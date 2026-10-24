require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/user.model');
const School = require('../models/school.model');
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
const BiometricDevice = require('../models/biometricDevice.model');
const BusTracker = require('../models/busTracker.model');
const AuditLog = require('../models/auditLog.model');
const PlatformSetting = require('../models/platformSetting.model');

const { ROLES } = require('../constants/roles');
const { USER_STATUS, SCHOOL_STATUS, BUS_STATUS, BIOMETRIC_STATUS, ATTENDANCE_STATUS, EXAM_TYPES, LEAVE_STATUS, FEE_STATUS } = require('../constants/status');

const seed = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/school_management_db');
    console.log('[Seed] Connected to database successfully');

    // Clean existing collections
    await Promise.all([
      School.deleteMany({}),
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
      BiometricDevice.deleteMany({}),
      BusTracker.deleteMany({}),
      AuditLog.deleteMany({}),
      PlatformSetting.deleteMany({}),
    ]);
    console.log('[Seed] Cleaned existing collections');

    // 1. Create Platform Setting
    const platformSetting = await PlatformSetting.create({
      platformName: 'ScholarCloud Unified Multi-School Platform',
      systemVersion: '3.4.0-Enterprise',
      maintenanceMode: false,
      defaultAcademicYear: '2026-2027',
      backupRetentionDays: 30,
      lastBackupAt: new Date(Date.now() - 3600000 * 4), // 4 hours ago
      lastBackupSizeMB: 348.6,
      failedLoginThreshold: 5,
    });

    // 2. Create Super Admin User
    const superAdmin = await User.create({
      name: 'Dr. Amitabh Sen (Chief Super Admin)',
      email: 'superadmin@scholarcloud.com',
      phone: '9999988888',
      password: 'Password@123',
      role: ROLES.SUPER_ADMIN,
      status: USER_STATUS.APPROVED,
      isOtpVerified: true,
      designation: 'Director of Platform Operations',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      permissions: {
        canView: true,
        canCreate: true,
        canEdit: true,
        canDelete: true,
        canApprove: true,
        canPublish: true,
        canExport: true,
      },
    });

    // 3. Create Multiple Schools
    // School 1: St. Xavier International Academy (Active)
    const schoolXavier = await School.create({
      name: 'St. Xavier International Academy',
      code: 'SXIS-MUM-01',
      affiliationCode: 'CBSE-MAH-2026-9812',
      status: SCHOOL_STATUS.ACTIVE,
      contactEmail: 'admin@school.com',
      contactPhone: '+91 98765 43210',
      address: 'Plot 14, Institutional Area, Sector 62',
      city: 'Mumbai',
      state: 'Maharashtra',
      principalName: 'Dr. Vivek Saxena',
      logo: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?auto=format&fit=crop&w=200&q=80',
      currentAcademicYear: '2026-2027',
      geofence: { latitude: 19.0760, longitude: 72.8777, radiusMeters: 300 },
      limits: { maxStudents: 1500, maxTeachers: 120, maxStaff: 60, storageLimitMB: 15360, usedStorageMB: 310 },
      modules: {
        busTracking: true,
        biometricAttendance: true,
        feeManagement: true,
        examResults: true,
        studentAdmission: true,
        leaveManagement: true,
        libraryModule: true,
        dailySyllabus: true,
      },
    });

    // School 2: Delhi Public Academy (Active)
    const schoolDPA = await School.create({
      name: 'Delhi Public Academy',
      code: 'DPA-DEL-02',
      affiliationCode: 'CBSE-DEL-2025-4120',
      status: SCHOOL_STATUS.ACTIVE,
      contactEmail: 'admin.dpa@school.com',
      contactPhone: '+91 98111 22334',
      address: 'Vasant Kunj Sector C, Institutional Road',
      city: 'New Delhi',
      state: 'Delhi',
      principalName: 'Mrs. Sunita Kaul',
      logo: 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?auto=format&fit=crop&w=200&q=80',
      currentAcademicYear: '2026-2027',
      geofence: { latitude: 28.5245, longitude: 77.1585, radiusMeters: 350 },
      limits: { maxStudents: 2000, maxTeachers: 150, maxStaff: 80, storageLimitMB: 20480, usedStorageMB: 420 },
      modules: {
        busTracking: true,
        biometricAttendance: true,
        feeManagement: true,
        examResults: true,
        studentAdmission: true,
        leaveManagement: true,
        libraryModule: true,
        dailySyllabus: true,
      },
    });

    // School 3: Greenwood Global High (Pending Approval)
    const schoolGreenwood = await School.create({
      name: 'Greenwood Global High',
      code: 'GGH-BLR-03',
      affiliationCode: 'ICSE-KAR-2026-1189',
      status: SCHOOL_STATUS.PENDING,
      contactEmail: 'admin.greenwood@school.com',
      contactPhone: '+91 99000 55443',
      address: 'Outer Ring Road, Marathahalli',
      city: 'Bengaluru',
      state: 'Karnataka',
      principalName: 'Mr. Arvind Swamy',
      logo: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=200&q=80',
      currentAcademicYear: '2026-2027',
      geofence: { latitude: 12.9716, longitude: 77.5946, radiusMeters: 250 },
      limits: { maxStudents: 800, maxTeachers: 60, maxStaff: 30, storageLimitMB: 8192, usedStorageMB: 50 },
      modules: {
        busTracking: true,
        biometricAttendance: true,
        feeManagement: true,
        examResults: true,
        studentAdmission: true,
        leaveManagement: true,
        libraryModule: false,
        dailySyllabus: true,
      },
    });

    // School 4: Heritage Cambridge School (Suspended)
    const schoolHeritage = await School.create({
      name: 'Heritage Cambridge School',
      code: 'HCS-KOL-04',
      affiliationCode: 'WBCSE-WB-2024-5541',
      status: SCHOOL_STATUS.SUSPENDED,
      contactEmail: 'principal.heritage@school.com',
      contactPhone: '+91 98300 11223',
      address: 'Salt Lake Sector 5, Salt Lake Bypass',
      city: 'Kolkata',
      state: 'West Bengal',
      principalName: 'Dr. Debabrata Roy',
      logo: 'https://images.unsplash.com/photo-1509062522246-3755977927d7?auto=format&fit=crop&w=200&q=80',
      currentAcademicYear: '2026-2027',
      geofence: { latitude: 22.5726, longitude: 88.3639, radiusMeters: 300 },
      limits: { maxStudents: 600, maxTeachers: 45, maxStaff: 20, storageLimitMB: 5120, usedStorageMB: 90 },
      modules: {
        busTracking: false,
        biometricAttendance: false,
        feeManagement: true,
        examResults: false,
        studentAdmission: false,
        leaveManagement: true,
        libraryModule: false,
        dailySyllabus: false,
      },
    });

    console.log('[Seed] 4 Multi-tenant Schools created');

    // 4. Create School Admins
    // Admin for St. Xavier
    const adminXavier = await User.create({
      name: 'Dr. Vivek Saxena (School Admin)',
      email: 'admin@school.com',
      phone: '9876543210',
      password: 'Password@123',
      role: ROLES.ADMIN,
      schoolId: schoolXavier._id,
      status: USER_STATUS.APPROVED,
      isOtpVerified: true,
      designation: 'Principal & Head of School',
      employeeId: 'ADM-SXIS-001',
      avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=200&q=80',
      permissions: {
        canView: true,
        canCreate: true,
        canEdit: true,
        canDelete: false,
        canApprove: true,
        canPublish: true,
        canExport: true,
      },
    });

    // Admin for Delhi Public Academy
    const adminDPA = await User.create({
      name: 'Mrs. Sunita Kaul (School Admin)',
      email: 'admin.dpa@school.com',
      phone: '9811122334',
      password: 'Password@123',
      role: ROLES.ADMIN,
      schoolId: schoolDPA._id,
      status: USER_STATUS.APPROVED,
      isOtpVerified: true,
      designation: 'Vice Principal & Admin Incharge',
      employeeId: 'ADM-DPA-002',
      avatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=200&q=80',
      permissions: {
        canView: true,
        canCreate: true,
        canEdit: true,
        canDelete: false,
        canApprove: true,
        canPublish: true,
        canExport: true,
      },
    });

    // Pending Admin for Greenwood Global
    const adminGreenwood = await User.create({
      name: 'Mr. Arvind Swamy (Applicant)',
      email: 'admin.greenwood@school.com',
      phone: '9900055443',
      password: 'Password@123',
      role: ROLES.ADMIN,
      schoolId: schoolGreenwood._id,
      status: USER_STATUS.PENDING,
      isOtpVerified: true,
      designation: 'Campus Director',
      employeeId: 'ADM-GGH-003',
      permissions: {
        canView: true,
        canCreate: false,
        canEdit: false,
        canDelete: false,
        canApprove: false,
        canPublish: false,
        canExport: false,
      },
    });

    // 5. Create Classrooms for St. Xavier & DPA
    const class10A = await ClassRoom.create({
      schoolId: schoolXavier._id,
      name: 'Class 10',
      section: 'A',
      roomNumber: 'Room 204',
      capacity: 40,
    });

    const class10B = await ClassRoom.create({
      schoolId: schoolXavier._id,
      name: 'Class 10',
      section: 'B',
      roomNumber: 'Room 205',
      capacity: 40,
    });

    const class9A = await ClassRoom.create({
      schoolId: schoolDPA._id,
      name: 'Class 9',
      section: 'A',
      roomNumber: 'Block C - 101',
      capacity: 45,
    });

    // 6. Create Teachers
    const teacherRahul = await User.create({
      name: 'Rahul Sharma',
      email: 'teacher.rahul@school.com',
      phone: '9876543211',
      password: 'Password@123',
      role: ROLES.TEACHER,
      schoolId: schoolXavier._id,
      status: USER_STATUS.APPROVED,
      isOtpVerified: true,
      subjects: ['Mathematics', 'Physics'],
      qualification: 'M.Sc. Mathematics, B.Ed.',
      salary: 58000,
      designation: 'Senior PGT Mathematics',
      employeeId: 'TCH-SXIS-101',
      isClassTeacher: true,
      assignedClass: class10A._id,
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
    });
    class10A.classTeacher = teacherRahul._id;
    await class10A.save();

    const teacherPriya = await User.create({
      name: 'Priya Mukherjee',
      email: 'teacher.priya@school.com',
      phone: '9876543212',
      password: 'Password@123',
      role: ROLES.TEACHER,
      schoolId: schoolXavier._id,
      status: USER_STATUS.APPROVED,
      isOtpVerified: true,
      subjects: ['English Literature', 'Social Studies'],
      qualification: 'M.A. English, B.Ed.',
      salary: 52000,
      designation: 'TGT English',
      employeeId: 'TCH-SXIS-102',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
    });

    const teacherAmit = await User.create({
      name: 'Amit Patel',
      email: 'teacher.amit@school.com',
      phone: '9876543213',
      password: 'Password@123',
      role: ROLES.TEACHER,
      schoolId: schoolXavier._id,
      status: USER_STATUS.PENDING,
      isOtpVerified: true,
      subjects: ['Computer Science', 'Artificial Intelligence'],
      qualification: 'B.Tech CSE, MCA',
      salary: 60000,
      designation: 'PGT Informatics',
      employeeId: 'TCH-SXIS-103',
    });

    // 7. Create Parents & Students
    const parentRajesh = await User.create({
      name: 'Rajesh Sharma',
      email: 'parent.rajesh@gmail.com',
      phone: '9876543214',
      password: 'Password@123',
      role: ROLES.PARENT,
      schoolId: schoolXavier._id,
      status: USER_STATUS.APPROVED,
      isOtpVerified: true,
      address: 'Flat 402, Royal Palms, Sector 62, Mumbai',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
    });

    const studentAarav = await Student.create({
      name: 'Aarav Sharma',
      rollNumber: 1,
      admissionNumber: 'SCH-2026-001',
      schoolId: schoolXavier._id,
      classId: class10A._id,
      parentId: parentRajesh._id,
      dateOfBirth: new Date('2011-04-12'),
      gender: 'MALE',
      bloodGroup: 'B+',
      address: 'Flat 402, Royal Palms, Sector 62, Mumbai',
      emergencyContact: '+91 98765 43214',
      photo: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=150&q=80',
      status: 'ACTIVE',
      academicSession: '2026-2027',
    });
    parentRajesh.children = [studentAarav._id];
    await parentRajesh.save();

    const parentVikram = await User.create({
      name: 'Vikram Malhotra',
      email: 'parent.vikram@gmail.com',
      phone: '9876543215',
      password: 'Password@123',
      role: ROLES.PARENT,
      schoolId: schoolXavier._id,
      status: USER_STATUS.PENDING,
      isOtpVerified: true,
      address: 'Villa 12, Palm Meadows, Mumbai',
    });

    const studentRohan = await Student.create({
      name: 'Rohan Malhotra',
      rollNumber: 2,
      admissionNumber: 'SCH-2026-002',
      schoolId: schoolXavier._id,
      classId: class10A._id,
      parentId: parentVikram._id,
      dateOfBirth: new Date('2011-07-25'),
      gender: 'MALE',
      bloodGroup: 'O+',
      address: 'Villa 12, Palm Meadows, Mumbai',
      emergencyContact: '+91 98765 43215',
      status: 'ACTIVE',
    });
    parentVikram.children = [studentRohan._id];
    await parentVikram.save();

    // 8. Create Student Attendance & Faculty Attendance with GPS
    const todayStr = new Date().toISOString().split('T')[0];
    await Attendance.create({
      schoolId: schoolXavier._id,
      date: todayStr,
      attendanceType: 'STUDENT',
      classId: class10A._id,
      markedBy: teacherRahul._id,
      records: [
        { studentId: studentAarav._id, status: ATTENDANCE_STATUS.PRESENT, remarks: 'On time' },
        { studentId: studentRohan._id, status: ATTENDANCE_STATUS.PRESENT, remarks: 'On time' },
      ],
    });

    // Faculty Attendance for Rahul Sharma with verified GPS Coordinates
    await Attendance.create({
      schoolId: schoolXavier._id,
      date: todayStr,
      attendanceType: 'FACULTY',
      teacherId: teacherRahul._id,
      markedBy: adminXavier._id,
      gpsPunch: {
        latitude: 19.0762,
        longitude: 72.8779,
        distanceMeters: 42,
        isWithinGeofence: true,
        punchInTime: new Date(Date.now() - 3600000 * 5),
        punchOutTime: null,
      },
      biometricPunchId: 'BIO-PUNCH-8841',
      records: [],
    });

    // 9. Create Biometric Machines
    await BiometricDevice.create({
      schoolId: schoolXavier._id,
      name: 'Main Gate Terminal 1',
      deviceSerial: 'ZK-TECO-MB460-XAV01',
      ipAddress: '192.168.1.101',
      location: 'Administrative Block - Gate A',
      status: BIOMETRIC_STATUS.ONLINE,
      lastSyncAt: new Date(),
      totalPunchesToday: 48,
      failedSyncAlerts: 0,
      syncLogs: [
        { timestamp: new Date(Date.now() - 600000), recordsCount: 12, status: 'SUCCESS', notes: 'Automated 10-minute sync successful' },
        { timestamp: new Date(Date.now() - 1200000), recordsCount: 36, status: 'SUCCESS', notes: 'Morning check-in batch synchronized' },
      ],
    });

    await BiometricDevice.create({
      schoolId: schoolXavier._id,
      name: 'Faculty Lounge Terminal 2',
      deviceSerial: 'ESL-BIO-F200-XAV02',
      ipAddress: '192.168.1.102',
      location: 'Staff Room First Floor',
      status: BIOMETRIC_STATUS.ONLINE,
      lastSyncAt: new Date(Date.now() - 1800000),
      totalPunchesToday: 24,
      failedSyncAlerts: 0,
      syncLogs: [
        { timestamp: new Date(Date.now() - 1800000), recordsCount: 24, status: 'SUCCESS', notes: 'Faculty morning check-in sync complete' },
      ],
    });

    await BiometricDevice.create({
      schoolId: schoolDPA._id,
      name: 'DPA Campus Central Scanner',
      deviceSerial: 'ANVIZ-C2PRO-DPA01',
      ipAddress: '192.168.2.55',
      location: 'Principal Entrance Lobby',
      status: BIOMETRIC_STATUS.SYNCING,
      lastSyncAt: new Date(),
      totalPunchesToday: 82,
      failedSyncAlerts: 0,
      syncLogs: [
        { timestamp: new Date(), recordsCount: 15, status: 'SUCCESS', notes: 'Active stream sync ongoing' },
      ],
    });

    await BiometricDevice.create({
      schoolId: schoolHeritage._id,
      name: 'Heritage Gateway Biometric',
      deviceSerial: 'ZK-TECO-F18-HCS01',
      ipAddress: '192.168.4.10',
      location: 'West Gate Security Cabin',
      status: BIOMETRIC_STATUS.OFFLINE,
      lastSyncAt: new Date(Date.now() - 86400000 * 2),
      totalPunchesToday: 0,
      failedSyncAlerts: 4,
      syncLogs: [
        { timestamp: new Date(Date.now() - 86400000 * 2), recordsCount: 0, status: 'FAILED', notes: 'Connection timed out: Device unreachable on IP 192.168.4.10' },
      ],
    });

    // 10. Create Bus Fleet with Live GPS Trackers & Expiry Alerts
    await BusTracker.create({
      schoolId: schoolXavier._id,
      busNumber: 'MH-02-CB-4890',
      routeName: 'Route 101: Andheri East to Campus',
      driverName: 'Suresh Gaikwad',
      driverPhone: '+91 98200 44332',
      gpsDeviceId: 'GPS-TRK-7711',
      status: BUS_STATUS.ACTIVE_TRIP,
      tripType: 'MORNING_PICKUP',
      capacity: 40,
      assignedStudentsCount: 28,
      currentLocation: {
        latitude: 19.1136,
        longitude: 72.8697,
        speedKmH: 34,
        heading: 145,
        lastPingAt: new Date(),
      },
      stops: [
        { stopName: 'Andheri Metro Station', scheduledTime: '07:15 AM', latitude: 19.1197, longitude: 72.8464, arrived: true, studentCount: 8 },
        { stopName: 'Chakala Junction', scheduledTime: '07:30 AM', latitude: 19.1114, longitude: 72.8608, arrived: true, studentCount: 12 },
        { stopName: 'MIDC Cross Road', scheduledTime: '07:45 AM', latitude: 19.1180, longitude: 72.8790, arrived: false, studentCount: 8 },
        { stopName: 'St. Xavier Campus Gate', scheduledTime: '08:05 AM', latitude: 19.0760, longitude: 72.8777, arrived: false, studentCount: 0 },
      ],
      insuranceExpiryDate: new Date(Date.now() + 120 * 24 * 60 * 60 * 1000),
      fitnessExpiryDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000),
      pollutionExpiryDate: new Date(Date.now() + 12 * 24 * 60 * 60 * 1000), // EXPIRING IN 12 DAYS! Triggers alert
    });

    await BusTracker.create({
      schoolId: schoolXavier._id,
      busNumber: 'MH-02-CB-4891',
      routeName: 'Route 102: Bandra West to Campus',
      driverName: 'Ramesh Sawant',
      driverPhone: '+91 98200 99887',
      gpsDeviceId: 'GPS-TRK-7712',
      status: BUS_STATUS.IDLE,
      tripType: 'IDLE',
      capacity: 35,
      assignedStudentsCount: 22,
      currentLocation: {
        latitude: 19.0760,
        longitude: 72.8777,
        speedKmH: 0,
        heading: 0,
        lastPingAt: new Date(Date.now() - 15 * 60000),
      },
      insuranceExpiryDate: new Date(Date.now() + 200 * 24 * 60 * 60 * 1000),
      fitnessExpiryDate: new Date(Date.now() + 250 * 24 * 60 * 60 * 1000),
      pollutionExpiryDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
    });

    await BusTracker.create({
      schoolId: schoolDPA._id,
      busNumber: 'DL-01-AB-1234',
      routeName: 'DPA Route 1: Noida Sec 62 to Vasant Kunj',
      driverName: 'Harpreet Singh',
      driverPhone: '+91 98111 66554',
      gpsDeviceId: 'GPS-TRK-8822',
      status: BUS_STATUS.ACTIVE_TRIP,
      tripType: 'MORNING_PICKUP',
      capacity: 45,
      assignedStudentsCount: 38,
      currentLocation: {
        latitude: 28.5670,
        longitude: 77.2430,
        speedKmH: 42,
        heading: 210,
        lastPingAt: new Date(),
      },
      stops: [
        { stopName: 'Sector 62 Fortis', scheduledTime: '07:10 AM', latitude: 28.6200, longitude: 77.3600, arrived: true, studentCount: 15 },
        { stopName: 'Lajpat Nagar Ring Road', scheduledTime: '07:35 AM', latitude: 28.5670, longitude: 77.2430, arrived: true, studentCount: 14 },
        { stopName: 'AIIMS Flyover', scheduledTime: '07:48 AM', latitude: 28.5680, longitude: 77.2080, arrived: false, studentCount: 9 },
        { stopName: 'DPA Campus Vasant Kunj', scheduledTime: '08:10 AM', latitude: 28.5245, longitude: 77.1585, arrived: false, studentCount: 0 },
      ],
      insuranceExpiryDate: new Date(Date.now() + 150 * 24 * 60 * 60 * 1000),
      fitnessExpiryDate: new Date(Date.now() + 6 * 24 * 60 * 60 * 1000), // EXPIRING IN 6 DAYS! Urgent Alert
      pollutionExpiryDate: new Date(Date.now() + 45 * 24 * 60 * 60 * 1000),
    });

    // 11. Create Exam Results
    await ExamResult.create({
      schoolId: schoolXavier._id,
      studentId: studentAarav._id,
      classId: class10A._id,
      examType: EXAM_TYPES.HALF_YEARLY,
      examTitle: 'Half-Yearly Examination 2026',
      academicYear: '2026-2027',
      enteredBy: teacherRahul._id,
      approvalStatus: 'APPROVED',
      isPublished: true,
      subjects: [
        { subjectName: 'Mathematics', maxMarks: 100, marksObtained: 94, grade: 'A+' },
        { subjectName: 'Physics', maxMarks: 100, marksObtained: 89, grade: 'A' },
        { subjectName: 'English Literature', maxMarks: 100, marksObtained: 86, grade: 'A' },
      ],
    });

    await ExamResult.create({
      schoolId: schoolXavier._id,
      studentId: studentRohan._id,
      classId: class10A._id,
      examType: EXAM_TYPES.HALF_YEARLY,
      examTitle: 'Half-Yearly Examination 2026',
      academicYear: '2026-2027',
      enteredBy: teacherRahul._id,
      approvalStatus: 'PENDING_APPROVAL',
      isPublished: false,
      subjects: [
        { subjectName: 'Mathematics', maxMarks: 100, marksObtained: 78, grade: 'B+' },
        { subjectName: 'Physics', maxMarks: 100, marksObtained: 82, grade: 'A' },
        { subjectName: 'English Literature', maxMarks: 100, marksObtained: 74, grade: 'B+' },
      ],
    });

    // 12. Create Fee Records
    await FeeRecord.create({
      schoolId: schoolXavier._id,
      studentId: studentAarav._id,
      parentId: parentRajesh._id,
      title: 'Term 1 Tuition & Composite Fee',
      feeCategory: 'TUITION',
      academicYear: '2026-2027',
      totalAmount: 25000,
      paidAmount: 25000,
      dueDate: new Date('2026-08-30'),
      status: FEE_STATUS.PAID,
      reconciliationStatus: 'RECONCILED',
      payments: [
        {
          amount: 25000,
          paymentDate: new Date('2026-08-20'),
          transactionId: 'TXN-UPI-99228811',
          method: 'UPI',
          receiptNumber: 'REC-260820',
        },
      ],
    });

    await FeeRecord.create({
      schoolId: schoolXavier._id,
      studentId: studentRohan._id,
      parentId: parentVikram._id,
      title: 'Term 1 Tuition & Composite Fee',
      feeCategory: 'TUITION',
      academicYear: '2026-2027',
      totalAmount: 25000,
      paidAmount: 10000,
      dueDate: new Date('2026-10-15'),
      status: FEE_STATUS.PARTIAL,
      reconciliationStatus: 'RECONCILED',
      payments: [
        {
          amount: 10000,
          paymentDate: new Date('2026-10-10'),
          transactionId: 'TXN-BANK-11002233',
          method: 'BANK_TRANSFER',
          receiptNumber: 'REC-261010',
        },
      ],
    });

    // 13. Create Central Notifications
    await Notification.create({
      title: 'Central Safety Protocol & Bus GPS Compliance 2026',
      message: 'All school principals and transport in-charges must ensure biometric synchronization and bus GPS trackers are verified before 30th October.',
      type: 'BROADCAST',
      targetRole: 'ADMIN',
      schoolId: null, // Platform-wide
      senderId: superAdmin._id,
      deliveryStatus: 'SENT',
    });

    await Notification.create({
      title: 'Emergency Advisory: Heavy Rain Warning',
      message: 'Meteorological department has issued an alert for coastal Maharashtra. St. Xavier campus afternoon bus departures rescheduled by 1 hour.',
      type: 'EMERGENCY',
      targetRole: 'ALL',
      schoolId: schoolXavier._id,
      isEmergency: true,
      senderId: superAdmin._id,
      deliveryStatus: 'SENT',
    });

    // 14. Create Initial Audit Logs
    await AuditLog.create({
      action: 'PLATFORM_INITIALIZATION',
      performedBy: superAdmin._id,
      performedByName: superAdmin.name,
      targetEntity: 'PlatformSetting',
      targetId: platformSetting._id,
      schoolId: null,
      schoolName: 'Platform Wide',
      details: { version: '3.4.0-Enterprise', initializedSchools: 4 },
      status: 'SUCCESS',
    });

    await AuditLog.create({
      action: 'APPROVE_SCHOOL',
      performedBy: superAdmin._id,
      performedByName: superAdmin.name,
      targetEntity: 'School',
      targetId: schoolXavier._id,
      schoolId: schoolXavier._id,
      schoolName: schoolXavier.name,
      details: { code: schoolXavier.code, status: 'ACTIVE' },
      status: 'SUCCESS',
    });

    console.log('====================================================');
    console.log('✅ COMPREHENSIVE MULTI-SCHOOL SEEDING COMPLETED!');
    console.log('----------------------------------------------------');
    console.log('👑 SUPER ADMIN CREDENTIALS:');
    console.log('   Email:    superadmin@scholarcloud.com');
    console.log('   Phone:    9999988888');
    console.log('   Password: Password@123');
    console.log('----------------------------------------------------');
    console.log('🏫 SCHOOL ADMIN CREDENTIALS:');
    console.log('   St. Xavier:    admin@school.com     / Password@123');
    console.log('   Delhi Public:  admin.dpa@school.com / Password@123');
    console.log('   Greenwood:     admin.greenwood@school.com (Pending)');
    console.log('----------------------------------------------------');
    console.log('👨‍🏫 CLASS TEACHER:  teacher.rahul@school.com / Password@123');
    console.log('👨‍👩‍👧 PARENT:         parent.rajesh@gmail.com / Password@123');
    console.log('====================================================');

    process.exit(0);
  } catch (error) {
    console.error('Fatal Seed Error:', error);
    process.exit(1);
  }
};

seed();
