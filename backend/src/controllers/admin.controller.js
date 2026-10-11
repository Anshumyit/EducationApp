const User = require('../models/user.model');
const Student = require('../models/student.model');
const ClassRoom = require('../models/classroom.model');
const SalarySlip = require('../models/salarySlip.model');
const NotificationService = require('../services/notification.service');
const { ROLES } = require('../constants/roles');
const { USER_STATUS } = require('../constants/status');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Admin Dashboard Statistics
 */
const getDashboardStats = asyncHandler(async (req, res) => {
  const [
    totalTeachers,
    totalStudents,
    totalParents,
    totalClasses,
    pendingTeachers,
    pendingParents,
  ] = await Promise.all([
    User.countDocuments({ role: ROLES.TEACHER, status: USER_STATUS.APPROVED }),
    Student.countDocuments(),
    User.countDocuments({ role: ROLES.PARENT, status: USER_STATUS.APPROVED }),
    ClassRoom.countDocuments(),
    User.countDocuments({ role: ROLES.TEACHER, status: USER_STATUS.PENDING }),
    User.countDocuments({ role: ROLES.PARENT, status: USER_STATUS.PENDING }),
  ]);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalTeachers,
        totalStudents,
        totalParents,
        totalClasses,
        pendingApprovals: {
          teachers: pendingTeachers,
          parents: pendingParents,
          total: pendingTeachers + pendingParents,
        },
      },
      'Dashboard stats retrieved'
    )
  );
});

/**
 * Get all teachers with subjects & assigned class details
 */
const getTeachersList = asyncHandler(async (req, res) => {
  const teachers = await User.find({ role: ROLES.TEACHER })
    .populate('assignedClass')
    .sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, teachers, 'Teachers list retrieved successfully')
  );
});

/**
 * Get list of users pending Admin approval
 */
const getPendingApprovals = asyncHandler(async (req, res) => {
  const { role } = req.query; // filter by TEACHER or PARENT or all
  const filter = { status: USER_STATUS.PENDING };
  if (role) filter.role = role;

  const pendingUsers = await User.find(filter).sort({ createdAt: -1 });
  return res.status(200).json(
    new ApiResponse(200, pendingUsers, 'Pending approval users retrieved')
  );
});

/**
 * Approve or Reject Teacher / Parent
 */
const updateApprovalStatus = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { status, remarks } = req.body; // 'APPROVED' or 'REJECTED'

  if (![USER_STATUS.APPROVED, USER_STATUS.REJECTED].includes(status)) {
    throw new ApiError(400, 'Invalid status. Must be APPROVED or REJECTED');
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  user.status = status;
  await user.save();

  // Send notification to the user
  await NotificationService.sendNotification({
    title: status === USER_STATUS.APPROVED ? 'Account Approved 🎉' : 'Registration Status Update',
    message: status === USER_STATUS.APPROVED
      ? `Congratulations ${user.name}! Your ${user.role.toLowerCase()} account has been approved by the School Admin. You can now log in and access all features.`
      : `Your account application was reviewed: ${remarks || 'Rejected by Admin'}.`,
    type: 'BROADCAST',
    targetRole: 'SPECIFIC',
    recipientId: user._id,
    senderId: req.user._id,
  });

  return res.status(200).json(
    new ApiResponse(200, user, `User account ${status.toLowerCase()} successfully`)
  );
});

/**
 * Create a new ClassRoom
 */
const createClassRoom = asyncHandler(async (req, res) => {
  const { name, section, roomNumber, capacity, classTeacherId } = req.body;

  if (!name || !section) {
    throw new ApiError(400, 'Class name and section are required');
  }

  const existing = await ClassRoom.findOne({ name, section });
  if (existing) {
    throw new ApiError(409, `Class ${name} ${section} already exists`);
  }

  const classroom = await ClassRoom.create({
    name,
    section,
    roomNumber: roomNumber || '',
    capacity: capacity || 40,
    classTeacher: classTeacherId || null,
  });

  if (classTeacherId) {
    await User.findByIdAndUpdate(classTeacherId, {
      isClassTeacher: true,
      assignedClass: classroom._id,
    });
  }

  return res.status(201).json(
    new ApiResponse(201, classroom, 'Classroom created successfully')
  );
});

/**
 * Get all classrooms
 */
const getAllClasses = asyncHandler(async (req, res) => {
  const classes = await ClassRoom.find().populate('classTeacher', 'name email phone subjects');
  return res.status(200).json(new ApiResponse(200, classes, 'Classes retrieved'));
});

/**
 * Assign Teacher as Class Teacher to ClassRoom
 */
const assignClassTeacher = asyncHandler(async (req, res) => {
  const { classId, teacherId } = req.body;

  const classroom = await ClassRoom.findById(classId);
  if (!classroom) throw new ApiError(404, 'Classroom not found');

  const teacher = await User.findOne({ _id: teacherId, role: ROLES.TEACHER });
  if (!teacher) throw new ApiError(404, 'Teacher not found');

  // If another teacher was assigned, update them
  if (classroom.classTeacher) {
    await User.findByIdAndUpdate(classroom.classTeacher, {
      isClassTeacher: false,
      assignedClass: null,
    });
  }

  classroom.classTeacher = teacher._id;
  await classroom.save();

  teacher.isClassTeacher = true;
  teacher.assignedClass = classroom._id;
  await teacher.save();

  return res.status(200).json(
    new ApiResponse(200, { classroom, teacher }, 'Class teacher assigned successfully')
  );
});

/**
 * Admin broadcast notification to ALL, TEACHERS, or PARENTS
 */
const broadcastNotice = asyncHandler(async (req, res) => {
  const { title, message, targetRole } = req.body;

  if (!title || !message) {
    throw new ApiError(400, 'Title and message are required');
  }

  const notification = await NotificationService.sendNotification({
    title,
    message,
    type: 'BROADCAST',
    targetRole: targetRole || 'ALL', // ALL | TEACHERS | PARENTS
    senderId: req.user._id,
  });

  return res.status(201).json(
    new ApiResponse(201, notification, 'Broadcast notice dispatched to recipients')
  );
});

/**
 * Create salary slip for a teacher
 */
const generateSalarySlip = asyncHandler(async (req, res) => {
  const {
    teacherId,
    month,
    year,
    basicSalary,
    hra = 0,
    da = 0,
    specialAllowance = 0,
    pfDeduction = 0,
    taxDeduction = 0,
  } = req.body;

  if (!teacherId || !month || !year || !basicSalary) {
    throw new ApiError(400, 'Teacher ID, month, year, and basic salary are required');
  }

  const teacher = await User.findOne({ _id: teacherId, role: ROLES.TEACHER });
  if (!teacher) throw new ApiError(404, 'Teacher not found');

  const grossSalary = Number(basicSalary) + Number(hra) + Number(da) + Number(specialAllowance);
  const totalDeductions = Number(pfDeduction) + Number(taxDeduction);
  const netSalary = grossSalary - totalDeductions;

  const slip = await SalarySlip.create({
    teacherId,
    month,
    year,
    basicSalary,
    hra,
    da,
    specialAllowance,
    pfDeduction,
    taxDeduction,
    netSalary,
    paymentStatus: 'PAID',
    paymentDate: new Date(),
  });

  // Notify teacher
  await NotificationService.sendNotification({
    title: `Salary Slip Generated 💵`,
    message: `Your salary slip for ${month} ${year} of ₹${netSalary.toLocaleString()} is now available to view and download.`,
    type: 'GENERAL',
    targetRole: 'SPECIFIC',
    recipientId: teacherId,
    senderId: req.user._id,
  });

  return res.status(201).json(
    new ApiResponse(201, slip, 'Salary slip generated successfully')
  );
});

/**
 * Get all salary slips
 */
const getAllSalarySlips = asyncHandler(async (req, res) => {
  const slips = await SalarySlip.find().populate('teacherId', 'name email phone subjects').sort({ createdAt: -1 });
  return res.status(200).json(new ApiResponse(200, slips, 'Salary slips retrieved'));
});

module.exports = {
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
};
