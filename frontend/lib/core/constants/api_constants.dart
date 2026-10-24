import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Toggle this to switch between Render cloud backend and local backend
  // In release mode (APK), it defaults to using the live Render cloud server
  static const bool useLiveServer = true;

  // Live Render deployment URL (HTTPS automatically maps to port 10000 on Render)
  static const String liveServerUrl = 'https://educationapp-2.onrender.com';

  // Dynamically resolve base URL
  static String get baseUrl {
    if (useLiveServer || kReleaseMode) {
      return '$liveServerUrl/api/v1';
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    if (Platform.isAndroid) {
      // Android emulator reaches host machine on 10.0.2.2
      return 'http://10.0.2.2:5000/api/v1';
    }
    return 'http://localhost:5000/api/v1';
  }

  static String get socketUrl {
    if (useLiveServer || kReleaseMode) {
      return liveServerUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  // Auth endpoints
  static const String login = '/auth/login';
  static const String registerAdmin = '/auth/register/admin';
  static const String verifyOtp = '/auth/verify-otp';
  static const String registerTeacher = '/auth/register/teacher';
  static const String registerParent = '/auth/register/parent';
  static const String currentUser = '/auth/me';

  // Admin endpoints
  static const String adminStats = '/admin/stats';
  static const String adminTeachers = '/admin/teachers';
  static const String adminApprovals = '/admin/approvals';
  static const String adminClasses = '/admin/classes';
  static const String adminBroadcast = '/admin/broadcast';
  static const String adminSalarySlips = '/admin/salary-slips';
  static const String adminStudents = '/admin/students';
  static const String adminStudentsPromote = '/admin/students/promote';
  static const String adminFeesOverview = '/admin/fees/overview';
  static const String adminFeesRecords = '/admin/fees/records';
  static const String adminFeesGenerate = '/admin/fees/generate';
  static const String adminAttendanceOverview = '/admin/attendance/overview';
  static const String adminNotifyAbsent = '/admin/attendance/notify-absent';
  static const String adminExamsOverview = '/admin/exams/overview';
  static const String adminPublishExams = '/admin/exams/publish';
  static const String adminSettings = '/admin/settings';

  // Teacher endpoints
  static const String teacherClassInfo = '/teacher/class-info';
  static const String teacherStudents = '/teacher/students';
  static const String teacherNotice = '/teacher/notice';
  static const String teacherSalarySlips = '/teacher/salary-slips';

  // Attendance endpoints
  static const String markAttendance = '/attendance/mark';
  static const String classAttendance = '/attendance/class';
  static const String studentAttendanceReport = '/attendance/student';
  static String classAttendanceLogs(String classId) => '/attendance/class/$classId/logs';
  static String classMonthlyReport(String classId) => '/attendance/class/$classId/monthly-report';

  // Exam endpoints
  static const String recordMarks = '/exams/marks';
  static const String studentExams = '/exams/student';

  // Homework endpoints
  static const String homework = '/homework';

  // Leave endpoints
  static const String submitLeave = '/leave/request';
  static const String classLeaves = '/leave/class';
  static const String myLeaves = '/leave/my-requests';
  static const String reviewLeave = '/leave/review';

  // Fees endpoints
  static const String studentFees = '/fees/student';
  static const String payFee = '/fees/pay';

  // Parent endpoints
  static const String parentChildren = '/parent/children';
  static const String parentDashboard = '/parent/child';
  static const String holidays = '/parent/holidays';

  // Notifications
  static const String myNotifications = '/notifications/my';
}
