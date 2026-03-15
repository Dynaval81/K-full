const { body, param, query } = require('express-validator');

exports.createChat = [
  body('targetUserId')
    .optional()
    .isUUID().withMessage('targetUserId must be a valid UUID'),
  body('targetKnNumber')
    .optional()
    .matches(/^KN-\d{5}$/).withMessage('targetKnNumber must be in format KN-XXXXX'),
  body().custom((_, { req }) => {
    if (!req.body.targetUserId && !req.body.targetKnNumber) {
      throw new Error('Either targetUserId or targetKnNumber is required');
    }
    return true;
  }),
];

exports.createGroupChat = [
  body('name').trim().notEmpty().withMessage('Group name is required')
    .isLength({ max: 100 }).withMessage('Group name too long'),
  body('type')
    .isIn(['classGroup', 'schoolGroup']).withMessage('type must be classGroup or schoolGroup'),
  body('memberIds').optional().isArray().withMessage('memberIds must be an array'),
];

exports.sendMessage = [
  param('id').isUUID().withMessage('Invalid chat ID'),
  body('text')
    .trim().notEmpty().withMessage('Message text is required')
    .isLength({ max: 4000 }).withMessage('Message too long (max 4000 characters)'),
  body('type')
    .optional()
    .isIn(['text', 'system']).withMessage('Invalid message type'),
];

exports.getMessages = [
  param('id').isUUID().withMessage('Invalid chat ID'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('limit must be 1-100'),
];
