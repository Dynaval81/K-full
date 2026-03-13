const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();

// Middleware
app.use(cors({
  origin: '*',  // Для разработки разрешаем все источники
  credentials: true
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// View engine setup
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Admin Panel
//const { admin, adminRouter } = require('./admin');
//app.use(admin.options.rootPath, adminRouter);

// Admin Panel API
app.use('/admin', require('./routes/admin.routes'));


// API Routes (добавим позже)
app.use('/api/v1/auth', require('./routes/auth.routes'));
app.use('/api/v1/schools', require('./routes/schools.routes'));
app.use('/api/v1/premium', require('./routes/premium.routes'));
app.use('/api/v1/users', require('./routes/users.routes'));
app.use('/api/v1/chats', require('./routes/chat.routes'));

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    success: false,
    error: err.message || 'Internal server error'
  });
});

module.exports = app;
