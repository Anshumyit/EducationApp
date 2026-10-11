const express = require('express');
const router = express.Router();
const {
  getMyClassInfo,
  getClassStudents,
  getStudentDetail,
  sendClassNotice,
  getMySalarySlips,
} = require('../controllers/teacher.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

router.use(verifyJWT, authorizeRoles(ROLES.TEACHER, ROLES.ADMIN));

router.get('/class-info', getMyClassInfo);
router.get('/students', getClassStudents);
router.get('/students/:studentId', getStudentDetail);
router.post('/notice', sendClassNotice);
router.get('/salary-slips', getMySalarySlips);

module.exports = router;
