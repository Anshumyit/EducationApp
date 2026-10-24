const mongoose = require('mongoose');

const studyMaterialSchema = new mongoose.Schema({
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
    enum: ['PDF', 'DOCUMENT', 'LINK', 'NOTES', 'IMAGE'],
    default: 'PDF',
  },
});

const dailySyllabusLogSchema = new mongoose.Schema(
  {
    teacherId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ClassRoom',
      required: true,
    },
    subject: {
      type: String,
      required: true,
      trim: true,
    },
    date: {
      type: String,
      required: true, // YYYY-MM-DD
      index: true,
    },
    chapter: {
      type: String,
      required: true,
      trim: true,
    },
    topic: {
      type: String,
      required: true,
      trim: true,
    },
    dailyTarget: {
      type: String,
      required: true,
      trim: true,
    },
    status: {
      type: String,
      enum: ['COMPLETED', 'PARTIALLY_COMPLETED', 'PENDING'],
      default: 'COMPLETED',
    },
    completionPercentage: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    durationMinutes: {
      type: Number,
      default: 45,
    },
    nextClassTarget: {
      type: String,
      default: '',
      trim: true,
    },
    studyMaterials: [studyMaterialSchema],
    notes: {
      type: String,
      default: '',
      trim: true,
    },
    academicSession: {
      type: String,
      default: '2026-2027',
    },
  },
  {
    timestamps: true,
  }
);

dailySyllabusLogSchema.index({ classId: 1, subject: 1, date: -1 });
dailySyllabusLogSchema.index({ teacherId: 1, date: -1 });

const DailySyllabusLog = mongoose.model('DailySyllabusLog', dailySyllabusLogSchema);
module.exports = DailySyllabusLog;
