const LeaveRequest = require('../models/leaveRequest.model');
const Student = require('../models/student.model');
const ClassRoom = require('../models/classroom.model');
const NotificationService = require('../services/notification.service');
const { LEAVE_STATUS } = require('../constants/status');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Parent submits a leave request for their child to the class teacher
 */
const submitLeaveRequest = asyncHandler(async (req, res) => {
  const { studentId, startDate, endDate, reason } = req.body;
  const parent = req.user;

  if (!studentId || !startDate || !endDate || !reason) {
    throw new ApiError(400, 'studentId, startDate, endDate, and reason are required');
  }

  const student = await Student.findOne({ _id: studentId, parentId: parent._id }).populate('classId');
  if (!student) {
    throw new ApiError(404, 'Student not found or not associated with your parent account');
  }

  const leave = await LeaveRequest.create({
    studentId,
    parentId: parent._id,
    classId: student.classId._id,
    startDate: new Date(startDate),
    endDate: new Date(endDate),
    reason,
    status: LEAVE_STATUS.PENDING,
  });

  // Notify the Class Teacher
  const classroom = await ClassRoom.findById(student.classId._id);
  if (classroom && classroom.classTeacher) {
    await NotificationService.sendNotification({
      title: `New Leave Request 📝`,
      message: `${parent.name} submitted a leave request for ${student.name} from ${new Date(startDate).toLocaleDateString()} to ${new Date(endDate).toLocaleDateString()}.`,
      type: 'LEAVE',
      targetRole: 'SPECIFIC',
      recipientId: classroom.classTeacher,
      senderId: parent._id,
      metaData: {
        leaveId: leave._id,
        studentId: student._id,
      },
    });
  }

  return res.status(201).json(
    new ApiResponse(201, leave, 'Leave request submitted successfully to class teacher')
  );
});

/**
 * Class teacher gets all leave requests for their class
 */
const getClassLeaveRequests = asyncHandler(async (req, res) => {
  const teacher = req.user;
  const classId = req.query.classId || teacher.assignedClass;

  if (!classId) {
    throw new ApiError(400, 'Class ID is required');
  }

  const { status } = req.query;
  const filter = { classId };
  if (status) filter.status = status;

  const leaves = await LeaveRequest.find(filter)
    .populate('studentId', 'name rollNumber photo')
    .populate('parentId', 'name email phone')
    .sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, leaves, 'Leave requests retrieved')
  );
});

/**
 * Class teacher approves or rejects leave request
 */
const reviewLeaveRequest = asyncHandler(async (req, res) => {
  const { leaveId } = req.params;
  const { status, reviewNotes } = req.body; // 'APPROVED' or 'REJECTED'
  const teacher = req.user;

  if (![LEAVE_STATUS.APPROVED, LEAVE_STATUS.REJECTED].includes(status)) {
    throw new ApiError(400, 'Invalid status. Must be APPROVED or REJECTED');
  }

  const leave = await LeaveRequest.findById(leaveId).populate('studentId').populate('parentId');
  if (!leave) throw new ApiError(404, 'Leave request not found');

  leave.status = status;
  leave.reviewedBy = teacher._id;
  leave.reviewNotes = reviewNotes || '';
  await leave.save();

  // Instantly notify the Parent
  const statusEmoji = status === LEAVE_STATUS.APPROVED ? '✅' : '❌';
  await NotificationService.sendNotification({
    title: `Leave Request ${status} ${statusEmoji}`,
    message: `Leave request for ${leave.studentId.name} has been ${status.toLowerCase()} by Class Teacher ${teacher.name}.${reviewNotes ? ` Note: ${reviewNotes}` : ''}`,
    type: 'LEAVE',
    targetRole: 'SPECIFIC',
    recipientId: leave.parentId._id,
    senderId: teacher._id,
    metaData: {
      leaveId: leave._id,
      status,
    },
  });

  return res.status(200).json(
    new ApiResponse(200, leave, `Leave request has been ${status.toLowerCase()}`)
  );
});

/**
 * Parent views their submitted leave requests
 */
const getParentLeaveRequests = asyncHandler(async (req, res) => {
  const parent = req.user;
  const leaves = await LeaveRequest.find({ parentId: parent._id })
    .populate('studentId', 'name rollNumber classId')
    .populate('reviewedBy', 'name')
    .sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, leaves, 'Parent leave requests retrieved')
  );
});

module.exports = {
  submitLeaveRequest,
  getClassLeaveRequests,
  reviewLeaveRequest,
  getParentLeaveRequests,
};
