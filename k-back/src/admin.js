const AdminJS = require('adminjs').default;
const { ComponentLoader } = require('adminjs');
const { Database, Resource, getModelByName } = require('@adminjs/prisma');
const bcrypt = require('bcryptjs');
const path = require('path');
const prisma = require('./lib/prisma');

const componentLoader = new ComponentLoader();
const Components = {
  Dashboard: componentLoader.add('Dashboard', path.join(__dirname, 'admin-components/Dashboard')),
  Login: componentLoader.override('Login', path.join(__dirname, 'admin-components/Login')),
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
      theme: {
        colors: {
          primary100: '#E6B800',
          primary80:  '#C9A200',
          primary60:  '#DAAE00',
          primary40:  '#EDD860',
          primary20:  '#FFF8CC',
          accent:     '#E6B800',
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
          login:     '0 8px 32px rgba(0,0,0,0.08)',
          cardHover: '0 4px 12px rgba(0,0,0,0.08)',
          drawer:    '-2px 0 8px rgba(0,0,0,0.06)',
          card:      '0 1px 6px rgba(0,0,0,0.05)',
        },
      },
    },
    availableThemes: [
      {
        id: 'knoty',
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
    defaultTheme: 'knoty',
    locale: {
      language: 'de',
      availableLanguages: ['de', 'en', 'ru'],
      translations: {
        de: {
          actions: {
            new: 'Neu erstellen',
            edit: 'Bearbeiten',
            show: 'Anzeigen',
            delete: 'Löschen',
            list: 'Liste',
            search: 'Suchen',
            save: 'Speichern',
            bulkDelete: 'Ausgewählte löschen',
          },
          buttons: {
            save: 'Speichern',
            addNewItem: 'Neuen Eintrag hinzufügen',
            delete: 'Löschen',
            cancel: 'Abbrechen',
            confirm: 'Bestätigen',
            filter: 'Filtern',
            applyChanges: 'Änderungen speichern',
            resetFilter: 'Filter zurücksetzen',
            logout: 'Abmelden',
            login: 'Anmelden',
            seeTheDocumentation: 'Dokumentation',
            createFirstRecord: 'Ersten Eintrag erstellen',
          },
          labels: {
            navigation: 'Navigation',
            pages: 'Seiten',
            selectedRecords: 'Ausgewählte Einträge ({{selected}})',
            filters: 'Filter',
            adminVersion: 'Admin: {{version}}',
            appVersion: 'App: {{version}}',
            loginWelcome: 'Willkommen bei Knoty Admin',
            dashboard: 'Dashboard',
            noResults: 'Keine Ergebnisse',
            // navigation group names (navigation.name in resource config)
            Users: 'Nutzer',
            Schools: 'Schulen',
            Codes: 'Codes',
            Logs: 'Protokoll',
            Settings: 'Einstellungen',
            // individual resource labels
            User: 'Nutzer',
            School: 'Schule',
            SchoolClass: 'Klasse',
            ActivationCode: 'Aktivierungscode',
            BannedEmail: 'Gesperrte E-Mail',
            LoginHistory: 'Login-Protokoll',
            ParentChild: 'Eltern-Kind',
            GlobalSettings: 'Einstellungen',
          },
          messages: {
            successfullyBulkDeleted: '{{count}} Einträge wurden erfolgreich gelöscht',
            successfullyDeleted: 'Eintrag wurde erfolgreich gelöscht',
            successfullyUpdated: 'Eintrag wurde erfolgreich aktualisiert',
            successfullyCreated: 'Eintrag wurde erfolgreich erstellt',
            thereWereValidationErrors: 'Es gibt Validierungsfehler — bitte überprüfen',
            forbiddenError: 'Sie haben keine Berechtigung für die Aktion: {{actionName}} auf {{resourceId}}',
            anyForbiddenError: 'Sie haben keine Berechtigung für diese Aktion',
            noRecordsSelected: 'Keine Einträge ausgewählt',
            confirmDelete: 'Möchten Sie diesen Eintrag wirklich löschen?',
            welcomeOnBoard: 'Willkommen bei Knoty Admin',
            filteringBy: 'Filter',
            notFound: 'Seite nicht gefunden',
            invalidCredentials: 'Ungültige E-Mail-Adresse oder Passwort',
            refreshError: 'Fehler beim Laden',
          },
          components: {
            Login: {
              welcomeHeader: 'Knoty Admin',
              welcomeMessage: 'Schulkommunikation für Lehrer, Eltern und Schüler. Sicher, strukturiert, DSGVO-konform.',
              loginButton: 'Anmelden',
              loginLabel: 'E-Mail-Adresse',
              passwordLabel: 'Passwort',
            },
            LanguageSelector: {
              availableLanguages: {
                de: 'Deutsch',
                en: 'English',
                ru: 'Русский',
              },
            },
          },
          resources: {
            User: { name: 'Nutzer', properties: { knNumber: 'KN-Nummer', firstName: 'Vorname', lastName: 'Nachname', email: 'E-Mail', role: 'Rolle', status: 'Status', isApproved: 'Freigegeben', createdAt: 'Erstellt am', verificationLevel: 'Verifikationsstufe', classId: 'Klasse', banReason: 'Sperrgrund', bannedAt: 'Gesperrt am', bannedBy: 'Gesperrt von', lastLoginAt: 'Letzter Login', lastLoginIp: 'Letzte IP', updatedAt: 'Geändert am' } },
            School: { name: 'Schulen', properties: { name: 'Name', city: 'Stadt', address: 'Adresse', createdAt: 'Erstellt am' } },
            SchoolClass: { name: 'Klassen', properties: { name: 'Name', teacherId: 'Lehrer-ID', createdAt: 'Erstellt am' } },
            ActivationCode: { name: 'Aktivierungscodes', properties: { code: 'Code', firstName: 'Vorname', lastName: 'Nachname', role: 'Rolle', status: 'Status', classId: 'Klasse', expiresAt: 'Gültig bis' } },
            BannedEmail: { name: 'Gesperrte E-Mails', properties: { email: 'E-Mail', reason: 'Grund', bannedBy: 'Gesperrt von', bannedAt: 'Gesperrt am' } },
            LoginHistory: { name: 'Login-Protokoll', properties: { ip: 'IP-Adresse', platform: 'Plattform', success: 'Erfolgreich', timestamp: 'Zeitpunkt' } },
            ParentChild: { name: 'Eltern-Kind Verknüpfungen', properties: { parentId: 'Elternteil-ID', childId: 'Kind-ID', status: 'Status', createdAt: 'Erstellt am' } },
            GlobalSettings: { name: 'Einstellungen', properties: { key: 'Schlüssel', value: 'Wert', updatedAt: 'Geändert am' } },
          },
        },
        en: {
          actions: {
            new: 'Create new',
            edit: 'Edit',
            show: 'Show',
            delete: 'Delete',
            list: 'List',
            search: 'Search',
            save: 'Save',
            bulkDelete: 'Delete selected',
          },
          buttons: {
            save: 'Save',
            addNewItem: 'Add new item',
            delete: 'Delete',
            cancel: 'Cancel',
            confirm: 'Confirm',
            filter: 'Filter',
            applyChanges: 'Apply changes',
            resetFilter: 'Reset filter',
            logout: 'Log out',
            login: 'Log in',
            seeTheDocumentation: 'Documentation',
            createFirstRecord: 'Create first record',
          },
          labels: {
            navigation: 'Navigation',
            pages: 'Pages',
            selectedRecords: 'Selected records ({{selected}})',
            filters: 'Filters',
            adminVersion: 'Admin: {{version}}',
            appVersion: 'App: {{version}}',
            loginWelcome: 'Welcome to Knoty Admin',
            dashboard: 'Dashboard',
            noResults: 'No results',
            // navigation group names
            Users: 'Users',
            Schools: 'Schools',
            Codes: 'Codes',
            Logs: 'Logs',
            Settings: 'Settings',
            // individual resource labels
            User: 'User',
            School: 'School',
            SchoolClass: 'Class',
            ActivationCode: 'Activation Code',
            BannedEmail: 'Banned Email',
            LoginHistory: 'Login History',
            ParentChild: 'Parent-Child',
            GlobalSettings: 'Settings',
          },
          messages: {
            successfullyBulkDeleted: '{{count}} records deleted successfully',
            successfullyDeleted: 'Record deleted successfully',
            successfullyUpdated: 'Record updated successfully',
            successfullyCreated: 'Record created successfully',
            thereWereValidationErrors: 'There were validation errors — please check',
            forbiddenError: 'You are not allowed to perform action: {{actionName}} on {{resourceId}}',
            anyForbiddenError: 'You are not allowed to perform this action',
            noRecordsSelected: 'No records selected',
            confirmDelete: 'Are you sure you want to delete this record?',
            welcomeOnBoard: 'Welcome to Knoty Admin',
            filteringBy: 'Filtering by',
            notFound: 'Page not found',
            invalidCredentials: 'Invalid email or password',
            refreshError: 'Loading error',
          },
          components: {
            Login: {
              welcomeHeader: 'Knoty Admin',
              welcomeMessage: 'School communication platform for teachers, parents and students. Secure, structured, GDPR-compliant.',
              loginButton: 'Log in',
              loginLabel: 'Email address',
              passwordLabel: 'Password',
            },
            LanguageSelector: {
              availableLanguages: {
                de: 'Deutsch',
                en: 'English',
                ru: 'Русский',
              },
            },
          },
          resources: {
            User: { name: 'Users', properties: { knNumber: 'KN Number', firstName: 'First name', lastName: 'Last name', email: 'Email', role: 'Role', status: 'Status', isApproved: 'Approved', createdAt: 'Created at', verificationLevel: 'Verification level', classId: 'Class', banReason: 'Ban reason', bannedAt: 'Banned at', bannedBy: 'Banned by', lastLoginAt: 'Last login', lastLoginIp: 'Last IP', updatedAt: 'Updated at' } },
            School: { name: 'Schools', properties: { name: 'Name', city: 'City', address: 'Address', createdAt: 'Created at' } },
            SchoolClass: { name: 'Classes', properties: { name: 'Name', teacherId: 'Teacher ID', createdAt: 'Created at' } },
            ActivationCode: { name: 'Activation Codes', properties: { code: 'Code', firstName: 'First name', lastName: 'Last name', role: 'Role', status: 'Status', classId: 'Class', expiresAt: 'Expires at' } },
            BannedEmail: { name: 'Banned Emails', properties: { email: 'Email', reason: 'Reason', bannedBy: 'Banned by', bannedAt: 'Banned at' } },
            LoginHistory: { name: 'Login History', properties: { ip: 'IP address', platform: 'Platform', success: 'Success', timestamp: 'Timestamp' } },
            ParentChild: { name: 'Parent-Child Links', properties: { parentId: 'Parent ID', childId: 'Child ID', status: 'Status', createdAt: 'Created at' } },
            GlobalSettings: { name: 'Settings', properties: { key: 'Key', value: 'Value', updatedAt: 'Updated at' } },
          },
        },
        ru: {
          actions: {
            new: 'Создать',
            edit: 'Редактировать',
            show: 'Просмотр',
            delete: 'Удалить',
            list: 'Список',
            search: 'Поиск',
            save: 'Сохранить',
            bulkDelete: 'Удалить выбранные',
          },
          buttons: {
            save: 'Сохранить',
            addNewItem: 'Добавить запись',
            delete: 'Удалить',
            cancel: 'Отмена',
            confirm: 'Подтвердить',
            filter: 'Фильтр',
            applyChanges: 'Применить',
            resetFilter: 'Сбросить фильтр',
            logout: 'Выйти',
            login: 'Войти',
            seeTheDocumentation: 'Документация',
            createFirstRecord: 'Создать первую запись',
          },
          labels: {
            navigation: 'Навигация',
            pages: 'Страницы',
            selectedRecords: 'Выбрано записей ({{selected}})',
            filters: 'Фильтры',
            adminVersion: 'Admin: {{version}}',
            appVersion: 'App: {{version}}',
            loginWelcome: 'Добро пожаловать в Knoty Admin',
            dashboard: 'Панель управления',
            noResults: 'Ничего не найдено',
            // navigation group names
            Users: 'Пользователи',
            Schools: 'Школы',
            Codes: 'Коды',
            Logs: 'Логи',
            Settings: 'Настройки',
            // individual resource labels
            User: 'Пользователь',
            School: 'Школа',
            SchoolClass: 'Класс',
            ActivationCode: 'Код активации',
            BannedEmail: 'Заблок. Email',
            LoginHistory: 'История входов',
            ParentChild: 'Родитель-Ребёнок',
            GlobalSettings: 'Настройки',
          },
          messages: {
            successfullyBulkDeleted: '{{count}} записей удалено',
            successfullyDeleted: 'Запись удалена',
            successfullyUpdated: 'Запись обновлена',
            successfullyCreated: 'Запись создана',
            thereWereValidationErrors: 'Ошибки валидации — проверьте поля',
            forbiddenError: 'Нет доступа к действию: {{actionName}} для {{resourceId}}',
            anyForbiddenError: 'Нет доступа к этому действию',
            noRecordsSelected: 'Записи не выбраны',
            confirmDelete: 'Вы уверены, что хотите удалить эту запись?',
            welcomeOnBoard: 'Добро пожаловать в Knoty Admin',
            filteringBy: 'Фильтр',
            notFound: 'Страница не найдена',
            invalidCredentials: 'Неверный email или пароль',
            refreshError: 'Ошибка загрузки',
          },
          components: {
            Login: {
              welcomeHeader: 'Knoty Admin',
              welcomeMessage: 'Платформа школьного общения для учителей, родителей и учеников. Безопасно, структурированно, в соответствии с GDPR.',
              loginButton: 'Войти',
              loginLabel: 'Email',
              passwordLabel: 'Пароль',
            },
            LanguageSelector: {
              availableLanguages: {
                de: 'Deutsch',
                en: 'English',
                ru: 'Русский',
              },
            },
          },
          resources: {
            User: { name: 'Пользователи', properties: { knNumber: 'KN-номер', firstName: 'Имя', lastName: 'Фамилия', email: 'Email', role: 'Роль', status: 'Статус', isApproved: 'Подтверждён', createdAt: 'Создан', verificationLevel: 'Уровень верификации', classId: 'Класс', banReason: 'Причина блокировки', bannedAt: 'Заблокирован', bannedBy: 'Заблокировал', lastLoginAt: 'Последний вход', lastLoginIp: 'Последний IP', updatedAt: 'Обновлён' } },
            School: { name: 'Школы', properties: { name: 'Название', city: 'Город', address: 'Адрес', createdAt: 'Создана' } },
            SchoolClass: { name: 'Классы', properties: { name: 'Название', teacherId: 'ID учителя', createdAt: 'Создан' } },
            ActivationCode: { name: 'Коды активации', properties: { code: 'Код', firstName: 'Имя', lastName: 'Фамилия', role: 'Роль', status: 'Статус', classId: 'Класс', expiresAt: 'Истекает' } },
            BannedEmail: { name: 'Заблокированные Email', properties: { email: 'Email', reason: 'Причина', bannedBy: 'Заблокировал', bannedAt: 'Заблокирован' } },
            LoginHistory: { name: 'История входов', properties: { ip: 'IP-адрес', platform: 'Платформа', success: 'Успешно', timestamp: 'Время' } },
            ParentChild: { name: 'Связи родитель-ребёнок', properties: { parentId: 'ID родителя', childId: 'ID ребёнка', status: 'Статус', createdAt: 'Создана' } },
            GlobalSettings: { name: 'Настройки', properties: { key: 'Ключ', value: 'Значение', updatedAt: 'Обновлено' } },
          },
        },
      },
    },
    assets: {
      styles: ['/public/admin-theme.css'],
    },
    resources: [
      // ── Users ───────────────────────────────────────────────────────────────
      {
        resource: { model: getModelByName('User'), client: prisma },
        options: {
          navigation: { name: 'Users', icon: 'User' },
          listProperties: ['knNumber', 'firstName', 'lastName', 'email', 'role', 'status', 'isApproved', 'createdAt'],
          filterProperties: ['role', 'status', 'isApproved', 'email'],
          showProperties: [
            'id', 'knNumber', 'email', 'firstName', 'lastName', 'role',
            'status', 'isApproved', 'verificationLevel', 'classId',
            'banReason', 'bannedAt', 'bannedBy', 'lastLoginAt', 'lastLoginIp',
            'createdAt', 'updatedAt',
          ],
          editProperties: ['email', 'firstName', 'lastName', 'role', 'classId', 'isApproved', 'verificationLevel'],
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
          listProperties: ['name', 'teacherId', 'createdAt'],
        },
      },

      // ── Activation codes ────────────────────────────────────────────────────
      {
        resource: { model: getModelByName('ActivationCode'), client: prisma },
        options: {
          navigation: { name: 'Codes', icon: 'Key' },
          listProperties: ['code', 'firstName', 'lastName', 'role', 'status', 'classId', 'expiresAt'],
          filterProperties: ['status', 'role', 'classId'],
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
          listProperties: ['ip', 'platform', 'success', 'timestamp'],
          filterProperties: ['success', 'timestamp'],
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
          listProperties: ['status', 'createdAt'],
          filterProperties: ['status'],
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
