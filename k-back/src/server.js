require('dotenv').config();

// ── Startup environment validation ───────────────────────────────────────────
const REQUIRED_ENV = ['JWT_SECRET'];
const missing = REQUIRED_ENV.filter(k => !process.env[k]);
if (missing.length) {
  console.error(`[FATAL] Missing required environment variables: ${missing.join(', ')}`);
  process.exit(1);
}

const app = require('./app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`
╔════════════════════════════════════════╗
║                                        ║
║     Knoty Backend started              ║
║                                        ║
║     Env:  ${(process.env.NODE_ENV || 'development').padEnd(29)}║
║     Port: ${String(PORT).padEnd(29)}║
║                                        ║
╚════════════════════════════════════════╝
  `);
});
