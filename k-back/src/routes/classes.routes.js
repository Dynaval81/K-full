const express = require('express');
const router = express.Router();
const classes = require('../controllers/classes.controller');
const auth = require('../middleware/auth.middleware');

router.use(auth);

router.get('/',             classes.listClasses);
router.post('/',            classes.createClass);
router.put('/:id',          classes.updateClass);
router.get('/:id/members',  classes.getClassMembers);

module.exports = router;
