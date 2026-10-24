const express = require('express');
const router = express.Router();
const {
  createHomework,
  getClassHomework,
  getHomeworkSubmissions,
  gradeSubmission,
  submitHomework,
  deleteHomework,
} = require('../controllers/homework.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

router.use(verifyJWT);

// Creating & Managing homework
router.post('/', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), createHomework);
router.get('/class/:classId', getClassHomework);
router.delete('/:homeworkId', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), deleteHomework);

// Submissions & Grading
router.get('/:homeworkId/submissions', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), getHomeworkSubmissions);
router.post('/:homeworkId/grade/:studentId', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), gradeSubmission);
router.post('/:homeworkId/submit', submitHomework);

module.exports = router;
