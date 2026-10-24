const express = require('express');
const router = express.Router();
const {
  markAttendance,
  getAttendanceByDate,
  getClassAttendanceLogs,
  getStudentAttendanceReport,
  getClassMonthlyReport,
} = require('../controllers/attendance.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

router.use(verifyJWT);

// Marking attendance requires TEACHER or ADMIN
router.post('/mark', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), markAttendance);
router.get('/class', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), getAttendanceByDate);
router.get('/class/:classId/logs', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), getClassAttendanceLogs);
router.get('/class/:classId/monthly-report', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), getClassMonthlyReport);

// Student attendance report accessible by Teacher, Admin, or Parent
router.get('/student/:studentId/report', getStudentAttendanceReport);

module.exports = router;
