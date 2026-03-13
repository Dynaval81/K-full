const express = require('express');
const router = express.Router();
const vpnController = require('../controllers/vpn.controller');
const authMiddleware = require('../middleware/auth.middleware');

// Требуется авторизация
router.use(authMiddleware);

router.get('/servers', vpnController.getServers);
router.get('/config/:nodeId', vpnController.getConfig);

module.exports = router;
