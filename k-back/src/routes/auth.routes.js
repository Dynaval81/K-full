const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const auth = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');
const validate = require('../middleware/validate');
const v = require('../validators/auth.validators');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, error: 'Too many login attempts. Try again in 15 minutes.' },
  standardHeaders: true, legacyHeaders: false,
});

const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  message: { success: false, error: 'Too many registration attempts. Try again in 1 hour.' },
  standardHeaders: true, legacyHeaders: false,
});

const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { success: false, error: 'Too many requests. Try again later.' },
  standardHeaders: true, legacyHeaders: false,
});

// Public
router.post('/register',     registerLimiter, v.register,     validate, auth.register);
router.post('/login',        loginLimiter,    v.login,        validate, auth.login);
router.post('/verify-code',  generalLimiter,  v.verifyCode,   validate, auth.verifyCode);
router.get( '/verify-email', generalLimiter,  auth.verifyEmail);
router.post('/recovery',     generalLimiter,  v.recovery,     validate, auth.recovery);
router.post('/refresh',      generalLimiter,  v.refresh,      validate, auth.refresh);

// Protected
router.get( '/me',          authMiddleware, auth.getCurrentUser);
router.post('/logout',      authMiddleware, auth.logout);
router.post('/logout/all',  authMiddleware, auth.logoutAll);

module.exports = router;
