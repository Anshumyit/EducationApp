const mongoose = require('mongoose');

const topicSchema = new mongoose.Schema({
  topicName: {
    type: String,
    required: true,
    trim: true,
  },
  status: {
    type: String,
    enum: ['PENDING', 'COMPLETED'],
    default: 'PENDING',
  },
  completedOn: {
    type: Date,
    default: null,
  },
  completedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
});

const chapterSchema = new mongoose.Schema({
  chapterNumber: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  description: {
    type: String,
    default: '',
    trim: true,
  },
  targetCompletionDate: {
    type: Date,
    required: true,
  },
  totalLecturesEstimated: {
    type: Number,
    default: 5,
  },
  lecturesConducted: {
    type: Number,
    default: 0,
  },
  status: {
    type: String,
    enum: ['NOT_STARTED', 'IN_PROGRESS', 'COMPLETED'],
    default: 'NOT_STARTED',
  },
  completedDate: {
    type: Date,
    default: null,
  },
  topics: [topicSchema],
});

const syllabusPlanSchema = new mongoose.Schema(
  {
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
    academicSession: {
      type: String,
      default: '2026-2027',
    },
    targetTerm: {
      type: String,
      enum: ['Term 1', 'Term 2', 'Annual', 'Mid-Term', 'Final'],
      default: 'Annual',
    },
    assignedTeacher: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    chapters: [chapterSchema],
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Method to calculate overall progress and topic counts
syllabusPlanSchema.methods.calculateProgress = function () {
  let totalTopics = 0;
  let completedTopics = 0;
  let totalChapters = this.chapters.length;
  let completedChapters = 0;

  this.chapters.forEach((ch) => {
    if (ch.status === 'COMPLETED') completedChapters++;
    if (ch.topics && ch.topics.length > 0) {
      totalTopics += ch.topics.length;
      completedTopics += ch.topics.filter((t) => t.status === 'COMPLETED').length;
    } else {
      totalTopics += 1;
      if (ch.status === 'COMPLETED') completedTopics += 1;
    }
  });

  const percentage = totalTopics > 0 ? Math.round((completedTopics / totalTopics) * 100) : 0;

  return {
    percentage,
    totalTopics,
    completedTopics,
    totalChapters,
    completedChapters,
  };
};

const SyllabusPlan = mongoose.model('SyllabusPlan', syllabusPlanSchema);
module.exports = SyllabusPlan;
