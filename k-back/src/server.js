require('dotenv').config();
const app = require('./app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`
╔════════════════════════════════════════╗
║                                        ║
║     🚀 VTALK BACKEND STARTED           ║
║                                        ║
║     Environment: ${process.env.NODE_ENV}           ║
║     Port: ${PORT}                         ║
║     API: http://57.128.239.33:${PORT}  ║
║                                        ║
║     Matrix: ${process.env.MATRIX_HOMESERVER_URL}   ║
║                                        ║
╚════════════════════════════════════════╝
  `);
});
