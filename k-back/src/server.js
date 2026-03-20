require('dotenv').config();

const http = require('http');
const log = require('lib/logger');

// ── Startup environment validation ───────────────────────────────────────────
const REQUIRED_ENV = ['JWT_SECRET', 'ADMIN_EMAIL', 'ADMIN_PASSWORD', 'ADMIN_COOKIE_SECRET'];
const missing = REQUIRED_ENV.filter(k => !process.env[k]);
if (missing.length) {
  log.fatal(`[FATAL] Missing required environment variables: ${missing.join(', ')}`);
  process.exit(1);
}

async function start() {
  const { Server } = require('socket.io');
  const app = require('./app');
  const { setupSocket, getOnlineSet } = require('./socket/socket.handler');

  // ── AdminJS panel ─────────────────────────────────────────────────────────
  // @adminjs/express is ESM-only so setup is async
  const { buildAdminRouter } = require('./admin');
  const { admin, router: adminRouter } = await buildAdminRouter();

  // Serve AdminJS user components bundle (production mode doesn't serve it via router)
  const path = require('path');
  const fs = require('fs');
  const bundlePath = path.join(process.cwd(), '.adminjs', 'bundle.js');
  app.get('/admin/frontend/assets/components.bundle.js', (req, res) => {
    try {
      const content = fs.readFileSync(bundlePath, 'utf8');
      res.setHeader('Content-Type', 'text/javascript; charset=utf-8');
      res.send(content);
    } catch {
      res.setHeader('Content-Type', 'text/javascript; charset=utf-8');
      res.send('');
    }
  });

  app.use(admin.options.rootPath, adminRouter);

  // ── Fallback handlers (must come after AdminJS mount) ─────────────────────
  app.use((req, res) => {
    res.status(404).json({ success: false, error: 'Route not found' });
  });
  app.use((err, req, res, next) => {
    log.error('Error:', err);
    res.status(err.status || 500).json({ success: false, error: err.message || 'Internal server error' });
  });

  const PORT = process.env.PORT || 3000;
  const server = http.createServer(app);

  // ── Socket.io ─────────────────────────────────────────────────────────────
  const io = new Server(server, {
    cors: {
      origin: process.env.ALLOWED_ORIGINS
        ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
        : '*',
      credentials: true,
    },
  });

  // Expose io and the online-user set to request handlers
  app.set('io', io);
  app.set('socketHandler', { getOnlineSet });

  setupSocket(io);

  // ── Start ─────────────────────────────────────────────────────────────────
  server.listen(PORT, '0.0.0.0', () => {
    log.info(`
╔════════════════════════════════════════╗
║                                        ║
║     Knoty Backend started              ║
║                                        ║
║     Env:  ${(process.env.NODE_ENV || 'development').padEnd(29)}║
║     Port: ${String(PORT).padEnd(29)}║
║     WS:   Socket.io enabled           ║
║     Admin: /admin                     ║
║                                        ║
╚════════════════════════════════════════╝
  `);
  });
}

start().catch(err => {
  log.fatal(err, '[FATAL] Server failed to start');
  process.exit(1);
});
