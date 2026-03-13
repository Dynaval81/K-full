const express = require('express');
const router = express.Router();
const usersController = require('../controllers/users.controller');
const authMiddleware = require('../middleware/auth.middleware');

// All user routes require authentication
router.use(authMiddleware);

router.put('/me', usersController.updateUsername);
router.get('/search', usersController.searchUsers); // ← НОВЫЙ ENDPOINT

module.exports = router;
