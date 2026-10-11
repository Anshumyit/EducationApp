const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    message: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: ['ATTENDANCE', 'HOMEWORK', 'RESULT', 'LEAVE', 'FEE', 'BROADCAST', 'GENERAL'],
      default: 'GENERAL',
    },
    // Target audience or specific recipient:
    targetRole: {
      type: String,
      enum: ['ALL', 'TEACHERS', 'PARENTS', 'SPECIFIC'],
      default: 'SPECIFIC',
    },
    recipientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null, // null if targetRole is ALL, TEACHERS, or PARENTS
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ClassRoom',
      default: null,
    },
    metaData: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    isReadBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
  },
  {
    timestamps: true,
  }
);

const Notification = mongoose.model('Notification', notificationSchema);
module.exports = Notification;
