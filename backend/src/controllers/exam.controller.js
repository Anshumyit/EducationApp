const ExamResult = require('../models/examResult.model');
const Student = require('../models/student.model');
const NotificationService = require('../services/notification.service');
const { EXAM_TYPES } = require('../constants/status');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Teacher records or updates exam marks for a student
 */
const recordExamMarks = asyncHandler(async (req, res) => {
  const { studentId, classId, examType, examTitle, academicYear, subjects } = req.body;
  const teacher = req.user;

  if (!studentId || !classId || !examType || !examTitle || !subjects || !Array.isArray(subjects)) {
    throw new ApiError(400, 'studentId, classId, examType, examTitle, and subjects array are required');
  }

  if (!Object.values(EXAM_TYPES).includes(examType)) {
    throw new ApiError(400, `Invalid examType. Must be one of: ${Object.values(EXAM_TYPES).join(', ')}`);
  }

  const student = await Student.findById(studentId).populate('parentId');
  if (!student) throw new ApiError(404, 'Student not found');

  // Check if result already exists for this student, examType, and examTitle
  let result = await ExamResult.findOne({ studentId, examType, examTitle });

  if (result) {
    result.subjects = subjects;
    result.academicYear = academicYear || result.academicYear;
    result.enteredBy = teacher._id;
    await result.save();
  } else {
    result = await ExamResult.create({
      studentId,
      classId,
      examType,
      examTitle,
      academicYear: academicYear || '2026-2027',
      subjects,
      enteredBy: teacher._id,
    });
  }

  // Instant notification to parent
  if (student.parentId) {
    await NotificationService.sendNotification({
      title: `Exam Result Published: ${examTitle} 📊`,
      message: `Results for ${student.name} in ${examTitle} (${examType.replace('_', ' ')}) are now available. Score: ${result.percentage}% (Grade: ${result.overallGrade}).`,
      type: 'RESULT',
      targetRole: 'SPECIFIC',
      recipientId: student.parentId._id,
      senderId: teacher._id,
      metaData: {
        studentId: student._id,
        examId: result._id,
        percentage: result.percentage,
        grade: result.overallGrade,
      },
    });
  }

  return res.status(201).json(
    new ApiResponse(201, result, 'Exam results recorded and parent notified successfully!')
  );
});

/**
 * Get results for a student (filtered by examType or all)
 */
const getStudentResults = asyncHandler(async (req, res) => {
  const { studentId } = req.params;
  const { examType, academicYear } = req.query;

  const filter = { studentId };
  if (examType) filter.examType = examType;
  if (academicYear) filter.academicYear = academicYear;

  const results = await ExamResult.find(filter)
    .populate('classId', 'name section')
    .sort({ examDate: -1 });

  return res.status(200).json(
    new ApiResponse(200, results, 'Student exam results retrieved')
  );
});

/**
 * Class teacher generates class-wide results for a specific exam
 */
const getClassExamResults = asyncHandler(async (req, res) => {
  const { classId } = req.params;
  const { examType, examTitle } = req.query;

  const filter = { classId };
  if (examType) filter.examType = examType;
  if (examTitle) filter.examTitle = examTitle;

  const results = await ExamResult.find(filter)
    .populate('studentId', 'name rollNumber admissionNumber photo')
    .sort({ percentage: -1 });

  const highestScore = results.length > 0 ? results[0].percentage : 0;
  const averageScore =
    results.length > 0
      ? parseFloat((results.reduce((acc, r) => acc + r.percentage, 0) / results.length).toFixed(2))
      : 0;

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        classId,
        totalEntries: results.length,
        highestScore,
        averageScore,
        results,
      },
      'Class exam performance report generated'
    )
  );
});

/**
 * Generate Comprehensive Annual / Multi-Term Report Card for Student
 */
const getAnnualReportCard = asyncHandler(async (req, res) => {
  const { studentId } = req.params;
  const { academicYear = '2026-2027' } = req.query;

  const student = await Student.findById(studentId).populate('classId').populate('parentId', 'name phone');
  if (!student) throw new ApiError(404, 'Student not found');

  const allResults = await ExamResult.find({ studentId, academicYear }).sort({ createdAt: 1 });

  const weeklyTests = allResults.filter((r) => r.examType === EXAM_TYPES.WEEKLY);
  const monthlyTests = allResults.filter((r) => r.examType === EXAM_TYPES.MONTHLY);
  const halfYearly = allResults.filter((r) => r.examType === EXAM_TYPES.HALF_YEARLY);
  const annual = allResults.filter((r) => r.examType === EXAM_TYPES.ANNUAL);

  const calculateAverage = (list) =>
    list.length > 0
      ? parseFloat((list.reduce((sum, r) => sum + r.percentage, 0) / list.length).toFixed(2))
      : null;

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        student,
        academicYear,
        summary: {
          weeklyAverage: calculateAverage(weeklyTests),
          monthlyAverage: calculateAverage(monthlyTests),
          halfYearlyAverage: calculateAverage(halfYearly),
          annualAverage: calculateAverage(annual),
          overallCumulative: calculateAverage(allResults),
        },
        breakdown: {
          weeklyTests,
          monthlyTests,
          halfYearly,
          annual,
        },
      },
      'Comprehensive report card generated'
    )
  );
});

module.exports = {
  recordExamMarks,
  getStudentResults,
  getClassExamResults,
  getAnnualReportCard,
};
