const bcrypt = require('bcryptjs');
const log = require('../lib/logger');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const prisma = require('../lib/prisma');
const emailService = require('../services/email.service');

// Access token — short-lived, stateless
function generateAccessToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '15m' });
}

// Refresh token — random hex, stored as SHA-256 hash in Session table
function generateRefreshToken() {
  return crypto.randomBytes(48).toString('hex'); // 96-char hex
}

function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

async function createSession(userId, refreshToken, req) {
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
  return prisma.session.create({
    data: {
      userId,
      token: hashToken(refreshToken),
      ip: req.ip ?? '0.0.0.0',
      device: req.headers['x-device'] ?? null,
      platform: req.headers['x-platform'] ?? null,
      expiresAt,
      isActive: true,
    },
  });
}

// ── Username helpers ──────────────────────────────────────────────────────────

const RESERVED_WORDS = new Set([
  'admin', 'administrator', 'administrador', 'admins',
  'director', 'direktur', 'direktor',
  'teacher', 'lehrer', 'учитель',
  'school', 'schule', 'schulen',
  'knoty', 'knotyadmin', 'knotyteam', 'knotybot',
  'system', 'support', 'helpdesk', 'help',
  'root', 'superuser', 'superadmin',
  'moderator', 'mod', 'mods',
  'owner', 'staff', 'team',
  'bot', 'robot', 'autobot',
  'official', 'info', 'contact', 'security', 'news',
  'null', 'undefined', 'anonymous', 'guest',
]);

function validateUsername(username) {
  if (!username || typeof username !== 'string') return 'Username is required';
  const u = username.toLowerCase().trim();
  if (u.length < 3) return 'Username must be at least 3 characters';
  if (u.length > 30) return 'Username must be at most 30 characters';
  if (!/^[a-z0-9_]+$/.test(u)) return 'Username may only contain letters, digits and underscores';
  if (/^[0-9]+$/.test(u)) return 'Username cannot consist of digits only';
  if (u.startsWith('_') || u.endsWith('_')) return 'Username cannot start or end with underscore';
  if (/_{2,}/.test(u)) return 'Username cannot have consecutive underscores';
  if (RESERVED_WORDS.has(u)) return 'This username is reserved';
  return null; // valid
}

const USERNAME_ADJECTIVES = [
  'swift', 'bright', 'cool', 'brave', 'smart', 'wild', 'keen', 'calm',
  'bold', 'free', 'sharp', 'lucky', 'sunny', 'storm', 'iron', 'silver',
  'golden', 'silent', 'fierce', 'noble', 'quick', 'azure', 'cosmic',
  'lunar', 'solar', 'sonic', 'epic', 'ultra', 'mega', 'turbo',
];
const USERNAME_NOUNS = [
  'eagle', 'wolf', 'fox', 'star', 'moon', 'lion', 'bear', 'hawk',
  'deer', 'oak', 'arrow', 'blade', 'comet', 'drift', 'echo', 'flame',
  'grove', 'haven', 'indie', 'jade', 'kite', 'lark', 'mist', 'nova',
  'orbit', 'pixel', 'quest', 'raven', 'scout', 'tide', 'valor', 'wave',
];

async function generateAvailableUsername(seed) {
  // 1. Try from seed (email prefix or first+last name)
  if (seed) {
    const base = seed.toLowerCase().replace(/[^a-z0-9]/g, '_').replace(/_{2,}/g, '_').replace(/^_|_$/g, '');
    if (base.length >= 3 && !RESERVED_WORDS.has(base) && !/^[0-9]+$/.test(base)) {
      const taken = await prisma.user.findUnique({ where: { username: base } });
      if (!taken) return base;
      // Try with number suffix
      for (let i = 2; i <= 9; i++) {
        const candidate = `${base}${i}`;
        const t = await prisma.user.findUnique({ where: { username: candidate } });
        if (!t) return candidate;
      }
    }
  }
  // 2. Fantasy name
  for (let attempt = 0; attempt < 20; attempt++) {
    const adj = USERNAME_ADJECTIVES[Math.floor(Math.random() * USERNAME_ADJECTIVES.length)];
    const noun = USERNAME_NOUNS[Math.floor(Math.random() * USERNAME_NOUNS.length)];
    const candidate = `${adj}_${noun}`;
    const taken = await prisma.user.findUnique({ where: { username: candidate } });
    if (!taken) return candidate;
  }
  // 3. Fallback with random suffix
  const adj = USERNAME_ADJECTIVES[Math.floor(Math.random() * USERNAME_ADJECTIVES.length)];
  const noun = USERNAME_NOUNS[Math.floor(Math.random() * USERNAME_NOUNS.length)];
  return `${adj}_${noun}_${Math.floor(100 + Math.random() * 900)}`;
}

// ── /auth/check-username?username=xxx ─────────────────────────────────────────
exports.checkUsername = async (req, res) => {
  const { username } = req.query;
  const error = validateUsername(username);
  if (error) return res.json({ available: false, error });
  const taken = await prisma.user.findUnique({ where: { username: username.toLowerCase().trim() } });
  return res.json({ available: !taken });
};

// ── /auth/suggest-username?hint=xxx ──────────────────────────────────────────
exports.suggestUsername = async (req, res) => {
  const { hint } = req.query;
  const username = await generateAvailableUsername(hint || null);
  return res.json({ username });
};

// ── KN number ─────────────────────────────────────────────────────────────────
async function generateKnNumber() {
  for (let attempt = 0; attempt < 10; attempt++) {
    const num = String(Math.floor(10000 + Math.random() * 90000));
    const knNumber = `KN-${num}`;
    const existing = await prisma.user.findUnique({ where: { knNumber } });
    if (!existing) return knNumber;
  }
  throw new Error('Failed to generate unique KN number after 10 attempts');
}

// Проверка активационного кода (до регистрации)
exports.verifyCode = async (req, res) => {
  try {
    const { code, firstName, lastName } = req.body;
    if (!code || !firstName || !lastName) {
      return res.status(400).json({ success: false, error: 'code, firstName and lastName are required' });
    }

    const activation = await prisma.activationCode.findUnique({
      where: { code },
      include: { school: true },
    });

    if (!activation || activation.status !== 'unused') {
      return res.json({ valid: false });
    }

    if (new Date() > activation.expiresAt) {
      return res.json({ valid: false, reason: 'expired' });
    }

    const nameMatch =
      activation.firstName.toLowerCase() === firstName.trim().toLowerCase() &&
      activation.lastName.toLowerCase() === lastName.trim().toLowerCase();

    if (!nameMatch) {
      return res.json({ valid: false, reason: 'name_mismatch' });
    }

    return res.json({
      valid: true,
      schoolName: activation.school.name,
      className: activation.classId,
      role: activation.role,
    });
  } catch (error) {
    log.error(error, 'verifyCode error:');
    return res.status(500).json({ success: false, error: 'Verification failed' });
  }
};

// Регистрация
exports.register = async (req, res) => {
  try {
    const { email, password, firstName, lastName, role, activationCode, schoolId, classId, username } = req.body;

    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({
        success: false,
        error: 'email, password, firstName and lastName are required',
      });
    }

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(400).json({ success: false, error: 'Email already registered' });
    }

    let userRole = role || 'student';
    let verificationLevel = 'sandbox';
    let isApproved = false;
    let resolvedSchoolId = schoolId || null;
    let resolvedClassId = classId || null;
    let codeToMark = null;

    if (activationCode) {
      const activation = await prisma.activationCode.findUnique({
        where: { code: activationCode },
      });

      if (!activation) {
        return res.status(400).json({ success: false, error: 'Code nicht gefunden' });
      }
      if (activation.status !== 'unused') {
        return res.status(400).json({ success: false, error: 'Code bereits verwendet' });
      }
      if (new Date() > activation.expiresAt) {
        return res.status(400).json({ success: false, error: 'Code abgelaufen' });
      }
      const nameMatch =
        activation.firstName.toLowerCase() === firstName.trim().toLowerCase() &&
        activation.lastName.toLowerCase() === lastName.trim().toLowerCase();
      if (!nameMatch) {
        return res.status(400).json({ success: false, error: 'Name stimmt nicht überein' });
      }

      userRole = activation.role;
      verificationLevel = 'schoolVerified';
      isApproved = true;
      resolvedSchoolId = activation.schoolId;
      resolvedClassId = activation.classId;
      codeToMark = activationCode;
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const knNumber = await generateKnNumber();

    // Resolve username: validate if provided, otherwise auto-generate
    let resolvedUsername;
    if (username) {
      const usernameError = validateUsername(username);
      if (usernameError) {
        return res.status(400).json({ success: false, error: usernameError, field: 'username' });
      }
      const normalised = username.toLowerCase().trim();
      const taken = await prisma.user.findUnique({ where: { username: normalised } });
      if (taken) {
        return res.status(400).json({ success: false, error: 'Username already taken', field: 'username' });
      }
      resolvedUsername = normalised;
    } else {
      const emailPrefix = email.split('@')[0];
      resolvedUsername = await generateAvailableUsername(emailPrefix);
    }

    const [user] = await prisma.$transaction(async (tx) => {
      const created = await tx.user.create({
        data: {
          email,
          password: hashedPassword,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          role: userRole,
          verificationLevel,
          isApproved,
          status: 'active',
          knNumber,
          username: resolvedUsername,
          schoolId: resolvedSchoolId,
          classId: resolvedClassId,
        },
      });

      if (codeToMark) {
        await tx.activationCode.update({
          where: { code: codeToMark },
          data: { status: 'used', usedBy: created.id },
        });
      }

      return [created];
    });

    // Send verification email (non-blocking — registration succeeds even if email fails)
    const verificationToken = jwt.sign({ email }, process.env.JWT_SECRET, { expiresIn: '24h' });
    emailService.sendVerificationEmail(email, verificationToken).catch(err => {
      log.error(err, 'Failed to send verification email after registration');
    });

    const accessToken = generateAccessToken(user.id);
    const refreshToken = generateRefreshToken();
    await createSession(user.id, refreshToken, req);

    return res.status(201).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          knNumber: user.knNumber,
          username: user.username,
          role: user.role,
          verificationLevel: user.verificationLevel,
          isApproved: user.isApproved,
        },
        accessToken,
        refreshToken,
        expiresIn: 900, // seconds
      },
    });
  } catch (error) {
    log.error(error, 'Register error:');
    return res.status(500).json({ success: false, error: 'Registration failed: ' + error.message });
  }
};

// Логин
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, error: 'Email and password are required' });
    }

    // Поиск по email, KN-номеру или username
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email },
          { knNumber: email.toUpperCase() },
          { username: email.toLowerCase() },
        ],
      },
      include: { school: { select: { id: true, name: true } } },
    });

    if (!user) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    if (user.status === 'banned') {
      return res.status(403).json({
        success: false,
        error: 'Konto gesperrt',
        code: 'ACCOUNT_BANNED',
        banReason: user.banReason,
      });
    }

    if (user.status === 'deleted') {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    const accessToken = generateAccessToken(user.id);
    const refreshToken = generateRefreshToken();
    await createSession(user.id, refreshToken, req);

    return res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          knNumber: user.knNumber,
          username: user.username,
          role: user.role,
          verificationLevel: user.verificationLevel,
          isApproved: user.isApproved,
          status: user.status,
          schoolId: user.schoolId,
          schoolName: user.school?.name ?? null,
          classId: user.classId,
        },
        accessToken,
        refreshToken,
        expiresIn: 900, // seconds
      },
    });
  } catch (error) {
    log.error(error, 'Login error:');
    return res.status(500).json({ success: false, error: 'Login failed' });
  }
};

// Верификация email (legacy, оставляем для обратной совместимости)
exports.verifyEmail = async (req, res) => {
  try {
    const { token } = req.query;
    if (!token) {
      return res.status(400).json({ success: false, error: 'Token is required' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await prisma.user.findUnique({ where: { email: decoded.email } });

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { emailVerified: true, emailVerificationToken: null },
    });

    return res.send(`<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>E-Mail bestätigt – Knoty</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, -apple-system, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; background: #F5F0D8; padding: 20px; }
    .card { background: #fff; border-radius: 24px; max-width: 420px; width: 100%; text-align: center; box-shadow: 0 12px 48px rgba(0,0,0,.10); overflow: hidden; }
    .header { padding: 28px 32px 16px; text-align: center; border-bottom: 1px solid #F5F5F5; }
    .body { padding: 40px 32px; }
    .check { width: 72px; height: 72px; background: #e8f8ee; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; }
    .check svg { width: 36px; height: 36px; }
    h1 { color: #1A1A1A; font-size: 22px; font-weight: 700; margin-bottom: 10px; }
    p { color: #6B6B6B; font-size: 15px; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <img src="${process.env.API_BASE_URL}/public/knoty_logo.png" alt="Knoty" width="110" style="display: block; margin: 0 auto;" />
    </div>
    <div class="body">
      <div class="check">
        <svg viewBox="0 0 24 24" fill="none" stroke="#22c55e" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="20 6 9 17 4 12"/>
        </svg>
      </div>
      <h1>E-Mail bestätigt!</h1>
      <p>Du kannst diese Seite schließen und zur Knoty-App zurückkehren.</p>
    </div>
  </div>
</body>
</html>`);
  } catch (error) {
    log.error(error, 'Email verification error:');
    return res.status(400).send('<p>Ungültiger oder abgelaufener Link.</p>');
  }
};

// Повторная отправка письма верификации
exports.resendVerification = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, error: 'Email is required' });
    }
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      // Don't reveal whether user exists
      return res.json({ success: true });
    }
    if (user.emailVerified) {
      return res.json({ success: true, alreadyVerified: true });
    }
    const token = jwt.sign({ email }, process.env.JWT_SECRET, { expiresIn: '24h' });
    await emailService.sendVerificationEmail(email, token);
    return res.json({ success: true });
  } catch (error) {
    log.error(error, 'resendVerification error:');
    return res.status(500).json({ success: false, error: 'Failed to resend' });
  }
};

// Восстановление доступа
exports.recovery = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, error: 'Email is required' });
    }

    const user = await prisma.user.findUnique({ where: { email } });

    if (user) {
      await emailService.sendRecoveryEmail(email, user.firstName || email, user.knNumber || '');
    }

    return res.json({
      success: true,
      message: 'If this email is registered, recovery instructions have been sent.',
    });
  } catch (error) {
    log.error(error, 'Recovery error:');
    return res.status(500).json({ success: false, error: 'Recovery failed' });
  }
};

// Обновить access token по refresh token
exports.refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ success: false, error: 'refreshToken is required' });
    }

    const hashed = hashToken(refreshToken);
    const session = await prisma.session.findUnique({ where: { token: hashed } });

    if (!session || !session.isActive) {
      return res.status(401).json({ success: false, error: 'Invalid or expired refresh token', code: 'REFRESH_INVALID' });
    }
    if (session.expiresAt < new Date()) {
      await prisma.session.update({ where: { id: session.id }, data: { isActive: false } });
      return res.status(401).json({ success: false, error: 'Refresh token expired', code: 'REFRESH_EXPIRED' });
    }

    const user = await prisma.user.findUnique({ where: { id: session.userId } });
    if (!user || user.status !== 'active') {
      return res.status(401).json({ success: false, error: 'User not found or inactive' });
    }

    // Rotate refresh token (invalidate old, issue new)
    const newRefreshToken = generateRefreshToken();
    await prisma.$transaction([
      prisma.session.update({ where: { id: session.id }, data: { isActive: false } }),
      prisma.session.create({
        data: {
          userId: user.id,
          token: hashToken(newRefreshToken),
          ip: req.ip ?? '0.0.0.0',
          device: session.device,
          platform: session.platform,
          expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
          isActive: true,
        },
      }),
    ]);

    return res.json({
      success: true,
      data: {
        accessToken: generateAccessToken(user.id),
        refreshToken: newRefreshToken,
        expiresIn: 900,
      },
    });
  } catch (error) {
    log.error(error, 'refresh error:');
    return res.status(500).json({ success: false, error: 'Token refresh failed' });
  }
};

// Logout — revoke current session
exports.logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await prisma.session.updateMany({
        where: { token: hashToken(refreshToken), userId: req.user.id },
        data: { isActive: false },
      });
    }
    return res.json({ success: true });
  } catch (error) {
    log.error(error, 'logout error:');
    return res.status(500).json({ success: false, error: 'Logout failed' });
  }
};

// Logout all — revoke all sessions for the user
exports.logoutAll = async (req, res) => {
  try {
    await prisma.session.updateMany({
      where: { userId: req.user.id },
      data: { isActive: false },
    });
    return res.json({ success: true });
  } catch (error) {
    log.error(error, 'logoutAll error:');
    return res.status(500).json({ success: false, error: 'Logout failed' });
  }
};

// Получить текущего пользователя
exports.getCurrentUser = async (req, res) => {
  try {
    // Re-fetch to include school relation
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: { school: { select: { id: true, name: true, city: true } } },
    });

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    return res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          knNumber: user.knNumber,
          username: user.username,
          role: user.role,
          verificationLevel: user.verificationLevel,
          isApproved: user.isApproved,
          emailVerified: user.emailVerified ?? false,
          status: user.status,
          schoolId: user.schoolId,
          schoolName: user.school?.name ?? null,
          schoolCity: user.school?.city ?? null,
          classId: user.classId,
          createdAt: user.createdAt,
        },
      },
    });
  } catch (error) {
    log.error(error, 'getCurrentUser error:');
    return res.status(500).json({ success: false, error: 'Failed to get user' });
  }
};
