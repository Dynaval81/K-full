const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const chat = require('../controllers/chat.controller');
const auth = require('../middleware/auth.middleware');
const validate = require('../middleware/validate');
const v = require('../validators/chat.validators');

const messageLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60,             // 60 messages per minute per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, error: 'Too many messages, slow down.' },
});

router.use(auth);

router.get('/',              chat.listChats);
router.post('/',             v.createChat,      validate, chat.createChat);
router.post('/group',        v.createGroupChat, validate, chat.createGroupChat);
router.get('/:id/messages',  v.getMessages,     validate, chat.getMessages);
router.post('/:id/messages', messageLimiter, v.sendMessage, validate, chat.sendMessage);
router.post('/:id/read',     chat.markRead);

module.exports = router;
