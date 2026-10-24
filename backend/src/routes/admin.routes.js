const express = require('express');
const router = express.Router();
const {
  getDashboardStats,
  getAllStudents,
  getStudentById,
  createStudent,
  updateStudent,
  deleteStudent,
  updateStudentStatus,
  promoteStudents,
  getTeachersList,
  createTeacher,
  updateTeacher,
  deleteTeacher,
  getPendingApprovals,
  updateApprovalStatus,
  createClassRoom,
  getAllClasses,
  updateClassRoom,
  deleteClassRoom,
  assignClassTeacher,
  getFeesOverview,
  getAllFeeRecords,
  generateFeeInvoices,
  recordFeePayment,
  getAdminAttendanceOverview,
  notifyAbsentParents,
  getAdminExamsOverview,
  publishExamResults,
  broadcastNotice,
  generateSalarySlip,
  getAllSalarySlips,
  getSchoolSettings,
  updateSchoolSettings,
} = require('../controllers/admin.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

// All admin routes require ADMIN role
router.use(verifyJWT, authorizeRoles(ROLES.ADMIN));

// 1. Dashboard
router.get('/stats', getDashboardStats);

// 2. Student Management
router.get('/students', getAllStudents);
router.get('/students/:id', getStudentById);
router.post('/students', createStudent);
router.put('/students/:id', updateStudent);
router.delete('/students/:id', deleteStudent);
router.patch('/students/:id/status', updateStudentStatus);
router.post('/students/promote', promoteStudents);

// 3. Teacher & Faculty Management
router.get('/teachers', getTeachersList);
router.post('/teachers', createTeacher);
router.put('/teachers/:id', updateTeacher);
router.delete('/teachers/:id', deleteTeacher);
router.get('/approvals', getPendingApprovals);
router.patch('/approvals/:userId', updateApprovalStatus);

// 4. Class, Section & Subject Management
router.get('/classes', getAllClasses);
router.post('/classes', createClassRoom);
router.put('/classes/:id', updateClassRoom);
router.delete('/classes/:id', deleteClassRoom);
router.post('/classes/assign-teacher', assignClassTeacher);

// 5. Fees & Payments
router.get('/fees/overview', getFeesOverview);
router.get('/fees/records', getAllFeeRecords);
router.post('/fees/generate', generateFeeInvoices);
router.post('/fees/records/:id/pay', recordFeePayment);

// 6. Attendance Management
router.get('/attendance/overview', getAdminAttendanceOverview);
router.post('/attendance/notify-absent', notifyAbsentParents);

// 7. Examination & Results
router.get('/exams/overview', getAdminExamsOverview);
router.post('/exams/publish', publishExamResults);

// 8. Notices & Broadcasts
router.post('/broadcast', broadcastNotice);

// 9. Payroll
router.post('/salary-slips', generateSalarySlip);
router.get('/salary-slips', getAllSalarySlips);

// 10. School Settings & Extras
router.get('/settings', getSchoolSettings);
router.put('/settings', updateSchoolSettings);

module.exports = router;
