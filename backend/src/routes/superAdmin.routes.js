const express = require('express');
const router = express.Router();
const {
  getSuperAdminDashboard,
  getAllSchools,
  createSchool,
  getSchoolDetails,
  updateSchool,
  updateSchoolStatus,
  getAllAdmins,
  createSchoolAdmin,
  updateAdminStatus,
  updateAdminPermissions,
  getAdminAuditLogs,
  updateSchoolModules,
  updateSchoolLimits,
  getSchoolLimitsUsage,
  getSuperAdminStudents,
  getAdmissionStats,
  createSuperAdminStudent,
  getSuperAdminStaff,
  getDuplicateEmployeeRecords,
  createSuperAdminStaff,
  getSchoolClasses,
  assignClassFaculty,
  getAllBiometricDevices,
  createBiometricDevice,
  syncBiometricDevice,
  getFacultyAttendanceReports,
  recordManualAttendanceOverride,
  markFacultyAttendanceSuperAdmin,
  getAllBuses,
  createBus,
  simulateBusMovement,
  getBusExpiryAlerts,
  getSuperAdminExams,
  approvePublishExamResult,
  correctExamResult,
  recordSuperAdminExam,
  getFinancialsOverview,
  recordFeeCorrection,
  broadcastCentralNotification,
  getCentralNotificationHistory,
  retryFailedNotification,
  getPlatformSettings,
  updatePlatformSettings,
  getSecurityAuditLogs,
  triggerSystemBackup,
} = require('../controllers/superAdmin.controller');

const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

// Strictly enforce SUPER_ADMIN role across all Super Admin endpoints
router.use(verifyJWT, authorizeRoles(ROLES.SUPER_ADMIN));

// 1. Dashboard
router.get('/dashboard/stats', getSuperAdminDashboard);

// 2. School Management
router.get('/schools', getAllSchools);
router.post('/schools', createSchool);
router.get('/schools/:id', getSchoolDetails);
router.put('/schools/:id', updateSchool);
router.patch('/schools/:id/status', updateSchoolStatus);

// School Specific Classrooms & Faculty Allocation
router.get('/schools/:schoolId/classes', getSchoolClasses);
router.post('/schools/:schoolId/classes', assignClassFaculty);

// 3. School Admin Accounts
router.get('/admins', getAllAdmins);
router.post('/admins', createSchoolAdmin);
router.patch('/admins/:id/status', updateAdminStatus);
router.patch('/admins/:id/permissions', updateAdminPermissions);
router.get('/admins/:id/audit-logs', getAdminAuditLogs);

// 4. Feature Access & Limits
router.patch('/schools/:id/modules', updateSchoolModules);
router.patch('/schools/:id/limits', updateSchoolLimits);
router.get('/schools/:id/limits-usage', getSchoolLimitsUsage);

// 5. Students & Admissions
router.get('/students', getSuperAdminStudents);
router.post('/students', createSuperAdminStudent);
router.get('/students/admissions-stats', getAdmissionStats);

// 6. Teacher & Staff
router.get('/staff', getSuperAdminStaff);
router.post('/staff', createSuperAdminStaff);
router.get('/staff/duplicates', getDuplicateEmployeeRecords);

// 7. Faculty Attendance & Biometric
router.get('/biometric/devices', getAllBiometricDevices);
router.post('/biometric/devices', createBiometricDevice);
router.post('/biometric/devices/:id/sync', syncBiometricDevice);
router.get('/biometric/faculty-attendance', getFacultyAttendanceReports);
router.post('/biometric/override', recordManualAttendanceOverride);
router.post('/faculty-attendance/mark', markFacultyAttendanceSuperAdmin);

// 8. Bus Fleet & Live Tracking
router.get('/buses', getAllBuses);
router.post('/buses', createBus);
router.patch('/buses/:id/simulate-location', simulateBusMovement);
router.get('/buses/alerts', getBusExpiryAlerts);

// 9. Examination & Results
router.get('/exams', getSuperAdminExams);
router.post('/exams', recordSuperAdminExam);
router.patch('/exams/:id/publish', approvePublishExamResult);
router.post('/exams/:id/correct', correctExamResult);

// 10. Financial Oversight
router.get('/financials/overview', getFinancialsOverview);
router.post('/financials/fee-correction', recordFeeCorrection);

// 11. Central Notifications
router.post('/notifications/broadcast', broadcastCentralNotification);
router.get('/notifications/history', getCentralNotificationHistory);
router.post('/notifications/:id/retry', retryFailedNotification);

// 12. System Settings, Security & Audit
router.get('/settings', getPlatformSettings);
router.put('/settings', updatePlatformSettings);
router.get('/security/audit-logs', getSecurityAuditLogs);
router.post('/security/backup-now', triggerSystemBackup);

module.exports = router;
