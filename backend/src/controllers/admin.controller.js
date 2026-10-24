const User = require('../models/user.model');
const Student = require('../models/student.model');
const ClassRoom = require('../models/classroom.model');
const SalarySlip = require('../models/salarySlip.model');
const Attendance = require('../models/attendance.model');
const FeeRecord = require('../models/feeRecord.model');
const ExamResult = require('../models/examResult.model');
const SchoolSetting = require('../models/schoolSetting.model');
const Notification = require('../models/notification.model');
const NotificationService = require('../services/notification.service');
const { ROLES } = require('../constants/roles');
const { USER_STATUS, ATTENDANCE_STATUS, FEE_STATUS } = require('../constants/status');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * 1. Admin Dashboard Statistics & Real-time Institutional Pulse
 */
const getDashboardStats = asyncHandler(async (req, res) => {
  const todayStr = new Date().toISOString().split('T')[0];

  const [
    totalTeachers,
    totalStudents,
    totalParents,
    totalSections,
    classesList,
    pendingTeachers,
    pendingParents,
    todayAttendanceRecords,
    feeAggregation,
    recentNotifications,
  ] = await Promise.all([
    User.countDocuments({ role: ROLES.TEACHER, status: USER_STATUS.APPROVED }),
    Student.countDocuments({ status: { $ne: 'INACTIVE' } }),
    User.countDocuments({ role: ROLES.PARENT, status: USER_STATUS.APPROVED }),
    ClassRoom.countDocuments(),
    ClassRoom.distinct('name'),
    User.countDocuments({ role: ROLES.TEACHER, status: USER_STATUS.PENDING }),
    User.countDocuments({ role: ROLES.PARENT, status: USER_STATUS.PENDING }),
    Attendance.find({ date: todayStr }),
    FeeRecord.aggregate([
      {
        $group: {
          _id: null,
          totalBilled: { $sum: '$totalAmount' },
          totalPaid: { $sum: '$paidAmount' },
        },
      },
    ]),
    Notification.find().sort({ createdAt: -1 }).limit(6).populate('senderId', 'name role avatar'),
  ]);

  // Compute today's attendance stats
  let presentCount = 0;
  let absentCount = 0;
  let lateCount = 0;

  todayAttendanceRecords.forEach((att) => {
    (att.records || []).forEach((rec) => {
      if (rec.status === ATTENDANCE_STATUS.PRESENT) presentCount++;
      else if (rec.status === ATTENDANCE_STATUS.ABSENT) absentCount++;
      else if (rec.status === ATTENDANCE_STATUS.LATE) lateCount++;
    });
  });

  const markedAttendanceTotal = presentCount + absentCount + lateCount;
  const attendancePercentage =
    totalStudents > 0
      ? parseFloat(((presentCount / totalStudents) * 100).toFixed(1))
      : 0;

  const totalFeeBilled = feeAggregation[0]?.totalBilled || 0;
  const totalFeeCollected = feeAggregation[0]?.totalPaid || 0;
  const totalFeePending = Math.max(0, totalFeeBilled - totalFeeCollected);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalTeachers,
        totalStudents,
        totalParents,
        totalClasses: classesList.length,
        totalSections,
        todayAttendance: {
          totalEnrolled: totalStudents,
          markedCount: markedAttendanceTotal,
          presentCount,
          absentCount,
          lateCount,
          percentage: attendancePercentage,
        },
        fees: {
          totalBilled: totalFeeBilled,
          totalCollected: totalFeeCollected,
          totalPending: totalFeePending,
        },
        pendingApprovals: {
          teachers: pendingTeachers,
          parents: pendingParents,
          total: pendingTeachers + pendingParents,
        },
        recentActivities: recentNotifications,
      },
      'Dashboard analytics and institutional pulse retrieved successfully'
    )
  );
});

/**
 * 2. Student Management: Get all students with filter & search
 */
const getAllStudents = asyncHandler(async (req, res) => {
  const { classId, search, status } = req.query;
  const filter = {};

  if (classId) filter.classId = classId;
  if (status) filter.status = status;
  if (search) {
    filter.$or = [
      { name: { $regex: search, $options: 'i' } },
      { admissionNumber: { $regex: search, $options: 'i' } },
      { emergencyContact: { $regex: search, $options: 'i' } },
    ];
  }

  const students = await Student.find(filter)
    .populate('classId', 'name section roomNumber')
    .populate('parentId', 'name email phone address')
    .sort({ rollNumber: 1, name: 1 });

  return res.status(200).json(new ApiResponse(200, students, 'Students retrieved successfully'));
});

/**
 * Student Management: Get single student by ID
 */
const getStudentById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const student = await Student.findById(id)
    .populate('classId', 'name section roomNumber classTeacher')
    .populate('parentId', 'name email phone address avatar');

  if (!student) throw new ApiError(404, 'Student not found');
  return res.status(200).json(new ApiResponse(200, student, 'Student details retrieved'));
});

/**
 * Student Management: Create new student
 */
const createStudent = asyncHandler(async (req, res) => {
  const {
    name,
    rollNumber,
    admissionNumber,
    classId,
    parentId,
    dateOfBirth,
    gender,
    bloodGroup,
    address,
    emergencyContact,
    photo,
  } = req.body;

  if (!name || !classId || !parentId || !address || !emergencyContact) {
    throw new ApiError(400, 'Name, Class, Parent, Address, and Emergency Contact are required');
  }

  // Validate ClassRoom & Parent exist
  const classroom = await ClassRoom.findById(classId);
  if (!classroom) throw new ApiError(404, 'Classroom not found');

  const parent = await User.findOne({ _id: parentId, role: ROLES.PARENT });
  if (!parent) throw new ApiError(404, 'Parent account not found');

  const generatedAdm =
    admissionNumber || `ADM-${new Date().getFullYear()}-${Math.floor(1000 + Math.random() * 9000)}`;

  // Find next roll number if not provided
  let calculatedRoll = rollNumber;
  if (!calculatedRoll) {
    const lastStudent = await Student.findOne({ classId }).sort({ rollNumber: -1 });
    calculatedRoll = lastStudent ? lastStudent.rollNumber + 1 : 1;
  }

  const student = await Student.create({
    name,
    rollNumber: Number(calculatedRoll),
    admissionNumber: generatedAdm,
    classId,
    parentId,
    dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
    gender: gender || 'MALE',
    bloodGroup: bloodGroup || 'O+',
    address,
    emergencyContact,
    photo:
      photo ||
      'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=150&q=80',
    status: 'ACTIVE',
  });

  // Notify parent
  await NotificationService.sendNotification({
    title: 'New Student Enrollment 🎒',
    message: `Your child ${name} has been enrolled in ${classroom.name} - ${classroom.section} (Roll #${calculatedRoll}, Admission #${generatedAdm}).`,
    type: 'GENERAL',
    targetRole: 'SPECIFIC',
    recipientId: parent._id,
    senderId: req.user._id,
  });

  return res.status(201).json(new ApiResponse(201, student, 'Student enrolled successfully'));
});

/**
 * Student Management: Update student record
 */
const updateStudent = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const updates = req.body;

  const student = await Student.findByIdAndUpdate(id, updates, { new: true })
    .populate('classId')
    .populate('parentId');

  if (!student) throw new ApiError(404, 'Student not found');
  return res.status(200).json(new ApiResponse(200, student, 'Student record updated'));
});

/**
 * Student Management: Delete student record
 */
const deleteStudent = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const student = await Student.findByIdAndDelete(id);
  if (!student) throw new ApiError(404, 'Student not found');
  return res.status(200).json(new ApiResponse(200, null, 'Student record deleted successfully'));
});

/**
 * Student Management: Transfer Certificate (TC) & Status update
 */
const updateStudentStatus = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status, tcReason, tcNumber } = req.body;

  const student = await Student.findById(id).populate('parentId');
  if (!student) throw new ApiError(404, 'Student not found');

  student.status = status;
  if (status === 'TC_ISSUED') {
    student.tcNumber = tcNumber || `TC-${Date.now().toString().slice(-6)}`;
    student.tcIssueDate = new Date();
    student.tcReason = tcReason || 'Parent relocation / course completion';

    if (student.parentId) {
      await NotificationService.sendNotification({
        title: 'Transfer Certificate Issued 📜',
        message: `Transfer Certificate #${student.tcNumber} has been officially issued for ${student.name}.`,
        type: 'GENERAL',
        targetRole: 'SPECIFIC',
        recipientId: student.parentId._id,
        senderId: req.user._id,
      });
    }
  }

  await student.save();
  return res.status(200).json(new ApiResponse(200, student, `Student status updated to ${status}`));
});

/**
 * Student Management: Promote student(s) to next class
 */
const promoteStudents = asyncHandler(async (req, res) => {
  const { studentIds, targetClassId, newAcademicSession } = req.body;

  if (!studentIds || !Array.isArray(studentIds) || studentIds.length === 0 || !targetClassId) {
    throw new ApiError(400, 'Student IDs array and targetClassId are required');
  }

  const targetClass = await ClassRoom.findById(targetClassId);
  if (!targetClass) throw new ApiError(404, 'Target class not found');

  await Student.updateMany(
    { _id: { $in: studentIds } },
    {
      $set: {
        classId: targetClassId,
        academicSession: newAcademicSession || '2026-2027',
        status: 'ACTIVE',
      },
    }
  );

  return res.status(200).json(
    new ApiResponse(
      200,
      { count: studentIds.length, targetClass: targetClass.displayName || targetClass.name },
      `${studentIds.length} student(s) promoted successfully to ${targetClass.name} - ${targetClass.section}`
    )
  );
});

/**
 * 3. Teacher & Staff Management: Get teachers list
 */
const getTeachersList = asyncHandler(async (req, res) => {
  const teachers = await User.find({ role: ROLES.TEACHER })
    .populate('assignedClass')
    .sort({ createdAt: -1 });

  return res.status(200).json(
    new ApiResponse(200, teachers, 'Teachers list retrieved successfully')
  );
});

/**
 * Teacher & Staff Management: Create teacher directly by Admin
 */
const createTeacher = asyncHandler(async (req, res) => {
  const { name, email, phone, password, subjects, qualification, salary } = req.body;

  if (!name || !email || !phone) {
    throw new ApiError(400, 'Name, Email, and Phone are required');
  }

  const existing = await User.findOne({ $or: [{ email }, { phone }] });
  if (existing) {
    throw new ApiError(409, 'A user with this email or phone already exists');
  }

  const teacher = await User.create({
    name,
    email,
    phone,
    password: password || 'Password@123',
    role: ROLES.TEACHER,
    status: USER_STATUS.APPROVED,
    isOtpVerified: true,
    subjects: Array.isArray(subjects) ? subjects : subjects ? subjects.split(',').map((s) => s.trim()) : [],
    qualification: qualification || 'B.Ed, Graduate',
    salary: salary ? Number(salary) : 45000,
    avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=200&q=80',
  });

  return res.status(201).json(new ApiResponse(201, teacher, 'Faculty member added successfully'));
});

/**
 * Teacher & Staff Management: Update teacher details
 */
const updateTeacher = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const updates = req.body;

  if (updates.subjects && typeof updates.subjects === 'string') {
    updates.subjects = updates.subjects.split(',').map((s) => s.trim());
  }

  const teacher = await User.findByIdAndUpdate(id, updates, { new: true }).populate('assignedClass');
  if (!teacher) throw new ApiError(404, 'Teacher not found');

  return res.status(200).json(new ApiResponse(200, teacher, 'Teacher details updated'));
});

/**
 * Teacher & Staff Management: Delete teacher
 */
const deleteTeacher = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const teacher = await User.findByIdAndDelete(id);
  if (!teacher) throw new ApiError(404, 'Teacher not found');
  return res.status(200).json(new ApiResponse(200, null, 'Teacher record removed'));
});

/**
 * Approvals Hub: Get pending users
 */
const getPendingApprovals = asyncHandler(async (req, res) => {
  const { role } = req.query;
  const filter = { status: USER_STATUS.PENDING };
  if (role) filter.role = role;

  const pendingUsers = await User.find(filter).sort({ createdAt: -1 });
  return res.status(200).json(
    new ApiResponse(200, pendingUsers, 'Pending approval users retrieved')
  );
});

/**
 * Approvals Hub: Approve or reject teacher / parent
 */
const updateApprovalStatus = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const { status, remarks } = req.body;

  if (![USER_STATUS.APPROVED, USER_STATUS.REJECTED].includes(status)) {
    throw new ApiError(400, 'Invalid status. Must be APPROVED or REJECTED');
  }

  const user = await User.findById(userId);
  if (!user) throw new ApiError(404, 'User not found');

  user.status = status;
  await user.save();

  await NotificationService.sendNotification({
    title: status === USER_STATUS.APPROVED ? 'Account Approved 🎉' : 'Registration Status Update',
    message:
      status === USER_STATUS.APPROVED
        ? `Congratulations ${user.name}! Your ${user.role.toLowerCase()} account has been approved by the School Admin. You can now log in.`
        : `Your account application was reviewed: ${remarks || 'Rejected by Admin'}.`,
    type: 'BROADCAST',
    targetRole: 'SPECIFIC',
    recipientId: user._id,
    senderId: req.user._id,
  });

  return res.status(200).json(
    new ApiResponse(200, user, `User account ${status.toLowerCase()} successfully`)
  );
});

/**
 * 4. Class, Section & Subject Management: Create Classroom
 */
const createClassRoom = asyncHandler(async (req, res) => {
  const { name, section, roomNumber, capacity, classTeacherId, subjects } = req.body;

  if (!name || !section) {
    throw new ApiError(400, 'Class name and section are required');
  }

  const existing = await ClassRoom.findOne({ name, section });
  if (existing) {
    throw new ApiError(409, `Class ${name} ${section} already exists`);
  }

  const classroom = await ClassRoom.create({
    name,
    section,
    roomNumber: roomNumber || '',
    capacity: capacity || 40,
    classTeacher: classTeacherId || null,
    subjects: subjects || [
      { name: 'Mathematics', code: 'MATH-101' },
      { name: 'English', code: 'ENG-101' },
      { name: 'Science', code: 'SCI-101' },
      { name: 'Social Studies', code: 'SST-101' },
      { name: 'Hindi', code: 'HIN-101' },
    ],
  });

  if (classTeacherId) {
    await User.findByIdAndUpdate(classTeacherId, {
      isClassTeacher: true,
      assignedClass: classroom._id,
    });
  }

  return res.status(201).json(
    new ApiResponse(201, classroom, 'Classroom created successfully')
  );
});

/**
 * Class, Section & Subject Management: Get all classes with student counts
 */
const getAllClasses = asyncHandler(async (req, res) => {
  const classes = await ClassRoom.find()
    .populate('classTeacher', 'name email phone subjects')
    .populate('subjects.teacher', 'name email phone');

  // Attach student count to each classroom
  const classesWithCounts = await Promise.all(
    classes.map(async (c) => {
      const studentCount = await Student.countDocuments({ classId: c._id, status: 'ACTIVE' });
      const obj = c.toObject();
      obj.studentCount = studentCount;
      return obj;
    })
  );

  return res.status(200).json(new ApiResponse(200, classesWithCounts, 'Classes retrieved'));
});

/**
 * Class, Section & Subject Management: Update Classroom (Subjects, Room, etc.)
 */
const updateClassRoom = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const updates = req.body;

  const classroom = await ClassRoom.findByIdAndUpdate(id, updates, { new: true })
    .populate('classTeacher', 'name email phone')
    .populate('subjects.teacher', 'name email phone');

  if (!classroom) throw new ApiError(404, 'Classroom not found');
  return res.status(200).json(new ApiResponse(200, classroom, 'Classroom updated successfully'));
});

/**
 * Class, Section & Subject Management: Delete Classroom
 */
const deleteClassRoom = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const studentCount = await Student.countDocuments({ classId: id });
  if (studentCount > 0) {
    throw new ApiError(400, `Cannot delete class with ${studentCount} enrolled students. Transfer students first.`);
  }

  await ClassRoom.findByIdAndDelete(id);
  return res.status(200).json(new ApiResponse(200, null, 'Classroom deleted'));
});

/**
 * Assign Teacher as Class Teacher to ClassRoom
 */
const assignClassTeacher = asyncHandler(async (req, res) => {
  const { classId, teacherId } = req.body;

  const classroom = await ClassRoom.findById(classId);
  if (!classroom) throw new ApiError(404, 'Classroom not found');

  const teacher = await User.findOne({ _id: teacherId, role: ROLES.TEACHER });
  if (!teacher) throw new ApiError(404, 'Teacher not found');

  if (classroom.classTeacher) {
    await User.findByIdAndUpdate(classroom.classTeacher, {
      isClassTeacher: false,
      assignedClass: null,
    });
  }

  classroom.classTeacher = teacher._id;
  await classroom.save();

  teacher.isClassTeacher = true;
  teacher.assignedClass = classroom._id;
  await teacher.save();

  return res.status(200).json(
    new ApiResponse(200, { classroom, teacher }, 'Class teacher assigned successfully')
  );
});

/**
 * 5. Fees & Payments Management: Overview Analytics
 */
const getFeesOverview = asyncHandler(async (req, res) => {
  const records = await FeeRecord.find().populate('studentId', 'name admissionNumber').sort({ createdAt: -1 });

  let totalBilled = 0;
  let totalCollected = 0;
  let paidCount = 0;
  let pendingCount = 0;
  let overdueCount = 0;

  const categoryBreakdown = {
    TUITION: 0,
    ADMISSION: 0,
    TRANSPORT: 0,
    EXAM: 0,
    ANNUAL: 0,
    OTHER: 0,
  };

  const now = new Date();

  records.forEach((r) => {
    totalBilled += r.totalAmount || 0;
    totalCollected += r.paidAmount || 0;

    const cat = r.feeCategory || 'TUITION';
    categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + (r.paidAmount || 0);

    if (r.paidAmount >= r.totalAmount) {
      paidCount++;
    } else if (now > new Date(r.dueDate)) {
      overdueCount++;
    } else {
      pendingCount++;
    }
  });

  const totalPending = Math.max(0, totalBilled - totalCollected);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalBilled,
        totalCollected,
        totalPending,
        paidCount,
        pendingCount,
        overdueCount,
        categoryBreakdown,
        recentInvoices: records.slice(0, 10),
      },
      'Fee analytics retrieved successfully'
    )
  );
});

/**
 * Fees & Payments: Get all fee records with search & filters
 */
const getAllFeeRecords = asyncHandler(async (req, res) => {
  const { status, classId, search } = req.query;
  const filter = {};

  if (status) filter.status = status;

  let records = await FeeRecord.find(filter)
    .populate({
      path: 'studentId',
      select: 'name rollNumber admissionNumber classId',
      populate: { path: 'classId', select: 'name section' },
    })
    .populate('parentId', 'name email phone')
    .sort({ createdAt: -1 });

  if (classId) {
    records = records.filter(
      (r) => r.studentId && r.studentId.classId && r.studentId.classId._id.toString() === classId
    );
  }

  if (search) {
    const s = search.toLowerCase();
    records = records.filter(
      (r) =>
        (r.title && r.title.toLowerCase().includes(s)) ||
        (r.studentId && r.studentId.name.toLowerCase().includes(s)) ||
        (r.studentId && r.studentId.admissionNumber.toLowerCase().includes(s))
    );
  }

  return res.status(200).json(new ApiResponse(200, records, 'Fee records retrieved'));
});

/**
 * Fees & Payments: Bulk generate fee invoices for an entire class or student
 */
const generateFeeInvoices = asyncHandler(async (req, res) => {
  const { classId, studentId, title, feeCategory, totalAmount, dueDate, academicYear } = req.body;

  if (!title || !totalAmount || !dueDate) {
    throw new ApiError(400, 'Title, Total Amount, and Due Date are required');
  }

  let students = [];
  if (studentId) {
    const s = await Student.findById(studentId);
    if (!s) throw new ApiError(404, 'Student not found');
    students = [s];
  } else if (classId) {
    students = await Student.find({ classId, status: 'ACTIVE' });
    if (students.length === 0) {
      throw new ApiError(400, 'No active students found in the selected class');
    }
  } else {
    throw new ApiError(400, 'Specify either classId or studentId');
  }

  const createdRecords = [];
  for (const student of students) {
    const fee = await FeeRecord.create({
      studentId: student._id,
      parentId: student.parentId,
      title,
      feeCategory: feeCategory || 'TUITION',
      totalAmount: Number(totalAmount),
      dueDate: new Date(dueDate),
      academicYear: academicYear || '2026-2027',
    });
    createdRecords.push(fee);

    // Send fee invoice notice to parent
    if (student.parentId) {
      await NotificationService.sendNotification({
        title: `New Fee Invoice: ${title} 💳`,
        message: `An invoice of ₹${Number(totalAmount).toLocaleString()} for ${student.name} is due on ${new Date(dueDate).toLocaleDateString()}.`,
        type: 'FEE',
        targetRole: 'SPECIFIC',
        recipientId: student.parentId,
        senderId: req.user._id,
      });
    }
  }

  return res.status(201).json(
    new ApiResponse(
      201,
      { count: createdRecords.length },
      `Generated ${createdRecords.length} fee invoice(s) successfully`
    )
  );
});

/**
 * Fees & Payments: Record payment / offline fee collection
 */
const recordFeePayment = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { amount, method = 'UPI', remarks } = req.body;

  const record = await FeeRecord.findById(id).populate('studentId').populate('parentId');
  if (!record) throw new ApiError(404, 'Fee record not found');

  const payAmt = Number(amount);
  if (!payAmt || payAmt <= 0) throw new ApiError(400, 'Valid payment amount required');

  record.paidAmount += payAmt;
  const receiptNum = `REC-${Date.now().toString().slice(-6)}`;
  record.payments.push({
    amount: payAmt,
    paymentDate: new Date(),
    method,
    receiptNumber: receiptNum,
  });

  await record.save();

  if (record.parentId) {
    await NotificationService.sendNotification({
      title: 'Payment Receipt Issued 🧾',
      message: `Payment of ₹${payAmt.toLocaleString()} received for ${record.studentId?.name} (${record.title}). Receipt: ${receiptNum}.`,
      type: 'FEE',
      targetRole: 'SPECIFIC',
      recipientId: record.parentId._id,
      senderId: req.user._id,
    });
  }

  return res.status(200).json(
    new ApiResponse(200, record, `Payment of ₹${payAmt} recorded successfully. Receipt #${receiptNum}`)
  );
});

/**
 * 6. Attendance Management: Institution-wide Daily Overview & Class-by-Class Breakdown
 */
const getAdminAttendanceOverview = asyncHandler(async (req, res) => {
  const { date } = req.query;
  const targetDateStr = date
    ? (typeof date === 'string' && date.includes('T') ? date.split('T')[0] : date)
    : new Date().toISOString().split('T')[0];

  const [classes, totalStudents, attendanceSessions] = await Promise.all([
    ClassRoom.find().populate('classTeacher', 'name phone'),
    Student.find({ status: 'ACTIVE' }).populate('classId').populate('parentId', 'name phone'),
    Attendance.find({ date: targetDateStr })
      .populate('records.studentId', 'name rollNumber admissionNumber')
      .populate('classId', 'name section'),
  ]);

  let institutionPresent = 0;
  let institutionAbsent = 0;
  let institutionLate = 0;
  let totalMarked = 0;

  attendanceSessions.forEach((session) => {
    (session.records || []).forEach((rec) => {
      totalMarked++;
      if (rec.status === ATTENDANCE_STATUS.PRESENT) institutionPresent++;
      else if (rec.status === ATTENDANCE_STATUS.ABSENT) institutionAbsent++;
      else if (rec.status === ATTENDANCE_STATUS.LATE) institutionLate++;
    });
  });

  // Class by class statistics
  const classBreakdown = classes.map((cls) => {
    const classStudents = totalStudents.filter(
      (s) => s.classId && s.classId._id.toString() === cls._id.toString()
    );
    const session = attendanceSessions.find(
      (l) => l.classId && l.classId._id.toString() === cls._id.toString()
    );

    let p = 0;
    let a = 0;
    let l = 0;
    if (session && session.records) {
      session.records.forEach((rec) => {
        if (rec.status === ATTENDANCE_STATUS.PRESENT) p++;
        else if (rec.status === ATTENDANCE_STATUS.ABSENT) a++;
        else if (rec.status === ATTENDANCE_STATUS.LATE) l++;
      });
    }

    return {
      classId: cls._id,
      className: `${cls.name} - ${cls.section}`,
      classTeacher: cls.classTeacher?.name || 'Unassigned',
      totalStudents: classStudents.length,
      marked: session?.records?.length || 0,
      present: p,
      absent: a,
      late: l,
      percentage: classStudents.length > 0 ? parseFloat(((p / classStudents.length) * 100).toFixed(1)) : 0,
    };
  });

  // Absent students list for targeted notifications
  const absentStudents = [];
  attendanceSessions.forEach((session) => {
    (session.records || []).forEach((rec) => {
      if (rec.status === ATTENDANCE_STATUS.ABSENT && rec.studentId) {
        const fullStudent = totalStudents.find(
          (s) => s._id.toString() === rec.studentId._id.toString()
        );
        absentStudents.push({
          attendanceSessionId: session._id,
          studentId: rec.studentId._id,
          studentName: rec.studentId.name,
          rollNumber: rec.studentId.rollNumber,
          admissionNumber: rec.studentId.admissionNumber,
          className: `${session.classId?.name} - ${session.classId?.section}`,
          parentName: fullStudent?.parentId?.name || 'Guardian',
          parentPhone: fullStudent?.parentId?.phone || fullStudent?.emergencyContact,
          parentId: fullStudent?.parentId?._id,
        });
      }
    });
  });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        date: targetDateStr,
        totalEnrolled: totalStudents.length,
        totalMarked,
        presentCount: institutionPresent,
        absentCount: institutionAbsent,
        lateCount: institutionLate,
        attendancePercentage:
          totalStudents.length > 0
            ? parseFloat(((institutionPresent / totalStudents.length) * 100).toFixed(1))
            : 0,
        classBreakdown,
        absentStudents,
      },
      'Institutional daily attendance overview retrieved'
    )
  );
});

/**
 * Attendance Management: Notify parents of all absent students today
 */
const notifyAbsentParents = asyncHandler(async (req, res) => {
  const { date } = req.body;
  const targetDateStr = date
    ? (typeof date === 'string' && date.includes('T') ? date.split('T')[0] : date)
    : new Date().toISOString().split('T')[0];

  const attendanceSessions = await Attendance.find({ date: targetDateStr });

  let notifiedCount = 0;
  for (const session of attendanceSessions) {
    for (const rec of (session.records || [])) {
      if (rec.status === ATTENDANCE_STATUS.ABSENT && rec.studentId) {
        const student = await Student.findById(rec.studentId).populate('parentId');
        if (student && student.parentId) {
          await NotificationService.sendNotification({
            title: 'Attendance Alert 🚨 (Student Absent)',
            message: `Dear Parent, ${student.name} was marked ABSENT today (${targetDateStr}). Please contact the school office if this is in error.`,
            type: 'ATTENDANCE',
            targetRole: 'SPECIFIC',
            recipientId: student.parentId._id,
            senderId: req.user._id,
          });
          notifiedCount++;
        }
      }
    }
  }

  return res.status(200).json(
    new ApiResponse(
      200,
      { notifiedCount },
      `Dispatched absence notifications to ${notifiedCount} guardian(s)`
    )
  );
});

/**
 * 7. Examination & Results Management: Exams Overview & Publishing
 */
const getAdminExamsOverview = asyncHandler(async (req, res) => {
  const examResults = await ExamResult.find()
    .populate('studentId', 'name rollNumber admissionNumber')
    .populate('classId', 'name section')
    .populate('enteredBy', 'name');

  // Group by Exam Title / Type
  const examMap = {};
  examResults.forEach((r) => {
    const key = `${r.examTitle} - ${r.examType}`;
    if (!examMap[key]) {
      examMap[key] = {
        title: r.examTitle,
        type: r.examType,
        totalEntries: 0,
        classes: new Set(),
        averagePercentage: 0,
        totalPctSum: 0,
        isPublished: r.isPublished,
        topPerformers: [],
      };
    }
    examMap[key].totalEntries++;
    if (r.classId) examMap[key].classes.add(`${r.classId.name}-${r.classId.section}`);
    examMap[key].totalPctSum += r.percentage || 0;
    if (r.isPublished) examMap[key].isPublished = true;
  });

  const examsSummary = Object.values(examMap).map((e) => ({
    title: e.title,
    type: e.type,
    totalEntries: e.totalEntries,
    classesCount: e.classes.size,
    averagePercentage:
      e.totalEntries > 0 ? parseFloat((e.totalPctSum / e.totalEntries).toFixed(1)) : 0,
    isPublished: e.isPublished,
  }));

  // Top school rankers
  const topRankers = examResults
    .filter((r) => r.percentage >= 85)
    .sort((a, b) => b.percentage - a.percentage)
    .slice(0, 10)
    .map((r) => ({
      studentName: r.studentId?.name || 'Student',
      rollNumber: r.studentId?.rollNumber,
      className: `${r.classId?.name} - ${r.classId?.section}`,
      examTitle: r.examTitle,
      percentage: r.percentage,
      overallGrade: r.overallGrade,
    }));

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalRecords: examResults.length,
        exams: examsSummary,
        topRankers,
        results: examResults.slice(0, 20),
      },
      'Exams and performance metrics retrieved successfully'
    )
  );
});

/**
 * Examination & Results Management: Publish results and notify parents
 */
const publishExamResults = asyncHandler(async (req, res) => {
  const { examTitle, examType, classId } = req.body;

  const filter = {};
  if (examTitle) filter.examTitle = examTitle;
  if (examType) filter.examType = examType;
  if (classId) filter.classId = classId;

  const results = await ExamResult.find(filter).populate('studentId', 'name parentId');
  if (results.length === 0) {
    throw new ApiError(404, 'No matching exam results found to publish');
  }

  await ExamResult.updateMany(filter, { $set: { isPublished: true } });

  // Broadcast notification to parents
  await NotificationService.sendNotification({
    title: 'Report Cards Released 🏆',
    message: `Academic results for ${examTitle || examType || 'recent examinations'} have been officially verified and published. Check report card in portal.`,
    type: 'EXAM',
    targetRole: 'PARENTS',
    senderId: req.user._id,
  });

  return res.status(200).json(
    new ApiResponse(
      200,
      { count: results.length },
      `Successfully verified and published ${results.length} exam report card(s)`
    )
  );
});

/**
 * 8. Broadcast Notice to All / Teachers / Parents
 */
const broadcastNotice = asyncHandler(async (req, res) => {
  const { title, message, targetRole } = req.body;

  if (!title || !message) {
    throw new ApiError(400, 'Title and message are required');
  }

  const notification = await NotificationService.sendNotification({
    title,
    message,
    type: 'BROADCAST',
    targetRole: targetRole || 'ALL',
    senderId: req.user._id,
  });

  return res.status(201).json(
    new ApiResponse(201, notification, 'Institutional broadcast notice dispatched successfully')
  );
});

/**
 * 9. Payroll: Generate salary slip
 */
const generateSalarySlip = asyncHandler(async (req, res) => {
  const {
    teacherId,
    month,
    year,
    basicSalary,
    hra = 0,
    da = 0,
    specialAllowance = 0,
    pfDeduction = 0,
    taxDeduction = 0,
  } = req.body;

  if (!teacherId || !month || !year || !basicSalary) {
    throw new ApiError(400, 'Teacher ID, month, year, and basic salary are required');
  }

  const teacher = await User.findOne({ _id: teacherId, role: ROLES.TEACHER });
  if (!teacher) throw new ApiError(404, 'Teacher not found');

  const grossSalary = Number(basicSalary) + Number(hra) + Number(da) + Number(specialAllowance);
  const totalDeductions = Number(pfDeduction) + Number(taxDeduction);
  const netSalary = grossSalary - totalDeductions;

  const slip = await SalarySlip.create({
    teacherId,
    month,
    year,
    basicSalary,
    hra,
    da,
    specialAllowance,
    pfDeduction,
    taxDeduction,
    netSalary,
    paymentStatus: 'PAID',
    paymentDate: new Date(),
  });

  await NotificationService.sendNotification({
    title: `Salary Slip Generated 💵`,
    message: `Your salary slip for ${month} ${year} of ₹${netSalary.toLocaleString()} is now ready to download.`,
    type: 'GENERAL',
    targetRole: 'SPECIFIC',
    recipientId: teacherId,
    senderId: req.user._id,
  });

  return res.status(201).json(
    new ApiResponse(201, slip, 'Salary slip generated successfully')
  );
});

/**
 * Payroll: Get all salary slips
 */
const getAllSalarySlips = asyncHandler(async (req, res) => {
  const slips = await SalarySlip.find()
    .populate('teacherId', 'name email phone subjects')
    .sort({ createdAt: -1 });
  return res.status(200).json(new ApiResponse(200, slips, 'Salary slips retrieved'));
});

/**
 * 10. School Settings, Transport & Library Hub
 */
const getSchoolSettings = asyncHandler(async (req, res) => {
  let settings = await SchoolSetting.findOne();
  if (!settings) {
    settings = await SchoolSetting.create({
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
  }

  return res.status(200).json(new ApiResponse(200, settings, 'School settings retrieved'));
});

/**
 * School Settings: Update profile, transport, or library
 */
const updateSchoolSettings = asyncHandler(async (req, res) => {
  const updates = req.body;
  let settings = await SchoolSetting.findOne();
  if (!settings) {
    settings = await SchoolSetting.create(updates);
  } else {
    Object.assign(settings, updates);
    await settings.save();
  }

  return res.status(200).json(new ApiResponse(200, settings, 'School settings updated successfully'));
});

module.exports = {
  getDashboardStats,
  getAllStudents,
  getStudentById,
  createStudent,
  updateStudent,
  deleteStudent,
  updateStudentStatus,
  promoteStudents,
  getTeachersList,
  createTeacher,
  updateTeacher,
  deleteTeacher,
  getPendingApprovals,
  updateApprovalStatus,
  createClassRoom,
  getAllClasses,
  updateClassRoom,
  deleteClassRoom,
  assignClassTeacher,
  getFeesOverview,
  getAllFeeRecords,
  generateFeeInvoices,
  recordFeePayment,
  getAdminAttendanceOverview,
  notifyAbsentParents,
  getAdminExamsOverview,
  publishExamResults,
  broadcastNotice,
  generateSalarySlip,
  getAllSalarySlips,
  getSchoolSettings,
  updateSchoolSettings,
};
