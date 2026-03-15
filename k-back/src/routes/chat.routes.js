const express = require('express');
const router = express.Router();
const chat = require('../controllers/chat.controller');
const auth = require('../middleware/auth.middleware');
const validate = require('../middleware/validate');
const v = require('../validators/chat.validators');

router.use(auth);

router.get('/',              chat.listChats);
router.post('/',             v.createChat,      validate, chat.createChat);
router.post('/group',        v.createGroupChat, validate, chat.createGroupChat);
router.get('/:id/messages',  v.getMessages,     validate, chat.getMessages);
router.post('/:id/messages', v.sendMessage,     validate, chat.sendMessage);
router.post('/:id/read',     chat.markRead);

module.exports = router;
