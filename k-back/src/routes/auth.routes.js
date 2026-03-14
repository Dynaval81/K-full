const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 10,
  message: { success: false, error: 'Too many login attempts. Try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5,
  message: { success: false, error: 'Too many registration attempts. Try again in 1 hour.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { success: false, error: 'Too many requests. Try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Public routes
router.post('/register',    registerLimiter, authController.register);
router.post('/login',       loginLimiter,    authController.login);
router.post('/verify-code', generalLimiter,  authController.verifyCode);
router.get('/verify-email', generalLimiter,  authController.verifyEmail);
router.post('/recovery',    generalLimiter,  authController.recovery);

// Protected routes
router.get('/me', authMiddleware, authController.getCurrentUser);

module.exports = router;
