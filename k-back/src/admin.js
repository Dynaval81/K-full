const AdminJS = require('adminjs').default;
const { ComponentLoader } = require('adminjs');
const { Database, Resource, getModelByName } = require('@adminjs/prisma');
const bcrypt = require('bcryptjs');
const path = require('path');
const prisma = require('./lib/prisma');

const componentLoader = new ComponentLoader();
const Components = {
  Dashboard: componentLoader.add('Dashboard', path.join(__dirname, 'admin-components/Dashboard')),
};

AdminJS.registerAdapter({ Database, Resource });

// ─── Custom action handlers ───────────────────────────────────────────────────

const approveUser = {
  actionType: 'record',
  icon: 'Checkmark',
  label: 'Approve',
  component: false,
  guard: 'Approve this user?',
  handler: async (request, response, context) => {
    const { record } = context;
    await prisma.user.update({
      where: { id: record.params.id },
      data: { isApproved: true, status: 'active' },
    });
    return {
      record: record.toJSON(context.currentAdmin),
      notice: { message: 'User approved.', type: 'success' },
    };
  },
};

const banUser = {
  actionType: 'record',
  icon: 'Ban',
  label: 'Ban',
  component: false,
  guard: 'Ban this user? Their email will be blacklisted.',
  handler: async (request, response, context) => {
    const { record } = context;
    const userId = record.params.id;
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      return { record: record.toJSON(context.currentAdmin), notice: { message: 'User not found.', type: 'error' } };
    }
    await prisma.$transaction([
      prisma.user.update({
        where: { id: userId },
        data: {
          status: 'banned',
          isBanned: true,
          banReason: 'Banned via admin panel',
          bannedAt: new Date(),
          bannedBy: context.currentAdmin?.email ?? 'admin',
        },
      }),
      prisma.bannedEmail.upsert({
        where: { email: user.email },
        create: { email: user.email, reason: 'Banned via admin panel', bannedBy: context.currentAdmin?.email ?? 'admin' },
        update: {},
      }),
    ]);
    return {
      record: record.toJSON(context.currentAdmin),
      notice: { message: `User banned and email ${user.email} blacklisted.`, type: 'success' },
    };
  },
};

const unbanUser = {
  actionType: 'record',
  icon: 'Restart',
  label: 'Unban',
  component: false,
  guard: 'Unban this user?',
  handler: async (request, response, context) => {
    const { record } = context;
    const userId = record.params.id;
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      return { record: record.toJSON(context.currentAdmin), notice: { message: 'User not found.', type: 'error' } };
    }
    await prisma.user.update({
      where: { id: userId },
      data: { status: 'active', isBanned: false, banReason: null, bannedAt: null, bannedBy: null },
    });
    await prisma.bannedEmail.deleteMany({ where: { email: user.email } });
    return {
      record: record.toJSON(context.currentAdmin),
      notice: { message: 'User unbanned.', type: 'success' },
    };
  },
};

const resetPassword = {
  actionType: 'record',
  icon: 'Password',
  label: 'Reset Password',
  component: false,
  guard: 'Reset this user\'s password? A temporary password will be shown once.',
  handler: async (request, response, context) => {
    const { record } = context;
    const tempPassword = Math.random().toString(36).slice(-10).toUpperCase();
    const hashed = await bcrypt.hash(tempPassword, 12);
    await prisma.user.update({
      where: { id: record.params.id },
      data: { password: hashed },
    });
    return {
      record: record.toJSON(context.currentAdmin),
      notice: {
        message: `Password reset. Temp password: ${tempPassword} — copy now, shown only once.`,
        type: 'info',
      },
    };
  },
};

// ─── Admin factory ────────────────────────────────────────────────────────────

async function buildAdminRouter() {
  // @adminjs/express is ESM-only — must use dynamic import
  const { buildAuthenticatedRouter } = await import('@adminjs/express');

  const admin = new AdminJS({
    rootPath: '/admin',
    componentLoader,
    dashboard: {
      component: Components.Dashboard,
    },
    branding: {
      companyName: 'Knoty Admin',
      logo: '/public/knoty_logo.png',
      favicon: '/public/knoty_logo.png',
      softwareBrothers: false,
      withMadeWithLove: false,
    },
    availableThemes: [
      {
        id: 'light',
        name: 'Knoty',
        bundlePath: path.join(__dirname, 'public/knoty-theme.bundle.js'),
        overrides: {
          colors: {
            primary100: '#E6B800',
            primary80:  '#C9A200',
            primary60:  '#DAAE00',
            primary40:  '#EDD860',
            primary20:  '#FFF8CC',
            accent:     '#E6B800',
            // Keep sidebar and bg white
            sidebar:    '#FFFFFF',
            bg:         '#F5F5F5',
            container:  '#FFFFFF',
            border:     '#E0E0E0',
            text:       '#1A1A1A',
            grey100:    '#1A1A1A',
            grey80:     '#3D3D3D',
            grey60:     '#6B6B6B',
            grey40:     '#AAAAAA',
            grey20:     '#F5F5F5',
          },
          shadows: {
            login:    '0 8px 32px rgba(0,0,0,0.08)',
            cardHover:'0 4px 12px rgba(0,0,0,0.08)',
            drawer:   '-2px 0 8px rgba(0,0,0,0.06)',
            card:     '0 1px 6px rgba(0,0,0,0.05)',
          },
        },
      },
    ],
    defaultTheme: 'light',
    assets: {
      styles: ['/public/admin-theme.css'],
    },
    resources: [
      // ── Users ───────────────────────────────────────────────────────────────
      {
        resource: { model: getModelByName('User'), client: prisma },
        options: {
          navigation: { name: 'Users', icon: 'User' },
          listProperties: ['knNumber', 'firstName', 'lastName', 'email', 'role', 'status', 'isApproved', 'schoolId', 'createdAt'],
          filterProperties: ['role', 'status', 'isApproved', 'schoolId', 'email'],
          showProperties: [
            'id', 'knNumber', 'email', 'firstName', 'lastName', 'role',
            'status', 'isApproved', 'verificationLevel', 'schoolId', 'classId',
            'banReason', 'bannedAt', 'bannedBy', 'lastLoginAt', 'lastLoginIp',
            'createdAt', 'updatedAt',
          ],
          editProperties: ['email', 'firstName', 'lastName', 'role', 'schoolId', 'classId', 'isApproved', 'verificationLevel'],
          properties: {
            password:               { isVisible: false },
            emailVerificationToken: { isVisible: false },
            matrixAccessToken:      { isVisible: false },
          },
          actions: {
            approveUser,
            banUser,
            unbanUser,
            resetPassword,
          },
        },
      },

      // ── Schools ─────────────────────────────────────────────────────────────
      {
        resource: { model: getModelByName('School'), client: prisma },
        options: {
          navigation: { name: 'Schools', icon: 'Building' },
          listProperties: ['name', 'city', 'address', 'createdAt'],
        },
      },

      // ── Classes ─────────────────────────────────────────────────────────────
      {
        resource: { model: getModelByName('SchoolClass'), client: prisma },
        options: {
          navigation: { name: 'Schools', icon: 'List' },
          listProperties: ['name', 'schoolId', 'teacherId', 'createdAt'],
        },
      },

      // ── Activation codes ────────────────────────────────────────────────────
      {
        resource: { model: getModelByName('ActivationCode'), client: prisma },
        options: {
          navigation: { name: 'Codes', icon: 'Key' },
          listProperties: ['code', 'firstName', 'lastName', 'role', 'status', 'schoolId', 'classId', 'expiresAt'],
          filterProperties: ['status', 'role', 'schoolId', 'classId'],
          actions: {
            new:  { isAccessible: false },
            edit: { isAccessible: false },
          },
        },
      },

      // ── Banned emails ────────────────────────────────────────────────────────
      {
        resource: { model: getModelByName('BannedEmail'), client: prisma },
        options: {
          navigation: { name: 'Users', icon: 'Subtract' },
          listProperties: ['email', 'reason', 'bannedBy', 'bannedAt'],
          actions: {
            new:  { isAccessible: false },
            edit: { isAccessible: false },
          },
        },
      },

      // ── Login history ────────────────────────────────────────────────────────
      {
        resource: { model: getModelByName('LoginHistory'), client: prisma },
        options: {
          navigation: { name: 'Logs', icon: 'Calendar' },
          listProperties: ['userId', 'ip', 'platform', 'success', 'timestamp'],
          filterProperties: ['userId', 'success', 'timestamp'],
          actions: {
            new:    { isAccessible: false },
            edit:   { isAccessible: false },
            delete: { isAccessible: false },
          },
        },
      },

      // ── Parent-Child links ───────────────────────────────────────────────────
      {
        resource: { model: getModelByName('ParentChild'), client: prisma },
        options: {
          navigation: { name: 'Users', icon: 'Link' },
          listProperties: ['parentId', 'childId', 'status', 'createdAt'],
          filterProperties: ['status', 'parentId', 'childId'],
          actions: {
            new:  { isAccessible: false },
            edit: { isAccessible: false },
          },
        },
      },

      // ── Global settings ──────────────────────────────────────────────────────
      {
        resource: { model: getModelByName('GlobalSettings'), client: prisma },
        options: {
          navigation: { name: 'Settings', icon: 'Settings' },
          listProperties: ['key', 'value', 'updatedAt'],
          actions: {
            new:    { isAccessible: false },
            delete: { isAccessible: false },
          },
        },
      },
    ],
  });

  const router = buildAuthenticatedRouter(
    admin,
    {
      authenticate: async (email, password) => {
        const adminEmail    = process.env.ADMIN_EMAIL;
        const adminPassword = process.env.ADMIN_PASSWORD;
        if (!adminEmail || !adminPassword) return null;
        if (email === adminEmail && password === adminPassword) {
          return { email, role: 'appAdmin' };
        }
        return null;
      },
      cookieName: 'knoty_admin',
      cookiePassword: process.env.ADMIN_COOKIE_SECRET,
    },
    null,
    {
      resave: false,
      saveUninitialized: false,
      secret: process.env.ADMIN_COOKIE_SECRET,
      cookie: {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        maxAge: 8 * 60 * 60 * 1000, // 8 hours
      },
    },
  );

  return { admin, router };
}

module.exports = { buildAdminRouter };
