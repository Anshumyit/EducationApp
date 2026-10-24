const mongoose = require('mongoose');

const communicationAttachmentSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
  },
  fileUrl: {
    type: String,
    required: true,
  },
  fileType: {
    type: String,
    enum: ['IMAGE', 'PDF', 'DOCUMENT', 'LINK'],
    default: 'DOCUMENT',
  },
});

const communicationMessageSchema = new mongoose.Schema(
  {
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    senderRole: {
      type: String,
      enum: ['TEACHER', 'PARENT', 'ADMIN'],
      required: true,
    },
    recipientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      default: null,
      index: true,
    },
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ClassRoom',
      default: null,
      index: true,
    },
    type: {
      type: String,
      enum: [
        'INDIVIDUAL_MESSAGE',
        'CLASS_ANNOUNCEMENT',
        'PROGRESS_SHARE',
        'PARENT_QUERY',
        'COMPLAINT',
        'MEETING_INVITE',
      ],
      default: 'INDIVIDUAL_MESSAGE',
    },
    title: {
      type: String,
      default: '',
      trim: true,
    },
    message: {
      type: String,
      required: true,
      trim: true,
    },
    attachments: [communicationAttachmentSchema],
    status: {
      type: String,
      enum: ['SENT', 'DELIVERED', 'READ'],
      default: 'SENT',
    },
    deliveredAt: {
      type: Date,
      default: Date.now,
    },
    readAt: {
      type: Date,
      default: null,
    },
    replyTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CommunicationMessage',
      default: null,
    },
    resolutionStatus: {
      type: String,
      enum: ['OPEN', 'IN_REVIEW', 'RESOLVED'],
      default: 'OPEN',
    },
    metaData: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

communicationMessageSchema.index({ classId: 1, type: 1, createdAt: -1 });
communicationMessageSchema.index({ senderId: 1, recipientId: 1, createdAt: -1 });

const CommunicationMessage = mongoose.model('CommunicationMessage', communicationMessageSchema);
module.exports = CommunicationMessage;
