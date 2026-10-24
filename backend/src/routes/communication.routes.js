const express = require('express');
const router = express.Router();
const {
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
} = require('../controllers/communication.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

router.use(verifyJWT);

// 1. Direct Messages & Chat
router.post('/messages', sendDirectMessage);
router.get('/messages/:otherUserId', getConversation);

// 2. Class Announcements
router.post('/announcements', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), sendClassAnnouncement);
router.get('/announcements/class/:classId', getClassAnnouncements);

// 3. Share Student Progress Card
router.post('/progress/share', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), shareStudentProgress);

// 4. PTM & Meetings
router.post('/meetings', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), scheduleMeeting);
router.get('/meetings', getMeetings);
router.patch('/meetings/:meetingId', updateMeetingStatus);

// 5. Parent Questions & Complaints
router.get('/queries', getParentQueriesAndComplaints);
router.post('/queries/:queryId/reply', authorizeRoles(ROLES.TEACHER, ROLES.ADMIN), replyToParentQuery);

module.exports = router;
