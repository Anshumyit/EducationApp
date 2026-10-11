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
  final String? errorMessage;

  AdminState({
    this.isLoading = false,
    this.stats,
    this.teachers = const [],
    this.pendingApprovals = const [],
    this.salarySlips = const [],
    this.errorMessage,
  });

  AdminState copyWith({
    bool? isLoading,
    Map<String, dynamic>? stats,
    List<dynamic>? teachers,
    List<dynamic>? pendingApprovals,
    List<dynamic>? salarySlips,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      teachers: teachers ?? this.teachers,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      salarySlips: salarySlips ?? this.salarySlips,
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
      final statsRes = await _dio.get(ApiConstants.adminStats);
      final teachersRes = await _dio.get(ApiConstants.adminTeachers);
      final approvalsRes = await _dio.get(ApiConstants.adminApprovals);

      state = state.copyWith(
        isLoading: false,
        stats: statsRes.data['data'],
        teachers: teachersRes.data['data'] ?? [],
        pendingApprovals: approvalsRes.data['data'] ?? [],
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.error?.toString());
    }
  }

  Future<bool> updateApprovalStatus(String userId, String status) async {
    try {
      await _dio.patch(
        '${ApiConstants.adminApprovals}/$userId',
        data: {'status': status},
      );

      // Refresh approvals & stats
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

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
