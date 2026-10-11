const Notification = require('../models/notification.model');
const { getIO } = require('./socket.service');

class NotificationService {
  /**
   * Dispatch a notification: persists to DB and pushes to Socket.io subscribers
   */
  static async sendNotification({
    title,
    message,
    type = 'GENERAL',
    targetRole = 'SPECIFIC',
    recipientId = null,
    senderId,
    classId = null,
    metaData = {},
  }) {
    try {
      const notification = await Notification.create({
        title,
        message,
        type,
        targetRole,
        recipientId,
        senderId,
        classId,
        metaData,
      });

      const populated = await Notification.findById(notification._id)
        .populate('senderId', 'name role avatar')
        .populate('classId', 'name section');

      const io = getIO();
      if (io) {
        if (targetRole === 'ALL') {
          io.emit('notification:new', populated);
        } else if (targetRole === 'TEACHERS') {
          io.to('role_TEACHER').emit('notification:new', populated);
        } else if (targetRole === 'PARENTS') {
          io.to('role_PARENT').emit('notification:new', populated);
        } else if (recipientId) {
          io.to(`user_${recipientId}`).emit('notification:new', populated);
        }

        if (classId) {
          io.to(`class_${classId}`).emit('notification:new', populated);
        }
      }

      return populated;
    } catch (error) {
      console.error('[NotificationService Error]', error.message);
      return null;
    }
  }
}

module.exports = NotificationService;
