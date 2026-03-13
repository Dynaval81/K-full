const nodemailer = require('nodemailer');

// Создаем transporter (пока используем console.log для разработки)
let transporter = null;

// Инициализация SMTP (если настроен)
if (process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASSWORD) {
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: false, // true для 465, false для других портов
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASSWORD
    }
  });
  console.log('✅ Email service configured');
} else {
  console.log('⚠️ Email service not configured (SMTP credentials missing)');
}

// Отправка email верификации
exports.sendVerificationEmail = async (email, token) => {
  const verificationUrl = `${process.env.API_BASE_URL}/api/v1/auth/verify-email?token=${token}`;

  const mailOptions = {
    from: process.env.EMAIL_FROM || 'noreply@vtalk.io',
    to: email,
    subject: 'Verify your Vtalk account',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Welcome to Vtalk! 🚀</h2>
        <p>Please verify your email address by clicking the button below:</p>
        <a href="${verificationUrl}" 
           style="display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 4px; margin: 20px 0;">
          Verify Email
        </a>
        <p>Or copy and paste this link in your browser:</p>
        <p style="color: #666; word-break: break-all;">${verificationUrl}</p>
        <p style="color: #999; font-size: 12px; margin-top: 40px;">
          If you didn't create a Vtalk account, you can safely ignore this email.
        </p>
      </div>
    `
  };

  // Если transporter настроен - отправляем реальное письмо
  if (transporter) {
    try {
      const info = await transporter.sendMail(mailOptions);
      console.log('✅ Verification email sent:', info.messageId);
      return { success: true };
    } catch (error) {
      console.error('❌ Failed to send email:', error);
      // Не падаем если email не отправился (для разработки)
      console.log('📧 Verification URL (for testing):', verificationUrl);
      return { success: false, error: error.message };
    }
  } else {
    // Для разработки - просто логируем ссылку
    console.log('📧 Verification URL (SMTP not configured):', verificationUrl);
    return { success: true }; // Возвращаем success чтобы регистрация не падала
  }
};

// Отправка recovery email
exports.sendRecoveryEmail = async (email, username, vtNumber) => {
  const mailOptions = {
    from: process.env.EMAIL_FROM || 'noreply@vtalk.io',
    to: email,
    subject: 'Vtalk Account Recovery',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2>Account Recovery 🔑</h2>
        <p>Your Vtalk account credentials:</p>
        
        <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <p><strong>Username:</strong> ${username}</p>
          <p><strong>VT-ID:</strong> ${vtNumber}</p>
          <p><strong>Email:</strong> ${email}</p>
        </div>
        
        <p>You can login using any of these credentials along with your password.</p>
        
        <p style="color: #666; font-size: 14px; margin-top: 30px;">
          If you forgot your password, please contact support.
        </p>
        
        <p style="color: #999; font-size: 12px; margin-top: 40px;">
          If you didn't request this, please ignore this email.
        </p>
      </div>
    `
  };

  // Если transporter настроен - отправляем реальное письмо
  if (transporter) {
    try {
      const info = await transporter.sendMail(mailOptions);
      console.log('✅ Recovery email sent:', info.messageId);
      return { success: true };
    } catch (error) {
      console.error('❌ Failed to send recovery email:', error);
      console.log('📧 Recovery info:', { username, vtNumber, email });
      return { success: false, error: error.message };
    }
  } else {
    // Для разработки - просто логируем
    console.log('📧 Recovery Email (SMTP not configured):');
    console.log('  To:', email);
    console.log('  Username:', username);
    console.log('  VT-ID:', vtNumber);
    return { success: true };
  }
};
