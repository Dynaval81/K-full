const AdminJS = require('adminjs');
const AdminJSExpress = require('@adminjs/express');
const { Database, Resource } = require('@adminjs/prisma');
const { PrismaClient } = require('@prisma/client');
const session = require('express-session');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

// Регистрируем Prisma адаптер
AdminJS.registerAdapter({ Database, Resource });

// Конфигурация AdminJS
const adminOptions = {
  resources: [
    {
      resource: { model: prisma.user, client: prisma },
      options: {
        properties: {
          password: { isVisible: false }, // Скрываем пароль
          matrixAccessToken: { isVisible: { list: false, filter: false, show: true, edit: false } },
          emailVerificationToken: { isVisible: false }
        },
        actions: {
          // Кастомное действие: Ban User
          banUser: {
            actionType: 'record',
            component: false,
            handler: async (request, response, context) => {
              const { record } = context;
              await prisma.user.update({
                where: { id: record.params.id },
                data: {
                  isPremium: false,
                  emailVerified: false
                }
              });
              return {
                record: record.toJSON(context.currentAdmin),
                notice: {
                  message: 'User banned successfully!',
                  type: 'success',
                },
              };
            },
          },
          // Кастомное действие: Grant Premium
          grantPremium: {
            actionType: 'record',
            component: false,
            handler: async (request, response, context) => {
              const { record } = context;
              const expiresAt = new Date();
              expiresAt.setDate(expiresAt.getDate() + 30);

              await prisma.user.update({
                where: { id: record.params.id },
                data: {
                  isPremium: true,
                  premiumPlan: 'admin_granted',
                  premiumExpiresAt: expiresAt
                }
              });
              return {
                record: record.toJSON(context.currentAdmin),
                notice: {
                  message: 'Premium granted for 30 days!',
                  type: 'success',
                },
              };
            },
          },
          // Кастомное действие: Reset Password
          resetPassword: {
            actionType: 'record',
            component: false,
            handler: async (request, response, context) => {
              const { record } = context;
              
              // Генерируем временный пароль (8 символов)
              const tempPassword = Math.random().toString(36).slice(-8).toUpperCase();
              const hashedPassword = await bcrypt.hash(tempPassword, 10);
              
              await prisma.user.update({
                where: { id: record.params.id },
                data: { password: hashedPassword }
              });
              
              return {
                record: record.toJSON(context.currentAdmin),
                notice: {
                  message: `✅ Password reset! New password: ${tempPassword} (Copy and save this!)`,
                  type: 'success',
                },
              };
            },
          },
        },
      },
    },
    {
      resource: { model: prisma.vpnNode, client: prisma },
      options: {
        properties: {
          vlessUri: { isVisible: { list: false, filter: false, show: true, edit: true } },
          singboxConfig: { isVisible: { list: false, filter: false, show: true, edit: true } }
        }
      }
    },
    {
      resource: { model: prisma.activationPassword, client: prisma },
      options: {}
    },
    {
      resource: { model: prisma.loginHistory, client: prisma },
      options: {
        actions: {
          new: { isAccessible: false },
          edit: { isAccessible: false },
          delete: { isAccessible: false }
        }
      }
    },
    {
      resource: { model: prisma.session, client: prisma },
      options: {
        actions: {
          new: { isAccessible: false },
          edit: { isAccessible: false }
        }
      }
    },
    {
      resource: { model: prisma.vpnConnection, client: prisma },
      options: {
        actions: {
          new: { isAccessible: false },
          edit: { isAccessible: false },
          delete: { isAccessible: false }
        }
      }
    }
  ],
  rootPath: '/admin',
  branding: {
    companyName: 'Vtalk Admin Panel',
    logo: false,
    softwareBrothers: false
  }
};

const admin = new AdminJS(adminOptions);

// Настройка сессий и аутентификации
const adminRouter = AdminJSExpress.buildAuthenticatedRouter(
  admin,
  {
    authenticate: async (email, password) => {
      // Аутентификация админа
      if (email === 'noreply.vtalk@gmail.com' && password === 'Vtalk2026AdminSecure!') {
        return { email: 'noreply.vtalk@gmail.com', role: 'admin' };
      }
      return null;
    },
    cookieName: 'adminjs',
    cookiePassword: 'vtalk-admin-secret-key-change-in-production-2026',
  },
  null,
  {
    secret: 'vtalk-session-secret-key-change-in-production-2026',
    resave: false,
    saveUninitialized: true,
    cookie: {
      httpOnly: true,
      secure: false, // В продакшене поставить true
    }
  }
);

module.exports = { admin, adminRouter };
