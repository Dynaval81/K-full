const express = require('express');
const router = express.Router();
const family = require('../controllers/family.controller');
const auth = require('../middleware/auth.middleware');
const validate = require('../middleware/validate');
const v = require('../validators/family.validators');

router.use(auth);

router.get('/children',          family.getChildren);
router.get('/parents',           family.getParents);
router.post('/link',             v.requestLink, validate, family.requestLink);
router.post('/link/:id/accept',  v.linkId, validate, family.acceptLink);
router.post('/link/:id/reject',  v.linkId, validate, family.rejectLink);
router.delete('/link/:id',       v.linkId, validate, family.deleteLink);

module.exports = router;
