require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/user.model');
const ClassRoom = require('../models/classroom.model');
const Student = require('../models/student.model');
const Attendance = require('../models/attendance.model');
const ExamResult = require('../models/examResult.model');
const Homework = require('../models/homework.model');
const LeaveRequest = require('../models/leaveRequest.model');
const FeeRecord = require('../models/feeRecord.model');
const SalarySlip = require('../models/salarySlip.model');
const Holiday = require('../models/holiday.model');
const Notification = require('../models/notification.model');
const SchoolSetting = require('../models/schoolSetting.model');
const { ROLES } = require('../constants/roles');
const { USER_STATUS, ATTENDANCE_STATUS, EXAM_TYPES, LEAVE_STATUS } = require('../constants/status');

const seed = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/school_management_db');
    console.log('[Seed] Connected to database');

    // Clean existing records
    await Promise.all([
      User.deleteMany({}),
      ClassRoom.deleteMany({}),
      Student.deleteMany({}),
      Attendance.deleteMany({}),
      ExamResult.deleteMany({}),
      Homework.deleteMany({}),
      LeaveRequest.deleteMany({}),
      FeeRecord.deleteMany({}),
      SalarySlip.deleteMany({}),
      Holiday.deleteMany({}),
      Notification.deleteMany({}),
      SchoolSetting.deleteMany({}),
    ]);
    console.log('[Seed] Existing collections cleaned');

    // 1. Create Admin
    const admin = await User.create({
      name: 'Dr. Vivek Saxena (Admin)',
      email: 'admin@school.com',
      phone: '9876543210',
      password: 'Password@123',
      role: ROLES.ADMIN,
      status: USER_STATUS.APPROVED,
      isOtpVerified: true,
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    });

    // 2. Create Classrooms
    const class10A = await ClassRoom.create({
      name: 'Class 10',
      section: 'A',
      roomNumber: 'Room 204',
      capacity: 40,
    });

    const class10B = await ClassRoom.create({
      name: 'Class 10',
      section: 'B',
      roomNumber: 'Room 205',
      capacity: 40,
    });

    // 3. Create Teachers
    // Teacher 1: Approved Class Teacher for 10-A
    const teacherRahul = await User.create({
      name: 'Rahul Sharma',
      email: 'teacher.rahul@school.com',
      phone: '9876543211',
      password: 'Password@123',
      role: ROLES.TEACHER,
      status: USER_STATUS.APPROVED,
      isOtpVerified: true,
      subjects: ['Mathematics', 'Physics'],
      qualification: 'M.Sc. Mathematics, B.Ed.',
      salary: 58000,
      isClassTeacher: true,
      assignedClass: class10A._id,
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
    });

    // Link ClassRoom 10A to Rahul
    class10A.classTeacher = teacherRahul._id;
    await class10A.save();

    // Teacher 2: Approved Subject Teacher
    const teacherPriya = await User.create({
      name: 'Priya Mukherjee',
      email: 'teacher.priya@school.com',
      phone: '9876543212',
      password: 'Password@123',
      role: ROLES.TEACHER,
      status: USER_STATUS.APPROVED,
      isOtpVerified: true,
      subjects: ['English Literature', 'Social Studies'],
      qualification: 'M.A. English, B.Ed.',
      salary: 52000,
      isClassTeacher: false,
      avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=200&q=80',
    });

    // Teacher 3: Pending Teacher (Waiting for Admin approval)
    const teacherAmit = await User.create({
      name: 'Amit Kumar Verma',
      email: 'teacher.amit@school.com',
      phone: '9876543213',
      password: 'Password@123',
      role: ROLES.TEACHER,
      status: USER_STATUS.PENDING,
      isOtpVerified: true,
      subjects: ['Chemistry', 'Biology'],
      qualification: 'M.Sc. Chemistry',
      salary: 50000,
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
    });

    // 4. Create Parents
    // Parent 1: Approved Parent
    const parentRajesh = await User.create({
      name: 'Rajesh Sharma',
      email: 'parent.rajesh@gmail.com',
      phone: '9876543214',
      password: 'Password@123',
      role: ROLES.PARENT,
      status: USER_STATUS.APPROVED,
      isOtpVerified: true,
      address: 'House #42, Green Park Avenue, Delhi',
      avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=200&q=80',
    });

    // Parent 2: Pending Parent (Waiting for Admin approval)
    const parentVikram = await User.create({
      name: 'Vikram Malhotra',
      email: 'parent.vikram@gmail.com',
      phone: '9876543215',
      password: 'Password@123',
      role: ROLES.PARENT,
      status: USER_STATUS.PENDING,
      isOtpVerified: true,
      address: 'Flat 301, Silver Crest Tower, Delhi',
      avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=200&q=80',
    });

    // 5. Create Students for Class 10-A
    const studentAarav = await Student.create({
      name: 'Aarav Sharma',
      rollNumber: 1,
      admissionNumber: 'ADM-2024-001',
      classId: class10A._id,
      parentId: parentRajesh._id,
      dateOfBirth: new Date('2011-04-12'),
      gender: 'MALE',
      bloodGroup: 'B+',
      address: 'House #42, Green Park Avenue, Delhi',
      emergencyContact: '9876543214',
      photo: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=200&q=80',
    });

    const studentAnanya = await Student.create({
      name: 'Ananya Patel',
      rollNumber: 2,
      admissionNumber: 'ADM-2024-002',
      classId: class10A._id,
      parentId: parentRajesh._id, // linked for demo
      dateOfBirth: new Date('2011-08-22'),
      gender: 'FEMALE',
      bloodGroup: 'O+',
      address: '77 Garden City, Delhi',
      emergencyContact: '9876543214',
      photo: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
    });

    const studentRohan = await Student.create({
      name: 'Rohan Gupta',
      rollNumber: 3,
      admissionNumber: 'ADM-2024-003',
      classId: class10A._id,
      parentId: parentRajesh._id,
      dateOfBirth: new Date('2011-01-15'),
      gender: 'MALE',
      bloodGroup: 'A+',
      address: '12 Metro Colony, Delhi',
      emergencyContact: '9876543214',
      photo: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=200&q=80',
    });

    const studentSneha = await Student.create({
      name: 'Sneha Verma',
      rollNumber: 4,
      admissionNumber: 'ADM-2024-004',
      classId: class10A._id,
      parentId: parentRajesh._id,
      dateOfBirth: new Date('2011-11-05'),
      gender: 'FEMALE',
      bloodGroup: 'AB+',
      address: '94 Lotus Boulevard, Delhi',
      emergencyContact: '9876543214',
      photo: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=80',
    });

    // Update parent's children array
    parentRajesh.children = [studentAarav._id, studentAnanya._id];
    await parentRajesh.save();

    // 6. Create Daily Attendance for current date
    const todayStr = new Date().toISOString().split('T')[0];
    await Attendance.create({
      date: todayStr,
      classId: class10A._id,
      markedBy: teacherRahul._id,
      records: [
        { studentId: studentAarav._id, status: ATTENDANCE_STATUS.PRESENT, remarks: 'On time' },
        { studentId: studentAnanya._id, status: ATTENDANCE_STATUS.PRESENT, remarks: 'On time' },
        { studentId: studentRohan._id, status: ATTENDANCE_STATUS.ABSENT, remarks: 'Medical excuse' },
        { studentId: studentSneha._id, status: ATTENDANCE_STATUS.LATE, remarks: 'Bus delayed' },
      ],
    });

    // Past attendance days for monthly reports
    const dates = ['2026-10-01', '2026-10-02', '2026-10-05', '2026-10-06', '2026-10-07', '2026-10-08', '2026-10-09'];
    for (const d of dates) {
      await Attendance.create({
        date: d,
        classId: class10A._id,
        markedBy: teacherRahul._id,
        records: [
          { studentId: studentAarav._id, status: ATTENDANCE_STATUS.PRESENT },
          { studentId: studentAnanya._id, status: ATTENDANCE_STATUS.PRESENT },
          { studentId: studentRohan._id, status: d === '2026-10-05' ? ATTENDANCE_STATUS.ABSENT : ATTENDANCE_STATUS.PRESENT },
          { studentId: studentSneha._id, status: ATTENDANCE_STATUS.PRESENT },
        ],
      });
    }

    // 7. Create Exam Results (Weekly, Monthly, Half-Yearly, Annual)
    // Weekly Test
    await ExamResult.create({
      studentId: studentAarav._id,
      classId: class10A._id,
      examType: EXAM_TYPES.WEEKLY,
      examTitle: 'Weekly Test - Unit 1',
      academicYear: '2026-2027',
      subjects: [
        { subjectName: 'Mathematics', maxMarks: 25, marksObtained: 24, grade: 'A+' },
        { subjectName: 'Physics', maxMarks: 25, marksObtained: 22, grade: 'A' },
        { subjectName: 'English', maxMarks: 25, marksObtained: 23, grade: 'A' },
        { subjectName: 'Social Science', maxMarks: 25, marksObtained: 21, grade: 'B+' },
      ],
      enteredBy: teacherRahul._id,
    });

    // Monthly Exam
    await ExamResult.create({
      studentId: studentAarav._id,
      classId: class10A._id,
      examType: EXAM_TYPES.MONTHLY,
      examTitle: 'September Monthly Assessment',
      academicYear: '2026-2027',
      subjects: [
        { subjectName: 'Mathematics', maxMarks: 100, marksObtained: 94, grade: 'A+' },
        { subjectName: 'Physics', maxMarks: 100, marksObtained: 89, grade: 'A' },
        { subjectName: 'English', maxMarks: 100, marksObtained: 86, grade: 'A' },
        { subjectName: 'Social Science', maxMarks: 100, marksObtained: 91, grade: 'A+' },
      ],
      enteredBy: teacherRahul._id,
    });

    // 6-Months (Half Yearly)
    await ExamResult.create({
      studentId: studentAarav._id,
      classId: class10A._id,
      examType: EXAM_TYPES.HALF_YEARLY,
      examTitle: 'Mid-Term Examination (Half Yearly)',
      academicYear: '2026-2027',
      subjects: [
        { subjectName: 'Mathematics', maxMarks: 100, marksObtained: 95, grade: 'A+' },
        { subjectName: 'Physics', maxMarks: 100, marksObtained: 91, grade: 'A+' },
        { subjectName: 'English', maxMarks: 100, marksObtained: 88, grade: 'A' },
        { subjectName: 'Social Science', maxMarks: 100, marksObtained: 90, grade: 'A+' },
      ],
      enteredBy: teacherRahul._id,
    });

    // 1-Year (Annual)
    await ExamResult.create({
      studentId: studentAarav._id,
      classId: class10A._id,
      examType: EXAM_TYPES.ANNUAL,
      examTitle: 'Annual Board Assessment Final',
      academicYear: '2025-2026',
      subjects: [
        { subjectName: 'Mathematics', maxMarks: 100, marksObtained: 96, grade: 'A+' },
        { subjectName: 'Physics', maxMarks: 100, marksObtained: 94, grade: 'A+' },
        { subjectName: 'English', maxMarks: 100, marksObtained: 90, grade: 'A+' },
        { subjectName: 'Social Science', maxMarks: 100, marksObtained: 92, grade: 'A+' },
      ],
      enteredBy: teacherRahul._id,
    });

    // 8. Create Homework
    await Homework.create({
      title: 'Quadratic Equations Exercise 4.2',
      description: 'Solve questions 1 through 10 from NCERT Textbook Chapter 4. Submit notebook on Monday.',
      subject: 'Mathematics',
      classId: class10A._id,
      assignedDate: new Date(),
      submissionDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days from now
      createdBy: teacherRahul._id,
    });

    await Homework.create({
      title: 'Ray Optics Diagrams and Reflection Laws',
      description: 'Draw ray diagrams for concave and convex mirrors with focal point specifications.',
      subject: 'Physics',
      classId: class10A._id,
      assignedDate: new Date(),
      submissionDate: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      createdBy: teacherRahul._id,
    });

    // 9. Create Leave Request
    await LeaveRequest.create({
      studentId: studentAarav._id,
      parentId: parentRajesh._id,
      classId: class10A._id,
      startDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
      endDate: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000),
      reason: 'Attending cousin’s wedding ceremony in Jaipur with family.',
      status: LEAVE_STATUS.PENDING,
    });

    // 10. Create Fee Records
    await FeeRecord.create({
      studentId: studentAarav._id,
      parentId: parentRajesh._id,
      title: 'Term 1 Tuition & Lab Fees',
      academicYear: '2026-2027',
      totalAmount: 35000,
      paidAmount: 25000,
      dueDate: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
      payments: [
        {
          amount: 25000,
          paymentDate: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
          method: 'UPI',
        },
      ],
    });

    // 11. Create Salary Slip for Teacher Rahul
    await SalarySlip.create({
      teacherId: teacherRahul._id,
      month: 'October',
      year: 2026,
      basicSalary: 45000,
      hra: 9000,
      da: 4000,
      specialAllowance: 4000,
      pfDeduction: 3500,
      taxDeduction: 1500,
      netSalary: 57000,
      paymentStatus: 'PAID',
    });

    // 12. Create Holidays
    await Holiday.create([
      {
        title: 'Diwali Festival Holidays',
        description: 'Deepawali festival celebrations break for students and staff.',
        startDate: new Date('2026-10-28'),
        endDate: new Date('2026-11-03'),
        type: 'FESTIVAL',
      },
      {
        title: 'Guru Nanak Jayanti',
        description: 'National public holiday honoring Guru Nanak Dev Ji.',
        startDate: new Date('2026-11-15'),
        endDate: new Date('2026-11-15'),
        type: 'FESTIVAL',
      },
      {
        title: 'Winter Vacation',
        description: 'Annual winter break for schools.',
        startDate: new Date('2026-12-24'),
        endDate: new Date('2027-01-05'),
        type: 'VACATION',
      },
    ]);

    // 13. Create Initial Broadcast Notifications
    await Notification.create([
      {
        title: 'Welcome to Academic Term 2026-2027 🎓',
        message: 'School management system is live. Teachers, parents, and students can now track progress in real time.',
        type: 'BROADCAST',
        targetRole: 'ALL',
        senderId: admin._id,
      },
      {
        title: 'Parent-Teacher Meeting Scheduled 📅',
        message: 'Term 1 PTM will be conducted on Saturday, Oct 24th from 9:00 AM to 1:00 PM in the school auditorium.',
        type: 'BROADCAST',
        targetRole: 'PARENTS',
        senderId: admin._id,
      },
    ]);

    // 14. Create School Settings (Profile, Bus Fleet, Library Catalog)
    await SchoolSetting.create({
      schoolName: 'St. Xavier International Academy',
      affiliationCode: 'CBSE-DEL-2026-9812',
      address: 'Plot 14, Institutional Area, Sector 62, New Delhi',
      phone: '+91 98765 43210',
      email: 'admin@school.com',
      currentSession: '2026-2027',
      busRoutes: [
        {
          routeName: 'Route 1 - East Campus to Sector 62',
          busNumber: 'DL-01-AB-1234',
          driverName: 'Suraj Pal Singh',
          driverPhone: '+91 98112 34567',
          capacity: 40,
          studentCount: 28,
        },
        {
          routeName: 'Route 2 - South Extension Express',
          busNumber: 'DL-01-CD-5678',
          driverName: 'Manoj Kumar',
          driverPhone: '+91 98223 45678',
          capacity: 35,
          studentCount: 22,
        },
      ],
      libraryBooks: [
        {
          title: 'NCERT Exemplar Mathematics Class 10',
          author: 'NCERT Council',
          isbn: '978-81-7450-843-0',
          category: 'Mathematics',
          totalCopies: 25,
          availableCopies: 18,
        },
        {
          title: 'Concepts of Physics (Vol 1 & 2)',
          author: 'Dr. H.C. Verma',
          isbn: '978-81-7709-187-8',
          category: 'Physics',
          totalCopies: 20,
          availableCopies: 14,
        },
        {
          title: 'A Brief History of Time',
          author: 'Stephen Hawking',
          isbn: '978-05-5338-016-3',
          category: 'Science & Astronomy',
          totalCopies: 10,
          availableCopies: 7,
        },
      ],
    });

    console.log('====================================================');
    console.log('✅ DATABASE SEEDING COMPLETED SUCCESSFULLY!');
    console.log('----------------------------------------------------');
    console.log('🔑 Credentials for instant testing:');
    console.log('  👑 ADMIN:');
    console.log('     Email: admin@school.com (or Phone: 9876543210)');
    console.log('     Password: Password@123');
    console.log('  👨‍🏫 CLASS TEACHER (Approved):');
    console.log('     Email: teacher.rahul@school.com (or Phone: 9876543211)');
    console.log('     Password: Password@123');
    console.log('  ⏳ TEACHER (Pending Approval - for demo):');
    console.log('     Email: teacher.amit@school.com');
    console.log('     Password: Password@123');
    console.log('  👨‍👩‍👧 PARENT (Approved):');
    console.log('     Email: parent.rajesh@gmail.com (or Phone: 9876543214)');
    console.log('     Password: Password@123');
    console.log('  ⏳ PARENT (Pending Approval - for demo):');
    console.log('     Email: parent.vikram@gmail.com');
    console.log('     Password: Password@123');
    console.log('====================================================');

    process.exit(0);
  } catch (error) {
    console.error('Seed Error:', error);
    process.exit(1);
  }
};

seed();
