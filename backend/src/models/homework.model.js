const mongoose = require('mongoose');

const homeworkAttachmentSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
  },
  fileUrl: {
    type: String,
    required: true,
    trim: true,
  },
  fileType: {
    type: String,
    enum: ['IMAGE', 'PDF', 'DOCUMENT', 'LINK'],
    default: 'DOCUMENT',
  },
});

const homeworkSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
    },
    subject: {
      type: String,
      required: true,
      trim: true,
    },
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ClassRoom',
      required: true,
      index: true,
    },
    assignedDate: {
      type: Date,
      default: Date.now,
    },
    submissionDate: {
      type: Date,
      required: true,
    },
    maxMarks: {
      type: Number,
      default: 20,
    },
    instructions: {
      type: String,
      default: '',
      trim: true,
    },
    attachments: [homeworkAttachmentSchema],
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

homeworkSchema.index({ classId: 1, submissionDate: -1 });

const Homework = mongoose.model('Homework', homeworkSchema);
module.exports = Homework;
