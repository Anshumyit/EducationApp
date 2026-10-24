const express = require('express');
const router = express.Router();
const {
  getMyClassInfo,
  getClassStudents,
  getStudentDetail,
  sendClassNotice,
  getMySalarySlips,
  getAllClassroomsForTeacher,
  createDailySyllabusLog,
  getDailySyllabusLogs,
  getSyllabusTrackerOverview,
  updateDailySyllabusLog,
  deleteDailySyllabusLog,
} = require('../controllers/teacher.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

router.use(verifyJWT, authorizeRoles(ROLES.TEACHER, ROLES.ADMIN));

router.get('/class-info', getMyClassInfo);
router.get('/classes', getAllClassroomsForTeacher);
router.get('/students', getClassStudents);
router.get('/students/:studentId', getStudentDetail);
router.post('/notice', sendClassNotice);
router.get('/salary-slips', getMySalarySlips);

// Daily Syllabus & Target Tracker Routes
router.get('/syllabus/overview', getSyllabusTrackerOverview);
router.get('/syllabus/daily-logs', getDailySyllabusLogs);
router.post('/syllabus/daily-logs', createDailySyllabusLog);
router.put('/syllabus/daily-logs/:id', updateDailySyllabusLog);
router.delete('/syllabus/daily-logs/:id', deleteDailySyllabusLog);

module.exports = router;

