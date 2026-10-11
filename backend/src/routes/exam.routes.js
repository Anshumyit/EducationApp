const express = require('express');
const router = express.Router();
const {
  recordExamMarks,
  getStudentResults,
  getClassExamResults,
  getAnnualReportCard,
} = require('../controllers/exam.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

router.use(verifyJWT);

// Entering marks requires TEACHER or ADMIN
router.post('/marks', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), recordExamMarks);
router.get('/class/:classId', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), getClassExamResults);

// Results query accessible to Teacher, Parent, Admin
router.get('/student/:studentId', getStudentResults);
router.get('/student/:studentId/annual-card', getAnnualReportCard);

module.exports = router;
