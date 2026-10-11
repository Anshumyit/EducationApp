const Student = require('../models/student.model');
const Attendance = require('../models/attendance.model');
const Homework = require('../models/homework.model');
const FeeRecord = require('../models/feeRecord.model');
const ExamResult = require('../models/examResult.model');
const Holiday = require('../models/holiday.model');
const { ATTENDANCE_STATUS } = require('../constants/status');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Get all children linked to the logged-in parent
 */
const getMyChildren = asyncHandler(async (req, res) => {
  const parent = req.user;

  const children = await Student.find({ parentId: parent._id })
    .populate({
      path: 'classId',
      populate: { path: 'classTeacher', select: 'name email phone avatar' },
    })
    .sort({ rollNumber: 1 });

  return res.status(200).json(
    new ApiResponse(200, children, 'Children list retrieved')
  );
});

/**
 * Get child summary dashboard
 */
const getChildDashboard = asyncHandler(async (req, res) => {
  const { studentId } = req.params;
  const parent = req.user;

  const student = await Student.findOne({ _id: studentId, parentId: parent._id }).populate({
    path: 'classId',
    populate: { path: 'classTeacher', select: 'name email phone avatar' },
  });

  if (!student) {
    throw new ApiError(404, 'Child profile not found');
  }

  const todayStr = new Date().toISOString().split('T')[0];
  const todayAttendance = await Attendance.findOne({
    classId: student.classId._id,
    date: todayStr,
  });

  let todayStatus = 'NOT_YET_MARKED';
  if (todayAttendance) {
    const rec = todayAttendance.records.find((r) => r.studentId.toString() === student._id.toString());
    if (rec) todayStatus = rec.status;
  }

  // Active homework assignments
  const activeHomeworkCount = await Homework.countDocuments({
    classId: student.classId._id,
    submissionDate: { $gte: new Date() },
  });

  // Recent exam result
  const latestResult = await ExamResult.findOne({ studentId: student._id }).sort({ examDate: -1 });

  // Fee summary
  const feeRecords = await FeeRecord.find({ studentId: student._id });
  const totalDue = feeRecords.reduce((sum, f) => sum + (f.totalAmount - f.paidAmount), 0);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        student,
        todayAttendance: todayStatus,
        activeHomeworkCount,
        latestResult,
        totalFeeDue: totalDue,
      },
      'Child dashboard summary retrieved'
    )
  );
});

/**
 * Get School Holidays calendar
 */
const getHolidays = asyncHandler(async (req, res) => {
  const holidays = await Holiday.find().sort({ startDate: 1 });
  return res.status(200).json(new ApiResponse(200, holidays, 'Holidays retrieved'));
});

module.exports = {
  getMyChildren,
  getChildDashboard,
  getHolidays,
};
