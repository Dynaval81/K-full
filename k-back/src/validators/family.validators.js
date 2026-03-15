const { body, param } = require('express-validator');

exports.requestLink = [
  body('childKnNumber')
    .trim().notEmpty().withMessage('childKnNumber is required')
    .matches(/^KN-\d{5}$/i).withMessage('childKnNumber must be in format KN-XXXXX'),
];

exports.linkId = [
  param('id').isUUID().withMessage('Invalid link ID'),
];
