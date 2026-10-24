const mongoose = require('mongoose');

const meetingScheduleSchema = new mongoose.Schema(
  {
    teacherId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    parentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
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
    title: {
      type: String,
      required: true,
      trim: true,
    },
    agenda: {
      type: String,
      default: '',
      trim: true,
    },
    meetingDate: {
      type: String,
      required: true, // YYYY-MM-DD
    },
    timeSlot: {
      type: String,
      required: true, // e.g. "10:30 AM - 11:00 AM"
    },
    mode: {
      type: String,
      enum: ['IN_PERSON_AT_SCHOOL', 'ONLINE_MEET', 'PHONE_CALL'],
      default: 'IN_PERSON_AT_SCHOOL',
    },
    meetLinkOrRoom: {
      type: String,
      default: 'Classroom',
      trim: true,
    },
    status: {
      type: String,
      enum: ['SCHEDULED', 'CONFIRMED', 'COMPLETED', 'RESCHEDULED', 'CANCELLED'],
      default: 'SCHEDULED',
    },
    teacherNotes: {
      type: String,
      default: '',
      trim: true,
    },
    parentFeedback: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

meetingScheduleSchema.index({ teacherId: 1, meetingDate: 1 });
meetingScheduleSchema.index({ parentId: 1, meetingDate: 1 });

const MeetingSchedule = mongoose.model('MeetingSchedule', meetingScheduleSchema);
module.exports = MeetingSchedule;
