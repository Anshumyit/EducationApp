const mongoose = require('mongoose');

const classroomSchema = new mongoose.Schema(
  {
    schoolId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'School',
      default: null,
    },
    name: {

      type: String,
      required: true,
      trim: true, // e.g. "Class 10"
    },
    section: {
      type: String,
      required: true,
      trim: true, // e.g. "A"
    },
    roomNumber: {
      type: String,
      default: '',
    },
    capacity: {
      type: Number,
      default: 40,
    },
    classTeacher: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    subjects: [
      {
        name: { type: String, required: true },
        code: { type: String, default: '' },
        teacher: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
      },
    ],
    timetable: [
      {
        day: { type: String, enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'] },
        periods: [
          {
            periodNumber: Number,
            subject: String,
            startTime: String,
            endTime: String,
            teacherName: String,
          },
        ],
      },
    ],
  },
  {
    timestamps: true,
  }
);

classroomSchema.virtual('displayName').get(function () {
  return `${this.name} - ${this.section}`;
});

const ClassRoom = mongoose.model('ClassRoom', classroomSchema);
module.exports = ClassRoom;
