const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');
const emailService = require('../services/email.service');

function generateToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '30d' });
}

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
    console.error('verifyCode error:', error);
    return res.status(500).json({ success: false, error: 'Verification failed' });
  }
};

// Регистрация
exports.register = async (req, res) => {
  try {
    const { email, password, firstName, lastName, role, activationCode, schoolId, classId } = req.body;

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

    const user = await prisma.user.create({
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
        schoolId: resolvedSchoolId,
        classId: resolvedClassId,
      },
    });

    if (codeToMark) {
      await prisma.activationCode.update({
        where: { code: codeToMark },
        data: { status: 'used', usedBy: user.id },
      });
    }

    const token = generateToken(user.id);

    return res.status(201).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          knNumber: user.knNumber,
          role: user.role,
          verificationLevel: user.verificationLevel,
          isApproved: user.isApproved,
        },
        token,
      },
    });
  } catch (error) {
    console.error('Register error:', error);
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

    // Поиск по email или KN-номеру
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email },
          { knNumber: email.toUpperCase() },
        ],
      },
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

    const token = generateToken(user.id);

    return res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          knNumber: user.knNumber,
          role: user.role,
          verificationLevel: user.verificationLevel,
          isApproved: user.isApproved,
          status: user.status,
          schoolId: user.schoolId,
          classId: user.classId,
        },
        token,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
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
  <title>E-Mail bestätigt – Knoty</title>
  <style>
    body { font-family: system-ui, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; background: #FFF8E1; }
    .card { background: white; border-radius: 20px; padding: 48px 32px; max-width: 400px; text-align: center; box-shadow: 0 8px 32px rgba(0,0,0,.12); }
    .icon { width: 72px; height: 72px; background: #E6B800; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 24px; font-size: 36px; }
    h1 { color: #1A1A1A; font-size: 24px; margin-bottom: 8px; }
    p { color: #6B6B6B; font-size: 15px; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">✓</div>
    <h1>E-Mail bestätigt!</h1>
    <p>Du kannst diese Seite schließen und zur Knoty-App zurückkehren.</p>
  </div>
</body>
</html>`);
  } catch (error) {
    console.error('Email verification error:', error);
    return res.status(400).send('<p>Ungültiger oder abgelaufener Link.</p>');
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
      await emailService.sendRecoveryEmail(email, user.firstName || user.username || email, user.knNumber || '');
    }

    return res.json({
      success: true,
      message: 'If this email is registered, recovery instructions have been sent.',
    });
  } catch (error) {
    console.error('Recovery error:', error);
    return res.status(500).json({ success: false, error: 'Recovery failed' });
  }
};

// Получить текущего пользователя
exports.getCurrentUser = async (req, res) => {
  try {
    const user = req.user;

    return res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          knNumber: user.knNumber,
          role: user.role,
          verificationLevel: user.verificationLevel,
          isApproved: user.isApproved,
          status: user.status,
          schoolId: user.schoolId,
          classId: user.classId,
          createdAt: user.createdAt,
        },
      },
    });
  } catch (error) {
    console.error('getCurrentUser error:', error);
    return res.status(500).json({ success: false, error: 'Failed to get user' });
  }
};
