const CommunicationMessage = require('../models/communicationMessage.model');
const MeetingSchedule = require('../models/meetingSchedule.model');
const Student = require('../models/student.model');
const User = require('../models/user.model');
const Attendance = require('../models/attendance.model');
const ExamResult = require('../models/examResult.model');
const NotificationService = require('../services/notification.service');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * 1. Send Individual Direct Message to Parent or Teacher
 */
const sendDirectMessage = asyncHandler(async (req, res) => {
  const sender = req.user;
  const {
    recipientId,
    studentId,
    message,
    attachments = [],
    type = 'INDIVIDUAL_MESSAGE',
    title = '',
  } = req.body;

  if (!recipientId || !message) {
    throw new ApiError(400, 'Recipient ID and message content are required');
  }

  const recipient = await User.findById(recipientId);
  if (!recipient) throw new ApiError(404, 'Recipient user not found');

  const communication = await CommunicationMessage.create({
    senderId: sender._id,
    senderRole: sender.role,
    recipientId,
    studentId: studentId || null,
    type,
    title,
    message,
    attachments,
    status: 'DELIVERED', // Message delivered to system
    deliveredAt: new Date(),
  });

  const populated = await CommunicationMessage.findById(communication._id)
    .populate('senderId', 'name role avatar')
    .populate('recipientId', 'name role avatar')
    .populate('studentId', 'name rollNumber');

  // Trigger real-time notification
  await NotificationService.sendNotification({
    title: `New Message from ${sender.name} 💬`,
    message: message.length > 80 ? `${message.substring(0, 80)}...` : message,
    type: 'GENERAL',
    targetRole: 'SPECIFIC',
    recipientId,
    senderId: sender._id,
    metaData: {
      messageId: communication._id,
      studentId,
      senderRole: sender.role,
    },
  });

  return res.status(201).json(
    new ApiResponse(201, populated, 'Message sent successfully and delivered!')
  );
});

/**
 * 2. Get 1-on-1 Conversation between logged-in user and another user
 * Automatically marks unread incoming messages as READ!
 */
const getConversation = asyncHandler(async (req, res) => {
  const currentUserId = req.user._id;
  const { otherUserId } = req.params;
  const { studentId } = req.query;

  const filter = {
    $or: [
      { senderId: currentUserId, recipientId: otherUserId },
      { senderId: otherUserId, recipientId: currentUserId },
    ],
  };

  if (studentId) filter.studentId = studentId;

  // Mark all incoming unread messages as READ
  await CommunicationMessage.updateMany(
    { senderId: otherUserId, recipientId: currentUserId, status: { $ne: 'READ' } },
    { $set: { status: 'READ', readAt: new Date() } }
  );

  const messages = await CommunicationMessage.find(filter)
    .populate('senderId', 'name role avatar')
    .populate('recipientId', 'name role avatar')
    .populate('studentId', 'name rollNumber')
    .sort({ createdAt: 1 });

  return res.status(200).json(
    new ApiResponse(200, messages, 'Conversation retrieved successfully')
  );
});

/**
 * 3. Class-wide Announcement by Class Teacher
 */
const sendClassAnnouncement = asyncHandler(async (req, res) => {
  const teacher = req.user;
  const { classId, title, message, attachments = [] } = req.body;

  if (!classId || !title || !message) {
    throw new ApiError(400, 'Class ID, title, and message are required');
  }

  const announcement = await CommunicationMessage.create({
    senderId: teacher._id,
    senderRole: teacher.role,
    classId,
    type: 'CLASS_ANNOUNCEMENT',
    title,
    message,
    attachments,
    status: 'DELIVERED',
    deliveredAt: new Date(),
  });

  const studentsCount = await Student.countDocuments({ classId });

  // Broadcast notification to all class parents
  await NotificationService.sendNotification({
    title: `📢 Class Announcement: ${title}`,
    message,
    type: 'BROADCAST',
    targetRole: 'PARENTS',
    classId,
    senderId: teacher._id,
    metaData: {
      announcementId: announcement._id,
      attachmentsCount: attachments.length,
    },
  });

  return res.status(201).json(
    new ApiResponse(
      201,
      { announcement, deliveredCount: studentsCount },
      'Class announcement dispatched and parents alerted!'
    )
  );
});

/**
 * 4. Get Class Announcements
 */
const getClassAnnouncements = asyncHandler(async (req, res) => {
  const { classId } = req.params;

  const announcements = await CommunicationMessage.find({
    classId,
    type: 'CLASS_ANNOUNCEMENT',
  })
    .populate('senderId', 'name avatar')
    .sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, announcements, 'Class announcements retrieved')
  );
});

/**
 * 5. Share Student Progress Card directly with Parent
 */
const shareStudentProgress = asyncHandler(async (req, res) => {
  const teacher = req.user;
  const { studentId, teacherRemarks = '', overallGrade = 'A' } = req.body;

  const student = await Student.findById(studentId)
    .populate('parentId', 'name email')
    .populate('classId', 'name section');

  if (!student) throw new ApiError(404, 'Student not found');
  if (!student.parentId) throw new ApiError(400, 'Student does not have a linked parent account');

  // Compute live attendance rate
  const attendanceRecords = await Attendance.find({
    classId: student.classId._id,
    'records.studentId': student._id,
  });

  let presentCount = 0;
  attendanceRecords.forEach((att) => {
    const rec = att.records.find((r) => r.studentId.toString() === student._id.toString());
    if (rec && (rec.status === 'PRESENT' || rec.status === 'LATE')) presentCount++;
  });

  const attendancePercentage = attendanceRecords.length > 0
    ? Math.round((presentCount / attendanceRecords.length) * 100)
    : 92;

  // Recent exam marks
  const examResults = await ExamResult.find({ studentId: student._id }).limit(3);

  const progressSummary = {
    studentName: student.name,
    rollNumber: student.rollNumber,
    className: `${student.classId.name} - ${student.classId.section}`,
    attendancePercentage,
    overallGrade,
    teacherRemarks: teacherRemarks || 'Showing steady progress in coursework and classroom engagement.',
    examResults: examResults.map((e) => ({
      examTitle: e.examTitle,
      percentage: e.percentage,
      grade: e.grade,
    })),
    sharedDate: new Date().toISOString(),
  };

  const messageText = `📊 Academic Progress Report for ${student.name} (#${student.rollNumber})\n` +
    `• Overall Grade: ${overallGrade}\n` +
    `• Attendance: ${attendancePercentage}%\n` +
    `• Teacher Remarks: "${progressSummary.teacherRemarks}"`;

  const communication = await CommunicationMessage.create({
    senderId: teacher._id,
    senderRole: teacher.role,
    recipientId: student.parentId._id,
    studentId: student._id,
    classId: student.classId._id,
    type: 'PROGRESS_SHARE',
    title: `Progress Report: ${student.name}`,
    message: messageText,
    status: 'DELIVERED',
    metaData: progressSummary,
  });

  // Alert parent
  await NotificationService.sendNotification({
    title: `📊 Student Progress Report: ${student.name}`,
    message: `Teacher ${teacher.name} has shared a progress report. Overall Grade: ${overallGrade}, Attendance: ${attendancePercentage}%.`,
    type: 'RESULT',
    targetRole: 'SPECIFIC',
    recipientId: student.parentId._id,
    classId: student.classId._id,
    senderId: teacher._id,
  });

  return res.status(201).json(
    new ApiResponse(201, communication, 'Progress report shared with parent successfully!')
  );
});

/**
 * 6. Schedule Meeting (PTM / 1-on-1 Meeting)
 */
const scheduleMeeting = asyncHandler(async (req, res) => {
  const teacher = req.user;
  const {
    parentId,
    studentId,
    classId,
    title,
    agenda = '',
    meetingDate,
    timeSlot,
    mode = 'IN_PERSON_AT_SCHOOL',
    meetLinkOrRoom = 'Room 204',
  } = req.body;

  if (!parentId || !studentId || !meetingDate || !timeSlot || !title) {
    throw new ApiError(400, 'Parent, Student, Title, Meeting Date, and Time Slot are required');
  }

  const meeting = await MeetingSchedule.create({
    teacherId: teacher._id,
    parentId,
    studentId,
    classId: classId || teacher.assignedClass,
    title,
    agenda,
    meetingDate,
    timeSlot,
    mode,
    meetLinkOrRoom,
    status: 'SCHEDULED',
  });

  const student = await Student.findById(studentId);

  // Send instant notification to parent
  await NotificationService.sendNotification({
    title: `📅 Meeting Scheduled: ${title}`,
    message: `Meeting on ${meetingDate} at ${timeSlot} (${mode.replace(/_/g, ' ')}: ${meetLinkOrRoom}) regarding ${student?.name || 'your child'}.`,
    type: 'GENERAL',
    targetRole: 'SPECIFIC',
    recipientId: parentId,
    senderId: teacher._id,
    metaData: { meetingId: meeting._id },
  });

  return res.status(201).json(
    new ApiResponse(201, meeting, 'Meeting scheduled and parent notified!')
  );
});

/**
 * 7. Get Meetings List
 */
const getMeetings = asyncHandler(async (req, res) => {
  const user = req.user;
  const filter = {};

  if (user.role === 'TEACHER') {
    filter.teacherId = user._id;
  } else if (user.role === 'PARENT') {
    filter.parentId = user._id;
  }

  const meetings = await MeetingSchedule.find(filter)
    .populate('teacherId', 'name email phone avatar')
    .populate('parentId', 'name email phone avatar')
    .populate('studentId', 'name rollNumber')
    .populate('classId', 'name section')
    .sort({ meetingDate: 1, createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, meetings, 'Meetings retrieved successfully')
  );
});

/**
 * 8. Update Meeting Status & Notes
 */
const updateMeetingStatus = asyncHandler(async (req, res) => {
  const { meetingId } = req.params;
  const { status, teacherNotes, parentFeedback } = req.body;

  const updateFields = {};
  if (status) updateFields.status = status;
  if (teacherNotes !== undefined) updateFields.teacherNotes = teacherNotes;
  if (parentFeedback !== undefined) updateFields.parentFeedback = parentFeedback;

  const meeting = await MeetingSchedule.findByIdAndUpdate(
    meetingId,
    { $set: updateFields },
    { new: true }
  )
    .populate('teacherId', 'name')
    .populate('parentId', 'name')
    .populate('studentId', 'name');

  if (!meeting) throw new ApiError(404, 'Meeting not found');

  return res.status(200).json(
    new ApiResponse(200, meeting, 'Meeting updated successfully')
  );
});

/**
 * 9. Get Parent Queries & Complaints
 */
const getParentQueriesAndComplaints = asyncHandler(async (req, res) => {
  const user = req.user;
  const filter = {
    type: { $in: ['PARENT_QUERY', 'COMPLAINT'] },
  };

  if (user.role === 'TEACHER') {
    filter.$or = [{ recipientId: user._id }, { senderId: user._id }];
  } else if (user.role === 'PARENT') {
    filter.senderId = user._id;
  }

  const queries = await CommunicationMessage.find(filter)
    .populate('senderId', 'name role avatar')
    .populate('recipientId', 'name role avatar')
    .populate('studentId', 'name rollNumber')
    .sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, queries, 'Queries and complaints retrieved')
  );
});

/**
 * 10. Teacher replies to Parent Query/Complaint
 */
const replyToParentQuery = asyncHandler(async (req, res) => {
  const teacher = req.user;
  const { queryId } = req.params;
  const { replyMessage, resolutionStatus = 'RESOLVED' } = req.body;

  if (!replyMessage) throw new ApiError(400, 'Reply message is required');

  const query = await CommunicationMessage.findById(queryId).populate('senderId', 'name email');
  if (!query) throw new ApiError(404, 'Query/Complaint not found');

  // Update original query resolution status
  query.resolutionStatus = resolutionStatus;
  await query.save();

  // Create reply message
  const reply = await CommunicationMessage.create({
    senderId: teacher._id,
    senderRole: teacher.role,
    recipientId: query.senderId._id,
    studentId: query.studentId,
    classId: query.classId,
    type: query.type,
    title: `Re: ${query.title || 'Inquiry'}`,
    message: replyMessage,
    replyTo: query._id,
    resolutionStatus,
    status: 'DELIVERED',
  });

  // Notify parent
  await NotificationService.sendNotification({
    title: `Teacher Replied: ${query.title || 'Your inquiry'}`,
    message: replyMessage,
    type: 'GENERAL',
    targetRole: 'SPECIFIC',
    recipientId: query.senderId._id,
    senderId: teacher._id,
  });

  return res.status(201).json(
    new ApiResponse(201, { query, reply }, 'Reply sent and parent notified!')
  );
});

module.exports = {
  sendDirectMessage,
  getConversation,
  sendClassAnnouncement,
  getClassAnnouncements,
  shareStudentProgress,
  scheduleMeeting,
  getMeetings,
  updateMeetingStatus,
  getParentQueriesAndComplaints,
  replyToParentQuery,
};
