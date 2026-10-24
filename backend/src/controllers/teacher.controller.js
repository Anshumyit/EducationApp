const User = require('../models/user.model');
const Student = require('../models/student.model');
const ClassRoom = require('../models/classroom.model');
const SalarySlip = require('../models/salarySlip.model');
const DailySyllabusLog = require('../models/dailySyllabusLog.model');
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

/**
 * Get all classrooms available for teacher selection
 */
const getAllClassroomsForTeacher = asyncHandler(async (req, res) => {
  const classrooms = await ClassRoom.find().sort({ name: 1, section: 1 });
  return res.status(200).json(
    new ApiResponse(200, classrooms, 'Classrooms retrieved successfully')
  );
});

/**
 * Create a new daily syllabus and target log
 */
const createDailySyllabusLog = asyncHandler(async (req, res) => {
  const teacherId = req.user._id;
  const {
    classId,
    subject,
    date,
    chapter,
    topic,
    dailyTarget,
    status = 'COMPLETED',
    completionPercentage = 0,
    durationMinutes = 45,
    nextClassTarget = '',
    studyMaterials = [],
    notes = '',
    academicSession = '2026-2027',
  } = req.body;

  if (!classId || !subject || !date || !chapter || !topic || !dailyTarget) {
    throw new ApiError(400, 'Class, subject, date, chapter, topic, and daily target are required');
  }

  const log = await DailySyllabusLog.create({
    teacherId,
    classId,
    subject,
    date,
    chapter,
    topic,
    dailyTarget,
    status,
    completionPercentage: Math.min(100, Math.max(0, Number(completionPercentage) || 0)),
    durationMinutes: Number(durationMinutes) || 45,
    nextClassTarget,
    studyMaterials,
    notes,
    academicSession,
  });

  const populatedLog = await DailySyllabusLog.findById(log._id)
    .populate('classId', 'name section roomNumber')
    .populate('teacherId', 'name email avatar');

  return res.status(201).json(
    new ApiResponse(201, populatedLog, 'Daily syllabus & target logged successfully!')
  );
});

/**
 * Get daily syllabus logs with optional filters
 */
const getDailySyllabusLogs = asyncHandler(async (req, res) => {
  const { classId, subject, date, status, startDate, endDate } = req.query;
  const filter = {};

  if (classId) filter.classId = classId;
  if (subject) filter.subject = new RegExp(`^${subject}$`, 'i');
  if (status) filter.status = status;
  if (date) filter.date = date;
  if (startDate && endDate) {
    filter.date = { $gte: startDate, $lte: endDate };
  } else if (startDate) {
    filter.date = { $gte: startDate };
  } else if (endDate) {
    filter.date = { $lte: endDate };
  }

  const logs = await DailySyllabusLog.find(filter)
    .populate('classId', 'name section roomNumber')
    .populate('teacherId', 'name email avatar')
    .sort({ date: -1, createdAt: -1 })
    .limit(100);

  return res.status(200).json(
    new ApiResponse(200, logs, 'Daily syllabus logs retrieved successfully')
  );
});

/**
 * Get comprehensive syllabus tracker overview and statistics
 */
const getSyllabusTrackerOverview = asyncHandler(async (req, res) => {
  const { classId, subject } = req.query;
  const matchFilter = {};
  if (classId) matchFilter.classId = classId;
  if (subject) matchFilter.subject = new RegExp(`^${subject}$`, 'i');

  const logs = await DailySyllabusLog.find(matchFilter)
    .populate('classId', 'name section')
    .populate('teacherId', 'name')
    .sort({ date: -1, createdAt: -1 });

  const subjectProgress = {};
  let totalMinutes = 0;
  let completedCount = 0;
  let partiallyCompletedCount = 0;
  let pendingCount = 0;

  logs.forEach((log) => {
    totalMinutes += (log.durationMinutes || 0);
    if (log.status === 'COMPLETED') completedCount++;
    else if (log.status === 'PARTIALLY_COMPLETED') partiallyCompletedCount++;
    else pendingCount++;

    const subKey = log.subject;
    if (!subjectProgress[subKey]) {
      subjectProgress[subKey] = {
        subject: subKey,
        latestPercentage: log.completionPercentage || 0,
        lastLoggedDate: log.date,
        lastChapter: log.chapter,
        lastTopic: log.topic,
        nextTarget: log.nextClassTarget,
        totalLectures: 1,
      };
    } else {
      subjectProgress[subKey].totalLectures += 1;
    }
  });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalLogs: logs.length,
        totalTeachingHours: (totalMinutes / 60).toFixed(1),
        totalTeachingMinutes: totalMinutes,
        statusBreakdown: {
          completed: completedCount,
          partiallyCompleted: partiallyCompletedCount,
          pending: pendingCount,
        },
        subjectProgress: Object.values(subjectProgress),
        recentLogs: logs.slice(0, 15),
      },
      'Syllabus tracker overview retrieved successfully'
    )
  );
});

/**
 * Update an existing daily syllabus log
 */
const updateDailySyllabusLog = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const updates = req.body;

  if (updates.completionPercentage !== undefined) {
    updates.completionPercentage = Math.min(100, Math.max(0, Number(updates.completionPercentage) || 0));
  }
  if (updates.durationMinutes !== undefined) {
    updates.durationMinutes = Number(updates.durationMinutes) || 45;
  }

  const log = await DailySyllabusLog.findByIdAndUpdate(
    id,
    { $set: updates },
    { new: true, runValidators: true }
  )
    .populate('classId', 'name section roomNumber')
    .populate('teacherId', 'name email avatar');

  if (!log) {
    throw new ApiError(404, 'Daily syllabus log not found');
  }

  return res.status(200).json(
    new ApiResponse(200, log, 'Daily syllabus log updated successfully')
  );
});

/**
 * Delete a daily syllabus log
 */
const deleteDailySyllabusLog = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const log = await DailySyllabusLog.findByIdAndDelete(id);

  if (!log) {
    throw new ApiError(404, 'Daily syllabus log not found');
  }

  return res.status(200).json(
    new ApiResponse(200, null, 'Daily syllabus log deleted successfully')
  );
});

module.exports = {
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
};

