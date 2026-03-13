const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chat.controller');
const authMiddleware = require('../middleware/auth.middleware');

// All chat routes require authentication
router.use(authMiddleware);

router.post('/create', chatController.createChat);
router.get('/list', chatController.listChats);

module.exports = router;
