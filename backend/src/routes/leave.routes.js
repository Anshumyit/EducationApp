const express = require('express');
const router = express.Router();
const {
  submitLeaveRequest,
  getClassLeaveRequests,
  reviewLeaveRequest,
  getParentLeaveRequests,
} = require('../controllers/leave.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

router.use(verifyJWT);

// Parent submits leave request
router.post('/request', authorizeRoles(ROLES.PARENT), submitLeaveRequest);
// Parent views their submitted requests
router.get('/my-requests', authorizeRoles(ROLES.PARENT), getParentLeaveRequests);

// Class teacher reviews and views leave requests
router.get('/class', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), getClassLeaveRequests);
router.patch('/review/:leaveId', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), reviewLeaveRequest);

module.exports = router;
