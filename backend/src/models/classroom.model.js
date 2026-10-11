const mongoose = require('mongoose');

const classroomSchema = new mongoose.Schema(
  {
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
