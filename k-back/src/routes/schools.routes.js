const express = require('express');
const router = express.Router();
const { getPublicSchools } = require('../controllers/schools.controller');

router.get('/', getPublicSchools);

module.exports = router;
