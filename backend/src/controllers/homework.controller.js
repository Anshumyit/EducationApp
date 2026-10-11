const Homework = require('../models/homework.model');
const ClassRoom = require('../models/classroom.model');
const NotificationService = require('../services/notification.service');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Teacher creates a subject-wise homework
 * Instantly triggers notification to all parents of the class!
 */
const createHomework = asyncHandler(async (req, res) => {
  const { title, description, subject, classId, assignedDate, submissionDate, attachments } = req.body;
  const teacher = req.user;

  if (!title || !description || !subject || !classId || !submissionDate) {
    throw new ApiError(400, 'Title, description, subject, classId, and submissionDate are required');
  }

  const classroom = await ClassRoom.findById(classId);
  if (!classroom) throw new ApiError(404, 'Classroom not found');

  const homework = await Homework.create({
    title,
    description,
    subject,
    classId,
    assignedDate: assignedDate || new Date(),
    submissionDate: new Date(submissionDate),
    attachments: attachments || [],
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
 * Get homework for a specific class
 */
const getClassHomework = asyncHandler(async (req, res) => {
  const { classId } = req.params;
  const { subject } = req.query;

  const filter = { classId };
  if (subject) filter.subject = new RegExp(subject, 'i');

  const homeworkList = await Homework.find(filter)
    .populate('createdBy', 'name email')
    .sort({ submissionDate: -1 });

  return res.status(200).json(
    new ApiResponse(200, homeworkList, 'Homework assignments retrieved')
  );
});

module.exports = {
  createHomework,
  getClassHomework,
};
