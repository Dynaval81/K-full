const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/verify-code', authController.verifyCode);
router.get('/verify-email', authController.verifyEmail);
router.post('/recovery', authController.recovery);

// Protected routes
router.get('/me', authMiddleware, authController.getCurrentUser);

module.exports = router;
