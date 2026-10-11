const express = require('express');
const router = express.Router();
const {
  createHomework,
  getClassHomework,
} = require('../controllers/homework.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

router.use(verifyJWT);

// Creating homework requires TEACHER or ADMIN
router.post('/', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), createHomework);
// Viewing class homework
router.get('/class/:classId', getClassHomework);

module.exports = router;
