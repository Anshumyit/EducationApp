import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class AdminState {
  final bool isLoading;
  final Map<String, dynamic>? stats;
  final List<dynamic> teachers;
  final List<dynamic> pendingApprovals;
  final List<dynamic> salarySlips;
  final List<dynamic> students;
  final List<dynamic> classes;
  final Map<String, dynamic>? feesOverview;
  final List<dynamic> feeRecords;
  final Map<String, dynamic>? attendanceOverview;
  final Map<String, dynamic>? examsOverview;
  final Map<String, dynamic>? schoolSettings;
  final String? errorMessage;

  AdminState({
    this.isLoading = false,
    this.stats,
    this.teachers = const [],
    this.pendingApprovals = const [],
    this.salarySlips = const [],
    this.students = const [],
    this.classes = const [],
    this.feesOverview,
    this.feeRecords = const [],
    this.attendanceOverview,
    this.examsOverview,
    this.schoolSettings,
    this.errorMessage,
  });

  AdminState copyWith({
    bool? isLoading,
    Map<String, dynamic>? stats,
    List<dynamic>? teachers,
    List<dynamic>? pendingApprovals,
    List<dynamic>? salarySlips,
    List<dynamic>? students,
    List<dynamic>? classes,
    Map<String, dynamic>? feesOverview,
    List<dynamic>? feeRecords,
    Map<String, dynamic>? attendanceOverview,
    Map<String, dynamic>? examsOverview,
    Map<String, dynamic>? schoolSettings,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      teachers: teachers ?? this.teachers,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      salarySlips: salarySlips ?? this.salarySlips,
      students: students ?? this.students,
      classes: classes ?? this.classes,
      feesOverview: feesOverview ?? this.feesOverview,
      feeRecords: feeRecords ?? this.feeRecords,
      attendanceOverview: attendanceOverview ?? this.attendanceOverview,
      examsOverview: examsOverview ?? this.examsOverview,
      schoolSettings: schoolSettings ?? this.schoolSettings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState());

  final Dio _dio = DioClient.instance;

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _dio.get(ApiConstants.adminStats),
        _dio.get(ApiConstants.adminTeachers),
        _dio.get(ApiConstants.adminApprovals),
        _dio.get(ApiConstants.adminClasses),
      ]);

      state = state.copyWith(
        isLoading: false,
        stats: results[0].data['data'],
        teachers: results[1].data['data'] ?? [],
        pendingApprovals: results[2].data['data'] ?? [],
        classes: results[3].data['data'] ?? [],
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.error?.toString());
    }
  }

  // Load pending approvals specifically
  Future<void> loadPendingApprovals() async {
    try {
      final approvalsRes = await _dio.get(ApiConstants.adminApprovals);
      state = state.copyWith(
        pendingApprovals: approvalsRes.data['data'] ?? [],
      );
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
    }
  }

  // 1. Approvals with INSTANT OPTIMISTIC UI UPDATE (no refresh required)
  Future<bool> updateApprovalStatus(String userId, String status) async {
    // 1. Snapshot previous state in case rollback is required
    final previousPending = List<dynamic>.from(state.pendingApprovals);
    final previousTeachers = List<dynamic>.from(state.teachers);
    final previousStats = state.stats != null ? Map<String, dynamic>.from(state.stats!) : null;

    final targetIndex = previousPending.indexWhere((u) => u['_id'] == userId);
    final targetUser = targetIndex != -1 ? previousPending[targetIndex] : null;

    // 2. SUDDEN UPDATE: Optimistically remove user from pendingApprovals immediately
    final updatedPending = previousPending.where((u) => u['_id'] != userId).toList();

    // 3. SUDDEN UPDATE: Update teachers directory immediately if role is TEACHER
    List<dynamic> updatedTeachers = List<dynamic>.from(state.teachers);
    if (status == 'APPROVED') {
      if (targetUser != null && targetUser['role'] == 'TEACHER') {
        final approvedUserObj = Map<String, dynamic>.from(targetUser);
        approvedUserObj['status'] = 'APPROVED';
        final teacherIdx = updatedTeachers.indexWhere((t) => t['_id'] == userId);
        if (teacherIdx != -1) {
          updatedTeachers[teacherIdx] = approvedUserObj;
        } else {
          updatedTeachers.insert(0, approvedUserObj);
        }
      } else {
        // In case teacher already in list with PENDING status
        final teacherIdx = updatedTeachers.indexWhere((t) => t['_id'] == userId);
        if (teacherIdx != -1) {
          final teacherCopy = Map<String, dynamic>.from(updatedTeachers[teacherIdx]);
          teacherCopy['status'] = 'APPROVED';
          updatedTeachers[teacherIdx] = teacherCopy;
        }
      }
    } else {
      // REJECTED status
      final teacherIdx = updatedTeachers.indexWhere((t) => t['_id'] == userId);
      if (teacherIdx != -1) {
        final teacherCopy = Map<String, dynamic>.from(updatedTeachers[teacherIdx]);
        teacherCopy['status'] = 'REJECTED';
        updatedTeachers[teacherIdx] = teacherCopy;
      }
    }

    // 4. SUDDEN UPDATE: Decrement pending approvals count immediately
    Map<String, dynamic>? updatedStats;
    if (state.stats != null) {
      updatedStats = Map<String, dynamic>.from(state.stats!);
      final currentPending = (updatedStats['pendingApprovals'] as num?)?.toInt() ?? 1;
      updatedStats['pendingApprovals'] = (currentPending > 0) ? currentPending - 1 : 0;
      if (status == 'APPROVED' && targetUser != null && targetUser['role'] == 'TEACHER') {
        final currentTeachers = (updatedStats['totalTeachers'] as num?)?.toInt() ?? 0;
        updatedStats['totalTeachers'] = currentTeachers + 1;
      }
    }

    // Apply sudden optimistic update! The card vanishes & badges update at 0ms latency.
    state = state.copyWith(
      pendingApprovals: updatedPending,
      teachers: updatedTeachers,
      stats: updatedStats ?? state.stats,
      clearError: true,
    );

    try {
      await _dio.patch(
        '${ApiConstants.adminApprovals}/$userId',
        data: {'status': status},
      );

      // Re-sync quietly in background to confirm server state
      _resyncApprovalsQuietly();
      return true;
    } on DioException catch (e) {
      // Revert if API fails
      state = state.copyWith(
        pendingApprovals: previousPending,
        teachers: previousTeachers,
        stats: previousStats ?? state.stats,
        errorMessage: e.error?.toString() ?? 'Failed to update approval status',
      );
      return false;
    }
  }

  Future<void> _resyncApprovalsQuietly() async {
    try {
      final approvalsRes = await _dio.get(ApiConstants.adminApprovals);
      final statsRes = await _dio.get(ApiConstants.adminStats);
      final teachersRes = await _dio.get(ApiConstants.adminTeachers);
      state = state.copyWith(
        pendingApprovals: approvalsRes.data['data'] ?? [],
        stats: statsRes.data['data'] ?? state.stats,
        teachers: teachersRes.data['data'] ?? state.teachers,
      );
    } catch (_) {
      // Quiet background sync ignore
    }
  }

  // 2. Student Management
  Future<void> loadStudents({String? classId, String? search, String? status}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final query = <String, dynamic>{};
      if (classId != null && classId.isNotEmpty) query['classId'] = classId;
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (status != null && status.isNotEmpty) query['status'] = status;

      final res = await _dio.get(ApiConstants.adminStudents, queryParameters: query);
      state = state.copyWith(
        isLoading: false,
        students: res.data['data'] ?? [],
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.error?.toString());
    }
  }

  Future<bool> createStudent(Map<String, dynamic> data) async {
    try {
      await _dio.post(ApiConstants.adminStudents, data: data);
      await loadStudents();
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  Future<bool> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      await _dio.put('${ApiConstants.adminStudents}/$id', data: data);
      await loadStudents();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  Future<bool> deleteStudent(String id) async {
    try {
      await _dio.delete('${ApiConstants.adminStudents}/$id');
      await loadStudents();
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  Future<bool> updateStudentStatus(String id, String status, {String? tcReason, String? tcNumber}) async {
    try {
      await _dio.patch(
        '${ApiConstants.adminStudents}/$id/status',
        data: {'status': status, 'tcReason': tcReason, 'tcNumber': tcNumber},
      );
      await loadStudents();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  Future<bool> promoteStudents(List<String> studentIds, String targetClassId, {String? session}) async {
    try {
      await _dio.post(
        ApiConstants.adminStudentsPromote,
        data: {
          'studentIds': studentIds,
          'targetClassId': targetClassId,
          'newAcademicSession': session ?? '2026-2027',
        },
      );
      await loadStudents();
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  // 3. Teachers & Classes
  Future<void> loadClasses() async {
    try {
      final res = await _dio.get(ApiConstants.adminClasses);
      state = state.copyWith(classes: res.data['data'] ?? []);
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
    }
  }

  Future<bool> createClassRoom(Map<String, dynamic> data) async {
    try {
      await _dio.post(ApiConstants.adminClasses, data: data);
      await loadClasses();
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  Future<bool> assignClassTeacher(String classId, String teacherId) async {
    try {
      await _dio.post(
        '${ApiConstants.adminClasses}/assign-teacher',
        data: {'classId': classId, 'teacherId': teacherId},
      );
      await loadClasses();
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  Future<bool> createTeacher(Map<String, dynamic> data) async {
    try {
      await _dio.post(ApiConstants.adminTeachers, data: data);
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  // 4. Fees Management
  Future<void> loadFees({String? status, String? classId, String? search}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final overviewRes = await _dio.get(ApiConstants.adminFeesOverview);
      final query = <String, dynamic>{};
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (classId != null && classId.isNotEmpty) query['classId'] = classId;
      if (search != null && search.isNotEmpty) query['search'] = search;

      final recordsRes = await _dio.get(ApiConstants.adminFeesRecords, queryParameters: query);

      state = state.copyWith(
        isLoading: false,
        feesOverview: overviewRes.data['data'],
        feeRecords: recordsRes.data['data'] ?? [],
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.error?.toString());
    }
  }

  Future<bool> generateFeeInvoices(Map<String, dynamic> data) async {
    try {
      await _dio.post(ApiConstants.adminFeesGenerate, data: data);
      await loadFees();
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  Future<bool> recordFeePayment(String recordId, double amount, {String method = 'UPI'}) async {
    try {
      await _dio.post(
        '${ApiConstants.adminFeesRecords}/$recordId/pay',
        data: {'amount': amount, 'method': method},
      );
      await loadFees();
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  // 5. Attendance Management
  Future<void> loadAttendanceOverview({String? date}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final query = <String, dynamic>{};
      if (date != null) query['date'] = date;

      final res = await _dio.get(ApiConstants.adminAttendanceOverview, queryParameters: query);
      state = state.copyWith(
        isLoading: false,
        attendanceOverview: res.data['data'],
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.error?.toString());
    }
  }

  Future<int?> notifyAbsentParents({String? date}) async {
    try {
      final res = await _dio.post(
        ApiConstants.adminNotifyAbsent,
        data: date != null ? {'date': date} : {},
      );
      return res.data['data']?['notifiedCount'] ?? 0;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return null;
    }
  }

  // 6. Examination & Results
  Future<void> loadExamsOverview() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.get(ApiConstants.adminExamsOverview);
      state = state.copyWith(
        isLoading: false,
        examsOverview: res.data['data'],
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.error?.toString());
    }
  }

  Future<bool> publishExamResults({String? examTitle, String? examType, String? classId}) async {
    try {
      await _dio.post(
        ApiConstants.adminPublishExams,
        data: {
          if (examTitle != null) 'examTitle': examTitle,
          if (examType != null) 'examType': examType,
          if (classId != null) 'classId': classId,
        },
      );
      await loadExamsOverview();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  // 7. School Settings, Transport & Library
  Future<void> loadSchoolSettings() async {
    try {
      final res = await _dio.get(ApiConstants.adminSettings);
      state = state.copyWith(schoolSettings: res.data['data']);
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
    }
  }

  Future<bool> updateSchoolSettings(Map<String, dynamic> data) async {
    try {
      final res = await _dio.put(ApiConstants.adminSettings, data: data);
      state = state.copyWith(schoolSettings: res.data['data']);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.response?.data?['message'] ?? e.error?.toString());
      return false;
    }
  }

  // 8. Broadcast Notice
  Future<bool> sendBroadcast({
    required String title,
    required String message,
    required String targetRole, // 'ALL' | 'TEACHERS' | 'PARENTS'
  }) async {
    try {
      await _dio.post(
        ApiConstants.adminBroadcast,
        data: {
          'title': title,
          'message': message,
          'targetRole': targetRole,
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  // 9. Payroll
  Future<bool> generateSalarySlip({
    required String teacherId,
    required String month,
    required int year,
    required double basicSalary,
    double hra = 0,
    double da = 0,
    double specialAllowance = 0,
    double pfDeduction = 0,
    double taxDeduction = 0,
  }) async {
    try {
      await _dio.post(
        ApiConstants.adminSalarySlips,
        data: {
          'teacherId': teacherId,
          'month': month,
          'year': year,
          'basicSalary': basicSalary,
          'hra': hra,
          'da': da,
          'specialAllowance': specialAllowance,
          'pfDeduction': pfDeduction,
          'taxDeduction': taxDeduction,
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});
