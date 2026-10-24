const mongoose = require('mongoose');

const submissionAttachmentSchema = new mongoose.Schema({
  title: {
    type: String,
    default: 'Document',
  },
  fileUrl: {
    type: String,
    required: true,
  },
  fileType: {
    type: String,
    enum: ['IMAGE', 'PDF', 'DOCUMENT', 'LINK'],
    default: 'IMAGE',
  },
});

const homeworkSubmissionSchema = new mongoose.Schema(
  {
    homeworkId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Homework',
      required: true,
      index: true,
    },
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: true,
      index: true,
    },
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ClassRoom',
      required: true,
    },
    submissionText: {
      type: String,
      default: '',
    },
    attachments: [submissionAttachmentSchema],
    submittedAt: {
      type: Date,
      default: Date.now,
    },
    isLate: {
      type: Boolean,
      default: false,
    },
    status: {
      type: String,
      enum: ['SUBMITTED', 'GRADED', 'RESUBMISSION_REQUESTED', 'PENDING'],
      default: 'SUBMITTED',
    },
    marksObtained: {
      type: Number,
      default: null,
    },
    maxMarks: {
      type: Number,
      default: 20,
    },
    feedback: {
      type: String,
      default: '',
    },
    gradedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    gradedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

homeworkSubmissionSchema.index({ homeworkId: 1, studentId: 1 }, { unique: true });

const HomeworkSubmission = mongoose.model('HomeworkSubmission', homeworkSubmissionSchema);
module.exports = HomeworkSubmission;
