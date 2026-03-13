const express = require('express');
const router = express.Router();
const premiumController = require('../controllers/premium.controller');
const authMiddleware = require('../middleware/auth.middleware');

// All premium routes require authentication
router.use(authMiddleware);

router.post('/activate', premiumController.activatePremium);
router.get('/status', premiumController.getPremiumStatus);

module.exports = router;
