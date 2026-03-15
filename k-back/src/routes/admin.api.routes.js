const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth.middleware');
const requireRole = require('../middleware/require-role.middleware');
const ctrl = require('../controllers/admin.api.controller');
const settings = require('../controllers/settings.controller');

// All admin API routes require JWT + appAdmin role
router.use(authMiddleware);
router.use(requireRole('appAdmin'));

// Stats
router.get('/stats', ctrl.getStats);

// Schools
router.get('/schools', ctrl.listSchools);
router.post('/schools', ctrl.createSchool);
router.put('/schools/:id', ctrl.updateSchool);

// Activation Codes
router.get('/codes', ctrl.listCodes);
router.post('/codes/generate', ctrl.generateCodes);
router.delete('/codes/:code', ctrl.deleteCode);

// Users
router.get('/users', ctrl.listUsers);
router.post('/users/:id/approve', ctrl.approveUser);
router.post('/users/:id/ban', ctrl.banUser);
router.post('/users/:id/unban', ctrl.unbanUser);

// Global settings
router.get('/settings',  settings.getSettings);
router.put('/settings',  settings.updateSettings);

module.exports = router;
