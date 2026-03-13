const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const matrixService = require('../services/matrix.service');
const emailService = require('../services/email.service');

const prisma = new PrismaClient();

// Генерация VT-номера (формат VT-XXXXX)
function generateVtNumber() {
  const number = Math.floor(10000 + Math.random() * 90000); // 10000-99999
  return `VT-${number}`;
}

// Генерация JWT токена
function generateToken(userId) {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: '30d' }
  );
}

// Регистрация
exports.register = async (req, res) => {
  try {
    const { email, password, username, region } = req.body;

    // Валидация
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email and password are required'
      });
    }

    // Проверка существования email
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: 'Email already registered'
      });
    }

    // Определяем username
    let finalUsername = username;
    if (!finalUsername || finalUsername.trim() === '') {
      finalUsername = email.split('@')[0];
    } else {
      finalUsername = finalUsername.trim();
    }

    // Хешируем пароль
    const hashedPassword = await bcrypt.hash(password, 10);

    // Генерируем VT-номер
    let vtNumber;
    let isUnique = false;
    while (!isUnique) {
      vtNumber = generateVtNumber();
      const existing = await prisma.user.findUnique({
        where: { vtNumber }
      });
      if (!existing) isUnique = true;
    }

    // Создаем пользователя в Matrix
    const matrixResult = await matrixService.createUser(email, password, finalUsername, vtNumber);

    if (!matrixResult.success) {
      return res.status(500).json({
        success: false,
        error: 'Failed to create Matrix user: ' + matrixResult.error
      });
    }

    // Генерируем токен верификации email
    const emailVerificationToken = jwt.sign(
      { email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Создаем пользователя в БД
    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        username: finalUsername,
        vtNumber,
        region: region || 'RU',
        matrixUserId: matrixResult.userId,
        matrixAccessToken: matrixResult.accessToken,
        emailVerificationToken
      }
    });

    // Отправляем email верификации
    await emailService.sendVerificationEmail(email, emailVerificationToken);

    // Генерируем JWT токен
    const token = generateToken(user.id);

    res.status(201).json({
      success: true,
      data: {
        user: {
          vtNumber: user.vtNumber,
          username: user.username,
          email: user.email,
          isPremium: user.isPremium,
          emailVerified: user.emailVerified
        },
        token
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      error: 'Registration failed: ' + error.message
    });
  }
};

// Логин (гибкий - по email, vtNumber или username)
exports.login = async (req, res) => {
  try {
    const { identifier, password } = req.body;

    // Валидация
    if (!identifier || !password) {
      return res.status(400).json({
        success: false,
        error: 'Identifier and password are required'
      });
    }

    // Нормализуем VT-номер для поиска
    const cleanIdentifier = identifier.toUpperCase().replace(/[^A-Z0-9]/g, ''); // Убираем всё кроме букв и цифр
    const numericPart = cleanIdentifier.replace(/^VT/, ''); // Убираем VT если есть

    // Ищем пользователя по email, vtNumber или username
    const user = await prisma.user.findFirst({
      where: {
         OR: [
           { email: identifier },
           { vtNumber: identifier }, // Точное совпадение
           { vtNumber: `VT-${numericPart}` }, // С префиксом и дефисом
           { username: identifier }
         ]
       }
     });
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    // Проверяем пароль
    const isValidPassword = await bcrypt.compare(password, user.password);

    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    // Проверяем верификацию email
    if (!user.emailVerified) {
      return res.status(403).json({
        success: false,
        error: 'Email not verified. Check your inbox.'
      });
    }

    // Определяем isFirstLogin
    const isFirstLogin = !user.lastLoginAt;

    // Обновляем lastLoginAt
    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() }
    });

    // Генерируем токен
    const token = generateToken(user.id);

    res.json({
      success: true,
      data: {
        user: {
          vtNumber: user.vtNumber,
          username: user.username,
          email: user.email,
          isPremium: user.isPremium,
          isFirstLogin
        },
        token
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Login failed'
    });
  }
};

// Верификация email
exports.verifyEmail = async (req, res) => {
  try {
    const { token } = req.query;

    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'Token is required'
      });
    }

    // Проверяем токен
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Находим пользователя
    const user = await prisma.user.findUnique({
      where: { email: decoded.email }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Обновляем статус верификации
    await prisma.user.update({
      where: { id: user.id },
      data: {
        emailVerified: true,
        emailVerificationToken: null
      }
    });

// Показываем красивую страницу успеха
res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Email Verified - Vtalk</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .container {
      background: white;
      border-radius: 16px;
      padding: 48px 32px;
      max-width: 480px;
      text-align: center;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
    }
    .success-icon {
      width: 80px;
      height: 80px;
      background: #10b981;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
      animation: scaleIn 0.5s ease-out;
    }
    .checkmark {
      width: 40px;
      height: 40px;
      border: 4px solid white;
      border-radius: 50%;
      position: relative;
    }
    .checkmark:after {
      content: '';
      position: absolute;
      width: 12px;
      height: 20px;
      border: solid white;
      border-width: 0 4px 4px 0;
      top: 6px;
      left: 10px;
      transform: rotate(45deg);
    }
    h1 {
      color: #1f2937;
      font-size: 28px;
      margin-bottom: 12px;
      font-weight: 700;
    }
    p {
      color: #6b7280;
      font-size: 16px;
      line-height: 1.6;
      margin-bottom: 32px;
    }
    .app-button {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      text-decoration: none;
      padding: 14px 32px;
      border-radius: 8px;
      font-weight: 600;
      font-size: 16px;
      display: inline-block;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .app-button:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
    }
    @keyframes scaleIn {
      from { transform: scale(0); }
      to { transform: scale(1); }
    }
    .footer {
      margin-top: 32px;
      color: #9ca3af;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="success-icon">
      <div class="checkmark"></div>
    </div>
    <h1>Email Verified! ✓</h1>
    <p>Your email has been successfully verified.<br>You can now close this page and return to the Vtalk app.</p>
    <a href="vtalk://verified" class="app-button">Open Vtalk App</a>
    <div class="footer">
      Vtalk - Secure Private Communication
    </div>
  </div>
</body>
</html>
`);
} catch (error) {
  console.error('Email verification error:', error);
  res.status(400).send(`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Verification Failed - Vtalk</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .container {
      background: white;
      border-radius: 16px;
      padding: 48px 32px;
      max-width: 480px;
      text-align: center;
      box-shadow: 0 20px 60px rgba(0,0,0,0.3);
    }
    .error-icon {
      width: 80px;
      height: 80px;
      background: #ef4444;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
      animation: scaleIn 0.5s ease-out;
    }
    .cross {
      width: 40px;
      height: 40px;
      position: relative;
    }
    .cross:before, .cross:after {
      content: '';
      position: absolute;
      width: 4px;
      height: 40px;
      background: white;
      left: 18px;
    }
    .cross:before { transform: rotate(45deg); }
    .cross:after { transform: rotate(-45deg); }
    h1 {
      color: #1f2937;
      font-size: 28px;
      margin-bottom: 12px;
      font-weight: 700;
    }
    p {
      color: #6b7280;
      font-size: 16px;
      line-height: 1.6;
      margin-bottom: 32px;
    }
    .app-button {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      text-decoration: none;
      padding: 14px 32px;
      border-radius: 8px;
      font-weight: 600;
      font-size: 16px;
      display: inline-block;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .app-button:hover {
      transform: translateY(-2px);
      box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
    }
    @keyframes scaleIn {
      from { transform: scale(0); }
      to { transform: scale(1); }
    }
    .footer {
      margin-top: 32px;
      color: #9ca3af;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="error-icon">
      <div class="cross"></div>
    </div>
    <h1>Verification Failed</h1>
    <p>This verification link is invalid or has expired.<br>Please request a new verification email.</p>
    <a href="vtalk://home" class="app-button">Return to App</a>
    <div class="footer">
      Vtalk - Secure Private Communication
    </div>
  </div>
</body>
</html>
  `);
}
};

// Восстановление доступа
exports.recovery = async (req, res) => {
  try {
    const { email } = req.body;

    // Валидация
    if (!email) {
      return res.status(400).json({
        success: false,
        error: 'Email is required'
      });
    }

    // Находим пользователя
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      // НЕ говорим что пользователь не найден (безопасность)
      return res.json({
        success: true,
        message: 'If this email is registered, recovery instructions have been sent.'
      });
    }

    // Отправляем recovery email
    await emailService.sendRecoveryEmail(
      email,
      user.username,
      user.vtNumber
    );

    res.json({
      success: true,
      message: 'Recovery instructions have been sent to your email.'
    });
  } catch (error) {
    console.error('Recovery error:', error);
    res.status(500).json({
      success: false,
      error: 'Recovery failed'
    });
  }
};

// Получить текущего пользователя
exports.getCurrentUser = async (req, res) => {
  try {
    const user = req.user;

    const now = new Date();

    const isPremium = user.isPremium && (!user.premiumExpiresAt || user.premiumExpiresAt > now);
    const hasVpnAccess = user.hasVpnAccess && (!user.vpnExpiresAt || user.vpnExpiresAt > now);
    const hasAiAccess = user.hasAiAccess && (!user.aiExpiresAt || user.aiExpiresAt > now);

    let features = [];
    if (isPremium) features = ['vpn', 'ai', 'unlimited_storage'];
    else {
      if (hasVpnAccess) features.push('vpn');
      if (hasAiAccess) features.push('ai');
    }

    let daysRemaining = null;
    const expiry = user.premiumExpiresAt || user.vpnExpiresAt || user.aiExpiresAt;
    if (expiry) {
      daysRemaining = Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));
    }

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          vtNumber: user.vtNumber,
          emailVerified: user.emailVerified,
          matrixUserId: user.matrixUserId,
          country: user.country,
          region: user.region,
          createdAt: user.createdAt,
          isFirstLogin: !user.lastLoginAt,

          isPremium,
          hasVpnAccess,
          hasAiAccess,
          premiumExpiresAt: user.premiumExpiresAt,
          vpnExpiresAt: user.vpnExpiresAt,
          aiExpiresAt: user.aiExpiresAt
        },
        premium: {
          isPremium,
          hasVpnAccess,
          hasAiAccess,
          features,
          plan: user.premiumPlan || 'free',
          daysRemaining,
          isLifetime: !expiry && features.length > 0
        }
      }
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({ success: false, error: 'Failed to get user' });
  }
};
