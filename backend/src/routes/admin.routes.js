const express = require('express');
const router = express.Router();
const {
  getDashboardStats,
  getTeachersList,
  getPendingApprovals,
  updateApprovalStatus,
  createClassRoom,
  getAllClasses,
  assignClassTeacher,
  broadcastNotice,
  generateSalarySlip,
  getAllSalarySlips,
} = require('../controllers/admin.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

// All admin routes require ADMIN role
router.use(verifyJWT, authorizeRoles(ROLES.ADMIN));

router.get('/stats', getDashboardStats);
router.get('/teachers', getTeachersList);
router.get('/approvals', getPendingApprovals);
router.patch('/approvals/:userId', updateApprovalStatus);
router.post('/classes', createClassRoom);
router.get('/classes', getAllClasses);
router.post('/classes/assign-teacher', assignClassTeacher);
router.post('/broadcast', broadcastNotice);
router.post('/salary-slips', generateSalarySlip);
router.get('/salary-slips', getAllSalarySlips);

module.exports = router;
