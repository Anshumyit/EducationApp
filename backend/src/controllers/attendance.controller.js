const Attendance = require('../models/attendance.model');
const Student = require('../models/student.model');
const NotificationService = require('../services/notification.service');
const { ATTENDANCE_STATUS } = require('../constants/status');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Teacher marks daily attendance for entire class
 * Sends instant notifications to parents!
 */
const markAttendance = asyncHandler(async (req, res) => {
  const { classId, date, records } = req.body;
  const teacher = req.user;

  if (!classId || !date || !records || !Array.isArray(records)) {
    throw new ApiError(400, 'classId, date (YYYY-MM-DD), and records array are required');
  }

  // Upsert attendance record for the date and class
  let attendance = await Attendance.findOne({ classId, date });

  if (attendance) {
    attendance.records = records;
    attendance.markedBy = teacher._id;
    await attendance.save();
  } else {
    attendance = await Attendance.create({
      classId,
      date,
      markedBy: teacher._id,
      records,
    });
  }

  // Send instant real-time notification to each student's parent
  // Do asynchronously in background so response isn't delayed
  (async () => {
    try {
      const studentIds = records.map((r) => r.studentId);
      const students = await Student.find({ _id: { $in: studentIds } }).populate('parentId');

      const studentMap = {};
      students.forEach((s) => {
        studentMap[s._id.toString()] = s;
      });

      for (const rec of records) {
        const student = studentMap[rec.studentId.toString()];
        if (student && student.parentId) {
          const statusText = rec.status;
          const statusIcon = statusText === 'PRESENT' ? '✅' : statusText === 'ABSENT' ? '❌' : '⚠️';

          await NotificationService.sendNotification({
            title: `Attendance Update: ${student.name} ${statusIcon}`,
            message: `Your ward ${student.name} was marked ${statusText} on ${date}.`,
            type: 'ATTENDANCE',
            targetRole: 'SPECIFIC',
            recipientId: student.parentId._id,
            classId,
            senderId: teacher._id,
            metaData: {
              studentId: student._id,
              date,
              status: rec.status,
            },
          });
        }
      }
    } catch (err) {
      console.error('[Attendance Notification Error]', err.message);
    }
  })();

  return res.status(200).json(
    new ApiResponse(
      200,
      attendance,
      'Attendance marked successfully and notifications dispatched to parents!'
    )
  );
});

/**
 * Get attendance for a specific class and date
 */
const getAttendanceByDate = asyncHandler(async (req, res) => {
  const { classId, date } = req.query;

  if (!classId || !date) {
    throw new ApiError(400, 'classId and date are required');
  }

  const attendance = await Attendance.findOne({ classId, date }).populate('records.studentId', 'name rollNumber photo');

  let presentCount = 0;
  let absentCount = 0;
  let lateCount = 0;
  let halfDayCount = 0;
  const presentStudents = [];
  const absentStudents = [];
  const lateStudents = [];

  if (attendance && attendance.records) {
    attendance.records.forEach((r) => {
      const s = r.studentId;
      const studentInfo = s
        ? {
            _id: s._id,
            name: s.name,
            rollNumber: s.rollNumber,
            photo: s.photo,
            status: r.status,
            remarks: r.remarks,
          }
        : {
            _id: null,
            name: 'Unknown',
            rollNumber: '-',
            status: r.status,
            remarks: r.remarks,
          };

      if (r.status === ATTENDANCE_STATUS.PRESENT) {
        presentCount++;
        presentStudents.push(studentInfo);
      } else if (r.status === ATTENDANCE_STATUS.ABSENT) {
        absentCount++;
        absentStudents.push(studentInfo);
      } else if (r.status === ATTENDANCE_STATUS.LATE) {
        lateCount++;
        lateStudents.push(studentInfo);
      } else if (r.status === ATTENDANCE_STATUS.HALF_DAY) {
        halfDayCount++;
      }
    });
  }

  const responseData = {
    _id: attendance ? attendance._id : null,
    attendance,
    isMarked: !!attendance,
    date,
    classId,
    records: attendance ? attendance.records : [],
    summary: {
      totalStudents: attendance ? attendance.records.length : 0,
      presentCount,
      absentCount,
      lateCount,
      halfDayCount,
      presentStudents,
      absentStudents,
      lateStudents,
    },
  };

  return res.status(200).json(
    new ApiResponse(200, responseData, 'Attendance retrieved')
  );
});

/**
 * Get attendance logs/history for a class (recent or filtered by month/year)
 */
const getClassAttendanceLogs = asyncHandler(async (req, res) => {
  const { classId } = req.params;
  const { month, year, limit = 30 } = req.query;

  if (!classId) {
    throw new ApiError(400, 'classId is required');
  }

  const query = { classId };
  if (month && year) {
    const monthPrefix = `${year}-${month.toString().padStart(2, '0')}`;
    query.date = { $regex: `^${monthPrefix}` };
  } else if (year) {
    query.date = { $regex: `^${year}` };
  }

  const attendances = await Attendance.find(query)
    .populate('records.studentId', 'name rollNumber photo')
    .sort({ date: -1 })
    .limit(Number(limit));

  const logs = attendances.map((att) => {
    let presentCount = 0;
    let absentCount = 0;
    let lateCount = 0;
    let halfDayCount = 0;
    const presentStudents = [];
    const absentStudents = [];
    const lateStudents = [];

    att.records.forEach((r) => {
      const s = r.studentId;
      const studentInfo = s
        ? {
            _id: s._id,
            name: s.name,
            rollNumber: s.rollNumber,
            photo: s.photo,
            status: r.status,
            remarks: r.remarks,
          }
        : {
            _id: null,
            name: 'Unknown',
            rollNumber: '-',
            status: r.status,
            remarks: r.remarks,
          };

      if (r.status === ATTENDANCE_STATUS.PRESENT) {
        presentCount++;
        presentStudents.push(studentInfo);
      } else if (r.status === ATTENDANCE_STATUS.ABSENT) {
        absentCount++;
        absentStudents.push(studentInfo);
      } else if (r.status === ATTENDANCE_STATUS.LATE) {
        lateCount++;
        lateStudents.push(studentInfo);
      } else if (r.status === ATTENDANCE_STATUS.HALF_DAY) {
        halfDayCount++;
      }
    });

    return {
      _id: att._id,
      date: att.date,
      classId: att.classId,
      totalStudents: att.records.length,
      presentCount,
      absentCount,
      lateCount,
      halfDayCount,
      presentStudents,
      absentStudents,
      lateStudents,
      records: att.records,
    };
  });

  return res.status(200).json(
    new ApiResponse(200, logs, 'Class attendance logs retrieved')
  );
});

/**
 * Generate monthly attendance report for a specific student
 */
const getStudentAttendanceReport = asyncHandler(async (req, res) => {
  const { studentId } = req.params;
  const { month, year } = req.query; // e.g. month: "10", year: "2026"

  const student = await Student.findById(studentId).populate('classId');
  if (!student) throw new ApiError(404, 'Student not found');

  const currentYear = year || new Date().getFullYear().toString();
  const currentMonth = month ? month.toString().padStart(2, '0') : (new Date().getMonth() + 1).toString().padStart(2, '0');
  const monthPrefix = `${currentYear}-${currentMonth}`;

  // Find all attendance records for student's class matching the month prefix
  const attendances = await Attendance.find({
    classId: student.classId._id,
    date: { $regex: `^${monthPrefix}` },
  }).sort({ date: 1 });

  let presentCount = 0;
  let absentCount = 0;
  let lateCount = 0;
  let halfDayCount = 0;
  const dailyHistory = [];

  attendances.forEach((att) => {
    const record = att.records.find((r) => {
      const sid = r.studentId?._id ? r.studentId._id.toString() : r.studentId?.toString();
      return sid === studentId.toString();
    });
    const status = record ? record.status : 'NOT_MARKED';

    if (status === ATTENDANCE_STATUS.PRESENT) presentCount++;
    else if (status === ATTENDANCE_STATUS.ABSENT) absentCount++;
    else if (status === ATTENDANCE_STATUS.LATE) lateCount++;
    else if (status === ATTENDANCE_STATUS.HALF_DAY) halfDayCount++;

    dailyHistory.push({
      date: att.date,
      status,
      remarks: record ? record.remarks : '',
    });
  });

  const totalDays = attendances.length;
  const effectivePresent = presentCount + lateCount * 0.8 + halfDayCount * 0.5;
  const percentage = totalDays > 0 ? parseFloat(((effectivePresent / totalDays) * 100).toFixed(1)) : 100;

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        student: {
          id: student._id,
          name: student.name,
          rollNumber: student.rollNumber,
          class: student.classId,
        },
        period: {
          month: currentMonth,
          year: currentYear,
        },
        summary: {
          totalWorkingDays: totalDays,
          present: presentCount,
          absent: absentCount,
          late: lateCount,
          halfDay: halfDayCount,
          percentage,
        },
        dailyHistory,
      },
      'Monthly student attendance report generated'
    )
  );
});

/**
 * Class Teacher generates class-wide monthly attendance summary
 */
const getClassMonthlyReport = asyncHandler(async (req, res) => {
  const { classId } = req.params;
  const { month, year } = req.query;

  const currentYear = year || new Date().getFullYear().toString();
  const currentMonth = month ? month.toString().padStart(2, '0') : (new Date().getMonth() + 1).toString().padStart(2, '0');
  const monthPrefix = `${currentYear}-${currentMonth}`;

  const students = await Student.find({ classId }).sort({ rollNumber: 1 });
  const attendances = await Attendance.find({
    classId,
    date: { $regex: `^${monthPrefix}` },
  }).populate('records.studentId', 'name rollNumber photo').sort({ date: -1 });

  const totalWorkingDays = attendances.length;

  const studentReports = students.map((student) => {
    let present = 0;
    let absent = 0;
    let late = 0;
    let halfDay = 0;

    attendances.forEach((att) => {
      const rec = att.records.find((r) => {
        const sid = r.studentId?._id ? r.studentId._id.toString() : r.studentId?.toString();
        return sid === student._id.toString();
      });
      if (rec) {
        if (rec.status === ATTENDANCE_STATUS.PRESENT) present++;
        else if (rec.status === ATTENDANCE_STATUS.ABSENT) absent++;
        else if (rec.status === ATTENDANCE_STATUS.LATE) late++;
        else if (rec.status === ATTENDANCE_STATUS.HALF_DAY) halfDay++;
      }
    });

    const effectivePresent = present + late * 0.8 + halfDay * 0.5;
    const percentage = totalWorkingDays > 0 ? parseFloat(((effectivePresent / totalWorkingDays) * 100).toFixed(1)) : 100;

    return {
      studentId: student._id,
      name: student.name,
      rollNumber: student.rollNumber,
      photo: student.photo,
      present,
      absent,
      late,
      halfDay,
      totalWorkingDays,
      percentage,
    };
  });

  // Calculate overall class average
  let totalPct = 0;
  studentReports.forEach((sr) => (totalPct += sr.percentage));
  const classAverage = studentReports.length > 0 ? parseFloat((totalPct / studentReports.length).toFixed(1)) : 0;

  // Build daily breakdown logs for this month
  const dailyBreakdown = attendances.map((att) => {
    let presentCount = 0;
    let absentCount = 0;
    let lateCount = 0;
    const absentStudents = [];
    const lateStudents = [];
    const presentStudents = [];

    att.records.forEach((r) => {
      const s = r.studentId;
      const sInfo = s ? { _id: s._id, name: s.name, rollNumber: s.rollNumber } : { name: 'Student', rollNumber: '-' };
      if (r.status === ATTENDANCE_STATUS.PRESENT) {
        presentCount++;
        presentStudents.push(sInfo);
      } else if (r.status === ATTENDANCE_STATUS.ABSENT) {
        absentCount++;
        absentStudents.push(sInfo);
      } else if (r.status === ATTENDANCE_STATUS.LATE) {
        lateCount++;
        lateStudents.push(sInfo);
      }
    });

    return {
      _id: att._id,
      date: att.date,
      totalStudents: att.records.length,
      presentCount,
      absentCount,
      lateCount,
      absentStudents,
      lateStudents,
      presentStudents,
    };
  });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        classId,
        period: { month: currentMonth, year: currentYear },
        totalWorkingDays,
        totalStudents: students.length,
        classAverage,
        studentReports,
        dailyBreakdown,
      },
      'Class monthly attendance report generated'
    )
  );
});

module.exports = {
  markAttendance,
  getAttendanceByDate,
  getClassAttendanceLogs,
  getStudentAttendanceReport,
  getClassMonthlyReport,
};
