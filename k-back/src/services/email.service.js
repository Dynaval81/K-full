const nodemailer = require('nodemailer');

let transporter = null;

if (process.env.GMAIL_CLIENT_ID && process.env.GMAIL_CLIENT_SECRET && process.env.GMAIL_REFRESH_TOKEN) {
  transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      type: 'OAuth2',
      user: process.env.GMAIL_USER,
      clientId: process.env.GMAIL_CLIENT_ID,
      clientSecret: process.env.GMAIL_CLIENT_SECRET,
      refreshToken: process.env.GMAIL_REFRESH_TOKEN,
    },
    family: 4, // force IPv4 — IPv6 is unreachable on this VPS
  });
  console.log('✅ Email service configured (Gmail OAuth2)');
} else {
  console.log('⚠️  Email service not configured (GMAIL_* credentials missing)');
}

const FROM = `Knoty <${process.env.GMAIL_USER || 'noreply.knoty@gmail.com'}>`;

exports.sendVerificationEmail = async (email, token) => {
  const verificationUrl = `${process.env.API_BASE_URL}/api/v1/auth/verify-email?token=${token}`;

  if (!transporter) {
    if (process.env.NODE_ENV !== 'production') {
      console.log('📧 Verification URL (dev, email not configured):', verificationUrl);
      return { success: true };
    }
    return { success: false, error: 'Email service not configured' };
  }

  try {
    const info = await transporter.sendMail({
      from: FROM,
      to: email,
      subject: 'Подтвердите ваш Knoty аккаунт',
      html: `
        <div style="font-family: system-ui, Arial, sans-serif; max-width: 560px; margin: 0 auto; background: #fff; border-radius: 16px; overflow: hidden; border: 1px solid #F0F0F0;">
          <div style="padding: 32px 40px 20px; text-align: center; border-bottom: 1px solid #F5F5F5;">
            <img src="${process.env.API_BASE_URL}/public/knoty_logo.png" alt="Knoty" width="120" style="display: block; margin: 0 auto;" />
          </div>
          <div style="padding: 40px;">
            <h2 style="margin: 0 0 12px; color: #1A1A1A; font-size: 22px;">Подтвердите email</h2>
            <p style="color: #555; line-height: 1.6; margin: 0 0 28px;">
              Для завершения регистрации нажмите кнопку ниже. Ссылка действительна 24 часа.
            </p>
            <a href="${verificationUrl}"
               style="display: inline-block; padding: 14px 32px; background: #E6B800; color: #1A1A1A; font-weight: 700; text-decoration: none; border-radius: 12px; font-size: 15px;">
              Подтвердить email
            </a>
            <p style="margin: 28px 0 0; color: #999; font-size: 12px; word-break: break-all;">
              Или скопируйте ссылку: ${verificationUrl}
            </p>
            <p style="margin: 20px 0 0; color: #bbb; font-size: 12px;">
              Если вы не регистрировались в Knoty — просто проигнорируйте это письмо.
            </p>
          </div>
        </div>
      `,
    });
    console.log('✅ Verification email sent:', info.messageId);
    return { success: true };
  } catch (error) {
    console.error('❌ Failed to send verification email:', error.message);
    console.log('📧 Verification URL (fallback):', verificationUrl);
    return { success: false, error: error.message };
  }
};

exports.sendRecoveryEmail = async (email, firstName, knNumber) => {
  if (!transporter) {
    console.log('📧 Recovery email (not configured):', { email, knNumber });
    return { success: true };
  }

  try {
    const info = await transporter.sendMail({
      from: FROM,
      to: email,
      subject: 'Восстановление доступа к Knoty',
      html: `
        <div style="font-family: system-ui, Arial, sans-serif; max-width: 560px; margin: 0 auto; background: #fff; border-radius: 16px; overflow: hidden; border: 1px solid #F0F0F0;">
          <div style="padding: 32px 40px 20px; text-align: center; border-bottom: 1px solid #F5F5F5;">
            <img src="${process.env.API_BASE_URL}/public/knoty_logo.png" alt="Knoty" width="120" style="display: block; margin: 0 auto;" />
          </div>
          <div style="padding: 40px;">
            <h2 style="margin: 0 0 12px; color: #1A1A1A; font-size: 22px;">Данные вашего аккаунта</h2>
            <p style="color: #555; line-height: 1.6; margin: 0 0 20px;">Здравствуйте, ${firstName}!</p>
            <div style="background: #F9F9F9; border-radius: 12px; padding: 20px; margin: 0 0 20px;">
              <p style="margin: 0 0 8px; color: #333;"><strong>Email:</strong> ${email}</p>
              <p style="margin: 0; color: #333;"><strong>Knoty-ID:</strong> ${knNumber}</p>
            </div>
            <p style="color: #999; font-size: 12px; margin: 0;">
              Если вы не запрашивали восстановление доступа — проигнорируйте это письмо.
            </p>
          </div>
        </div>
      `,
    });
    console.log('✅ Recovery email sent:', info.messageId);
    return { success: true };
  } catch (error) {
    console.error('❌ Failed to send recovery email:', error.message);
    return { success: false, error: error.message };
  }
};
