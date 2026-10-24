const Homework = require('../models/homework.model');
const HomeworkSubmission = require('../models/homeworkSubmission.model');
const ClassRoom = require('../models/classroom.model');
const Student = require('../models/student.model');
const NotificationService = require('../services/notification.service');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Teacher creates a subject-wise homework
 * Instantly triggers notification to all parents of the class!
 */
const createHomework = asyncHandler(async (req, res) => {
  const {
    title,
    description,
    subject,
    classId,
    assignedDate,
    submissionDate,
    maxMarks = 20,
    instructions = '',
    attachments = [],
  } = req.body;
  const teacher = req.user;

  if (!title || !description || !subject || !classId || !submissionDate) {
    throw new ApiError(400, 'Title, description, subject, classId, and submissionDate are required');
  }

  const classroom = await ClassRoom.findById(classId);
  if (!classroom) throw new ApiError(404, 'Classroom not found');

  // Format attachments properly
  const formattedAttachments = Array.isArray(attachments)
    ? attachments.map((att) =>
        typeof att === 'string'
          ? { title: 'Attached Document', fileUrl: att, fileType: att.endsWith('.pdf') ? 'PDF' : 'IMAGE' }
          : att
      )
    : [];

  const homework = await Homework.create({
    title,
    description,
    subject,
    classId,
    assignedDate: assignedDate || new Date(),
    submissionDate: new Date(submissionDate),
    maxMarks: Number(maxMarks) || 20,
    instructions,
    attachments: formattedAttachments,
    createdBy: teacher._id,
  });

  const formattedDueDate = new Date(submissionDate).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });

  // Instantly send push/in-app notification to all parents of this class!
  await NotificationService.sendNotification({
    title: `New Homework: ${subject} 📚`,
    message: `${title} - Due: ${formattedDueDate}. Please ensure your child submits on time.`,
    type: 'HOMEWORK',
    targetRole: 'PARENTS',
    classId,
    senderId: teacher._id,
    metaData: {
      homeworkId: homework._id,
      subject,
      submissionDate,
    },
  });

  return res.status(201).json(
    new ApiResponse(
      201,
      homework,
      'Homework assigned successfully and instant notification sent to parents!'
    )
  );
});

/**
 * Get homework for a specific class with submission statistics
 */
const getClassHomework = asyncHandler(async (req, res) => {
  const { classId } = req.params;
  const { subject } = req.query;

  const filter = { classId };
  if (subject) filter.subject = new RegExp(subject, 'i');

  const homeworkList = await Homework.find(filter)
    .populate('createdBy', 'name email')
    .sort({ submissionDate: -1 });

  const totalStudents = await Student.countDocuments({ classId });

  // For each homework, compute submission counters
  const enrichedList = await Promise.all(
    homeworkList.map(async (hw) => {
      const submissions = await HomeworkSubmission.find({ homeworkId: hw._id });
      const submittedCount = submissions.length;
      const gradedCount = submissions.filter((s) => s.status === 'GRADED').length;
      const lateCount = submissions.filter((s) => s.isLate).length;
      const pendingCount = Math.max(0, totalStudents - submittedCount);

      return {
        ...hw.toObject(),
        stats: {
          totalStudents,
          submittedCount,
          gradedCount,
          pendingCount,
          lateCount,
        },
      };
    })
  );

  return res.status(200).json(
    new ApiResponse(200, enrichedList, 'Homework assignments retrieved successfully')
  );
});

/**
 * Get all student submissions for a specific homework
 * Lists both submitted students (with marks, feedback, files, late status)
 * and pending students who haven't submitted yet!
 */
const getHomeworkSubmissions = asyncHandler(async (req, res) => {
  const { homeworkId } = req.params;

  const homework = await Homework.findById(homeworkId).populate('classId', 'name section');
  if (!homework) throw new ApiError(404, 'Homework not found');

  // Find all students enrolled in this class
  const students = await Student.find({ classId: homework.classId._id })
    .populate('parentId', 'name email phone avatar')
    .sort({ rollNumber: 1 });

  // Find all submissions for this homework
  const submissions = await HomeworkSubmission.find({ homeworkId })
    .populate('studentId', 'name rollNumber avatar parentId')
    .populate('gradedBy', 'name');

  const submissionMap = new Map();
  submissions.forEach((sub) => {
    if (sub.studentId) {
      submissionMap.set(sub.studentId._id.toString(), sub);
    }
  });

  // Construct consolidated roster
  const studentRoster = students.map((std) => {
    const existingSub = submissionMap.get(std._id.toString());
    if (existingSub) {
      return {
        student: std,
        hasSubmitted: true,
        submission: existingSub,
        status: existingSub.status,
        isLate: existingSub.isLate,
        marksObtained: existingSub.marksObtained,
        maxMarks: homework.maxMarks,
        feedback: existingSub.feedback,
        submittedAt: existingSub.submittedAt,
        attachments: existingSub.attachments,
        submissionText: existingSub.submissionText,
      };
    } else {
      return {
        student: std,
        hasSubmitted: false,
        submission: null,
        status: 'PENDING',
        isLate: new Date() > new Date(homework.submissionDate),
        marksObtained: null,
        maxMarks: homework.maxMarks,
        feedback: '',
        submittedAt: null,
        attachments: [],
        submissionText: '',
      };
    }
  });

  const submittedCount = submissions.length;
  const gradedCount = submissions.filter((s) => s.status === 'GRADED').length;
  const pendingCount = students.length - submittedCount;
  const lateCount = studentRoster.filter((r) => r.isLate).length;

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        homework,
        summary: {
          totalStudents: students.length,
          submittedCount,
          gradedCount,
          pendingCount,
          lateCount,
        },
        roster: studentRoster,
      },
      'Homework submissions and student roster retrieved'
    )
  );
});

/**
 * Teacher grades a student's submission and provides marks & feedback
 */
const gradeSubmission = asyncHandler(async (req, res) => {
  const { homeworkId, studentId } = req.params;
  const { marksObtained, feedback = '', status = 'GRADED' } = req.body;
  const teacher = req.user;

  const homework = await Homework.findById(homeworkId);
  if (!homework) throw new ApiError(404, 'Homework assignment not found');

  const student = await Student.findById(studentId);
  if (!student) throw new ApiError(404, 'Student not found');

  let submission = await HomeworkSubmission.findOne({ homeworkId, studentId });

  if (!submission) {
    // If student hadn't submitted online, teacher can still record offline/checked submission!
    submission = new HomeworkSubmission({
      homeworkId,
      studentId,
      classId: homework.classId,
      submissionText: 'Graded in classroom',
      submittedAt: new Date(),
    });
  }

  submission.marksObtained = Number(marksObtained);
  submission.maxMarks = homework.maxMarks;
  submission.feedback = feedback;
  submission.status = status; // 'GRADED' or 'RESUBMISSION_REQUESTED'
  submission.gradedBy = teacher._id;
  submission.gradedAt = new Date();

  await submission.save();

  // Send instant notification to student's parent about homework score & feedback
  if (student.parentId) {
    const statusMsg =
      status === 'GRADED'
        ? `Marks: ${marksObtained}/${homework.maxMarks} 📝. Feedback: "${feedback || 'Checked and reviewed'}"`
        : `Teacher requested resubmission. Feedback: "${feedback}"`;

    await NotificationService.sendNotification({
      title: `Homework Checked: ${homework.subject}`,
      message: `${student.name}'s homework "${homework.title}" has been reviewed. ${statusMsg}`,
      type: 'HOMEWORK',
      targetRole: 'SPECIFIC',
      recipientId: student.parentId,
      classId: homework.classId,
      senderId: teacher._id,
      metaData: {
        homeworkId: homework._id,
        studentId: student._id,
        marksObtained,
        maxMarks: homework.maxMarks,
        feedback,
      },
    });
  }

  return res.status(200).json(
    new ApiResponse(200, submission, 'Homework submission graded and parent notified!')
  );
});

/**
 * Student/Parent submits homework
 */
const submitHomework = asyncHandler(async (req, res) => {
  const { homeworkId } = req.params;
  const { studentId, submissionText = '', attachments = [] } = req.body;

  const homework = await Homework.findById(homeworkId);
  if (!homework) throw new ApiError(404, 'Homework not found');

  const isLate = new Date() > new Date(homework.submissionDate);

  const formattedAttachments = Array.isArray(attachments)
    ? attachments.map((att) =>
        typeof att === 'string'
          ? { title: 'Submitted File', fileUrl: att, fileType: att.endsWith('.pdf') ? 'PDF' : 'IMAGE' }
          : att
      )
    : [];

  const submission = await HomeworkSubmission.findOneAndUpdate(
    { homeworkId, studentId },
    {
      $set: {
        classId: homework.classId,
        submissionText,
        attachments: formattedAttachments,
        submittedAt: new Date(),
        isLate,
        status: 'SUBMITTED',
      },
    },
    { upsert: true, new: true, runValidators: true }
  );

  return res.status(200).json(
    new ApiResponse(200, submission, isLate ? 'Homework submitted (Late submission recorded)' : 'Homework submitted successfully!')
  );
});

/**
 * Delete a homework assignment and all its submissions
 */
const deleteHomework = asyncHandler(async (req, res) => {
  const { homeworkId } = req.params;

  const homework = await Homework.findByIdAndDelete(homeworkId);
  if (!homework) throw new ApiError(404, 'Homework not found');

  await HomeworkSubmission.deleteMany({ homeworkId });

  return res.status(200).json(
    new ApiResponse(200, null, 'Homework assignment deleted successfully')
  );
});

module.exports = {
  createHomework,
  getClassHomework,
  getHomeworkSubmissions,
  gradeSubmission,
  submitHomework,
  deleteHomework,
};
