import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class TeacherState {
  final bool isLoading;
  final Map<String, dynamic>? classInfo;
  final List<dynamic> students;
  final List<dynamic> leaveRequests;
  final List<dynamic> salarySlips;
  final Map<String, dynamic>? todayAttendance;
  final List<dynamic> attendanceLogs;
  final Map<String, dynamic>? monthlyReport;
  final String? errorMessage;

  TeacherState({
    this.isLoading = false,
    this.classInfo,
    this.students = const [],
    this.leaveRequests = const [],
    this.salarySlips = const [],
    this.todayAttendance,
    this.attendanceLogs = const [],
    this.monthlyReport,
    this.errorMessage,
  });

  TeacherState copyWith({
    bool? isLoading,
    Map<String, dynamic>? classInfo,
    List<dynamic>? students,
    List<dynamic>? leaveRequests,
    List<dynamic>? salarySlips,
    Map<String, dynamic>? todayAttendance,
    List<dynamic>? attendanceLogs,
    Map<String, dynamic>? monthlyReport,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TeacherState(
      isLoading: isLoading ?? this.isLoading,
      classInfo: classInfo ?? this.classInfo,
      students: students ?? this.students,
      leaveRequests: leaveRequests ?? this.leaveRequests,
      salarySlips: salarySlips ?? this.salarySlips,
      todayAttendance: todayAttendance ?? this.todayAttendance,
      attendanceLogs: attendanceLogs ?? this.attendanceLogs,
      monthlyReport: monthlyReport ?? this.monthlyReport,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TeacherNotifier extends StateNotifier<TeacherState> {
  TeacherNotifier() : super(TeacherState());

  final Dio _dio = DioClient.instance;

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final classRes = await _dio.get(ApiConstants.teacherClassInfo);
      final classData = classRes.data['data'];

      final classId = classData?['classroom']?['_id'];

      List<dynamic> studentsList = [];
      List<dynamic> leavesList = [];
      Map<String, dynamic>? todayAttData;

      if (classId != null) {
        final studentsRes = await _dio.get(
          ApiConstants.teacherStudents,
          queryParameters: {'classId': classId},
        );
        studentsList = studentsRes.data['data']?['students'] ?? [];

        final leavesRes = await _dio.get(
          ApiConstants.classLeaves,
          queryParameters: {'classId': classId},
        );
        leavesList = leavesRes.data['data'] ?? [];

        // Load today's attendance summary for quick teacher view
        try {
          final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final attRes = await _dio.get(
            ApiConstants.classAttendance,
            queryParameters: {'classId': classId, 'date': todayStr},
          );
          todayAttData = attRes.data['data'];
        } catch (_) {}
      }

      final salaryRes = await _dio.get(ApiConstants.teacherSalarySlips);
      final salaryList = salaryRes.data['data'] ?? [];

      state = state.copyWith(
        isLoading: false,
        classInfo: classData,
        students: studentsList,
        leaveRequests: leavesList,
        salarySlips: salaryList,
        todayAttendance: todayAttData,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.error?.toString());
    }
  }

  Future<Map<String, dynamic>?> fetchAttendanceForDate({
    required String classId,
    required String date,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.classAttendance,
        queryParameters: {'classId': classId, 'date': date},
      );
      return res.data['data'];
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return null;
    }
  }

  Future<List<dynamic>> fetchClassAttendanceLogs({
    required String classId,
    String? month,
    String? year,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.classAttendanceLogs(classId),
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      final logs = res.data['data'] as List<dynamic>? ?? [];
      state = state.copyWith(attendanceLogs: logs);
      return logs;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchClassMonthlyReport({
    required String classId,
    String? month,
    String? year,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.classMonthlyReport(classId),
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      final report = res.data['data'];
      state = state.copyWith(monthlyReport: report);
      return report;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return null;
    }
  }

  Future<bool> markAttendance({
    required String classId,
    required String date,
    required List<Map<String, dynamic>> records,
  }) async {
    try {
      await _dio.post(
        ApiConstants.markAttendance,
        data: {
          'classId': classId,
          'date': date,
          'records': records,
        },
      );
      // Reload dashboard so today's attendance updates immediately across views
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<bool> recordExamMarks({
    required String studentId,
    required String classId,
    required String examType,
    required String examTitle,
    required List<Map<String, dynamic>> subjects,
    String academicYear = '2026-2027',
  }) async {
    try {
      await _dio.post(
        ApiConstants.recordMarks,
        data: {
          'studentId': studentId,
          'classId': classId,
          'examType': examType,
          'examTitle': examTitle,
          'academicYear': academicYear,
          'subjects': subjects,
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<bool> createHomework({
    required String title,
    required String description,
    required String subject,
    required String classId,
    required DateTime submissionDate,
  }) async {
    try {
      await _dio.post(
        ApiConstants.homework,
        data: {
          'title': title,
          'description': description,
          'subject': subject,
          'classId': classId,
          'submissionDate': submissionDate.toIso8601String(),
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<bool> sendNotice({
    required String title,
    required String message,
  }) async {
    try {
      await _dio.post(
        ApiConstants.teacherNotice,
        data: {'title': title, 'message': message},
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<bool> reviewLeave({
    required String leaveId,
    required String status,
    String reviewNotes = '',
  }) async {
    try {
      await _dio.patch(
        '${ApiConstants.reviewLeave}/$leaveId',
        data: {'status': status, 'reviewNotes': reviewNotes},
      );
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }
}

final teacherProvider = StateNotifierProvider<TeacherNotifier, TeacherState>((ref) {
  return TeacherNotifier();
});
