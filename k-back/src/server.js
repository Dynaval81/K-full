require('dotenv').config();

// ── Startup environment validation ───────────────────────────────────────────
const REQUIRED_ENV = ['JWT_SECRET'];
const missing = REQUIRED_ENV.filter(k => !process.env[k]);
if (missing.length) {
  log.fatal(`[FATAL] Missing required environment variables: ${missing.join(', ')}`);
  process.exit(1);
}

const http = require('http');
const log = require('lib/logger');
const { Server } = require('socket.io');
const app = require('./app');
const { setupSocket, getOnlineSet } = require('./socket/socket.handler');

const PORT = process.env.PORT || 3000;

const server = http.createServer(app);

// ── Socket.io ─────────────────────────────────────────────────────────────────
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

// ── Start ─────────────────────────────────────────────────────────────────────
server.listen(PORT, '0.0.0.0', () => {
  log.info(`
╔════════════════════════════════════════╗
║                                        ║
║     Knoty Backend started              ║
║                                        ║
║     Env:  ${(process.env.NODE_ENV || 'development').padEnd(29)}║
║     Port: ${String(PORT).padEnd(29)}║
║     WS:   Socket.io enabled           ║
║                                        ║
╚════════════════════════════════════════╝
  `);
});
