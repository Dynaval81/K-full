const express = require('express');
const log = require('lib/logger');
const cors = require('cors');
const maintenanceMiddleware = require('./middleware/maintenance.middleware');

const app = express();

// Trust Nginx reverse proxy — needed for req.secure, req.ip, and secure session cookies
app.set('trust proxy', 1);

// CORS — configurable via ALLOWED_ORIGINS env var (comma-separated).
// In production NODE_ENV the variable must be set explicitly; '*' is never used.
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
  : null;

if (!allowedOrigins && process.env.NODE_ENV === 'production') {
  log.error('[FATAL] ALLOWED_ORIGINS must be set in production');
  process.exit(1);
}

app.use(cors({
  origin: allowedOrigins
    ? (origin, cb) => {
        // Allow requests with no origin (mobile apps, curl)
        if (!origin || allowedOrigins.includes(origin)) return cb(null, true);
        cb(new Error(`CORS: origin ${origin} not allowed`));
      }
    : '*', // development only — production blocked above
  credentials: true,
}));

// Apply body parsers only to API routes — AdminJS uses formidable internally
// and throws OldBodyParserUsedError if req._body is already set.
// NOTE: string prefix '/api' is used intentionally — Express regexp in app.use()
// does not trigger body parsing correctly in Express 4.
app.use('/api', express.json({ limit: '5mb' }));
app.use('/api', express.urlencoded({ extended: true, limit: '5mb' }));

// Static assets (admin panel branding, logos)
app.use('/public', express.static(require('path').join(__dirname, 'public')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Maintenance mode — checked before all API routes (admin bypasses it)
app.use(maintenanceMiddleware);

// API Routes
app.use('/api/v1/auth',    require('./routes/auth.routes'));
app.use('/api/v1/admin',   require('./routes/admin.api.routes'));
app.use('/api/v1/schools', require('./routes/schools.routes'));
app.use('/api/v1/classes', require('./routes/classes.routes'));
app.use('/api/v1/family',  require('./routes/family.routes'));
app.use('/api/v1/users',   require('./routes/users.routes'));
app.use('/api/v1/chats',   require('./routes/chat.routes'));

// 404 and error handlers are registered in server.js after AdminJS is mounted,
// so that /adminjs routes are matched before the 404 catch-all.

module.exports = app;
