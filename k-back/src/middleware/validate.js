// Validation error handler — use after express-validator chains
const { validationResult } = require('express-validator');

module.exports = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: errors.array()[0].msg,
      details: errors.array().map(e => ({ field: e.path, msg: e.msg })),
    });
  }
  next();
};
