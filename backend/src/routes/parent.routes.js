const express = require('express');
const router = express.Router();
const {
  getMyChildren,
  getChildDashboard,
  getHolidays,
} = require('../controllers/parent.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

router.use(verifyJWT);

router.get('/children', authorizeRoles(ROLES.PARENT), getMyChildren);
router.get('/child/:studentId/dashboard', authorizeRoles(ROLES.PARENT), getChildDashboard);
router.get('/holidays', getHolidays);

module.exports = router;
