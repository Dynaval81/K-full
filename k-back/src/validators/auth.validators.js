const { body } = require('express-validator');

exports.register = [
  body('email')
    .isEmail().withMessage('Valid email is required')
    .normalizeEmail(),
  body('password')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('firstName')
    .trim().notEmpty().withMessage('First name is required')
    .isLength({ max: 64 }).withMessage('First name too long'),
  body('lastName')
    .trim().notEmpty().withMessage('Last name is required')
    .isLength({ max: 64 }).withMessage('Last name too long'),
];

exports.login = [
  body('email').trim().notEmpty().withMessage('Email or KN-number is required'),
  body('password').notEmpty().withMessage('Password is required'),
];

exports.verifyCode = [
  body('code')
    .trim()
    .matches(/^KNOTY-[A-Z0-9]{4}-[A-Z0-9]{4}$/i)
    .withMessage('Invalid activation code format (expected KNOTY-XXXX-XXXX)'),
  body('firstName').trim().notEmpty().withMessage('First name is required'),
  body('lastName').trim().notEmpty().withMessage('Last name is required'),
];

exports.refresh = [
  body('refreshToken').trim().notEmpty().withMessage('refreshToken is required'),
];

exports.recovery = [
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
];
