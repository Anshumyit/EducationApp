const User = require('../models/user.model');
const Student = require('../models/student.model');
const ClassRoom = require('../models/classroom.model');
const SalarySlip = require('../models/salarySlip.model');
const NotificationService = require('../services/notification.service');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Get teacher's assigned class details and student count
 */
const getMyClassInfo = asyncHandler(async (req, res) => {
  const teacher = req.user;

  if (!teacher.assignedClass) {
    return res.status(200).json(
      new ApiResponse(
        200,
        { assignedClass: null, totalStudents: 0, message: 'No class assigned yet as class teacher' },
        'Class info retrieved'
      )
    );
  }

  const classroom = await ClassRoom.findById(teacher.assignedClass);
  const totalStudents = await Student.countDocuments({ classId: teacher.assignedClass });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        classroom,
        totalStudents,
        isClassTeacher: teacher.isClassTeacher,
      },
      'Class details retrieved'
    )
  );
});

/**
 * Get all students in teacher's class with parent info
 */
const getClassStudents = asyncHandler(async (req, res) => {
  const teacher = req.user;
  const classId = req.query.classId || teacher.assignedClass;

  if (!classId) {
    throw new ApiError(400, 'Class ID is required or you are not assigned as a class teacher');
  }

  const students = await Student.find({ classId })
    .populate('parentId', 'name email phone address avatar')
    .populate('classId', 'name section')
    .sort({ rollNumber: 1 });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        total: students.length,
        students,
      },
      'Students list retrieved'
    )
  );
});

/**
 * Get single student full profile
 */
const getStudentDetail = asyncHandler(async (req, res) => {
  const { studentId } = req.params;

  const student = await Student.findById(studentId)
    .populate('parentId', 'name email phone address avatar')
    .populate('classId', 'name section roomNumber');

  if (!student) {
    throw new ApiError(404, 'Student not found');
  }

  return res.status(200).json(
    new ApiResponse(200, student, 'Student details retrieved')
  );
});

/**
 * Teacher sends instant notification / announcement to Class Parents
 */
const sendClassNotice = asyncHandler(async (req, res) => {
  const { title, message } = req.body;
  const teacher = req.user;

  if (!teacher.assignedClass) {
    throw new ApiError(400, 'You must be assigned as a class teacher to send class notices');
  }

  if (!title || !message) {
    throw new ApiError(400, 'Title and message are required');
  }

  const notification = await NotificationService.sendNotification({
    title,
    message,
    type: 'BROADCAST',
    targetRole: 'PARENTS',
    classId: teacher.assignedClass,
    senderId: teacher._id,
  });

  return res.status(201).json(
    new ApiResponse(201, notification, 'Instant notification sent to all class parents!')
  );
});

/**
 * Get logged-in teacher's salary slips
 */
const getMySalarySlips = asyncHandler(async (req, res) => {
  const teacher = req.user;
  const slips = await SalarySlip.find({ teacherId: teacher._id }).sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, slips, 'Teacher salary slips retrieved')
  );
});

module.exports = {
  getMyClassInfo,
  getClassStudents,
  getStudentDetail,
  sendClassNotice,
  getMySalarySlips,
};
