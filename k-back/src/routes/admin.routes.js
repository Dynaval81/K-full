const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');

// Простая аутентификация middleware
const adminAuth = (req, res, next) => {
  const auth = req.headers.authorization;

  if (!auth || auth !== 'Basic ' + Buffer.from('noreply.vtalk@gmail.com:Vtalk2026AdminSecure!').toString('base64')) {
    res.setHeader('WWW-Authenticate', 'Basic realm="Vtalk Admin"');
    return res.status(401).send('Authentication required');
  }

  next();
};

router.use(adminAuth);

// Dashboard
router.get('/', adminController.dashboard);

// Users
router.get('/users', adminController.listUsers);
router.get('/users/new', adminController.showCreateUser);
router.post('/users/create', adminController.createUser);
router.get('/users/:id/edit', adminController.showEditUser);
router.post('/users/:id/edit', adminController.editUser);
router.get('/users/:id', adminController.viewUser);
router.post('/users/:id/ban', adminController.banUser);
router.post('/users/:id/unban', adminController.unbanUser);
router.post('/users/:id/delete', adminController.deleteUser);
router.post('/users/:id/premium', adminController.grantPremium);
router.post('/users/:id/reset-password', adminController.resetPassword);
router.post('/users/:id/set-password', adminController.setPassword);
router.post('/users/:id/permission/:type', adminController.togglePermission);

// VPN Nodes
router.get('/vpn', adminController.listVpnNodes);
router.get('/vpn/new', adminController.showCreateVpn);
router.post('/vpn/create', adminController.createVpnNode);

// Activation Codes
router.get('/codes', adminController.listCodes);
router.get('/codes/new', adminController.showCreateCode);
router.post('/codes/create', adminController.createCode);
router.post('/codes/:id/delete', adminController.deleteCode);

// Ban List
router.get('/banlist', adminController.listBannedEmails);
router.post('/banlist/:id/unban', adminController.unbanEmail);

module.exports = router;
