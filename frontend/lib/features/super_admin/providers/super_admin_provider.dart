import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/super_admin_models.dart';

class SuperAdminState {
  final bool isLoading;
  final Map<String, dynamic>? dashboardStats;
  final List<SuperAdminSchoolModel> schools;
  final List<SuperAdminUserModel> admins;
  final List<SuperAdminBusModel> buses;
  final List<SuperAdminBiometricModel> biometricDevices;
  final Map<String, dynamic>? financials;
  final List<dynamic> broadcasts;
  final String? errorMessage;
  final String? successMessage;

  SuperAdminState({
    this.isLoading = false,
    this.dashboardStats,
    this.schools = const [],
    this.admins = const [],
    this.buses = const [],
    this.biometricDevices = const [],
    this.financials,
    this.broadcasts = const [],
    this.errorMessage,
    this.successMessage,
  });

  SuperAdminState copyWith({
    bool? isLoading,
    Map<String, dynamic>? dashboardStats,
    List<SuperAdminSchoolModel>? schools,
    List<SuperAdminUserModel>? admins,
    List<SuperAdminBusModel>? buses,
    List<SuperAdminBiometricModel>? biometricDevices,
    Map<String, dynamic>? financials,
    List<dynamic>? broadcasts,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SuperAdminState(
      isLoading: isLoading ?? this.isLoading,
      dashboardStats: dashboardStats ?? this.dashboardStats,
      schools: schools ?? this.schools,
      admins: admins ?? this.admins,
      buses: buses ?? this.buses,
      biometricDevices: biometricDevices ?? this.biometricDevices,
      financials: financials ?? this.financials,
      broadcasts: broadcasts ?? this.broadcasts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class SuperAdminNotifier extends StateNotifier<SuperAdminState> {
  SuperAdminNotifier() : super(SuperAdminState());

  Dio get _dio => DioClient.instance;

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.get(ApiConstants.superAdminDashboard);
      if (res.data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          dashboardStats: res.data['data'],
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: res.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  List<dynamic> _extractList(dynamic raw, String key) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is Map && raw[key] is List) return raw[key] as List;
    return [];
  }

  Future<void> loadSchools() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.get(ApiConstants.superAdminSchools);
      if (res.data['success'] == true) {
        final raw = res.data['data'];
        final list = _extractList(raw, 'schools')
            .map((item) => SuperAdminSchoolModel.fromJson(item))
            .toList();
        state = state.copyWith(isLoading: false, schools: list);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: res.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadAdmins() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.get(ApiConstants.superAdminAdmins);
      if (res.data['success'] == true) {
        final raw = res.data['data'];
        final list = _extractList(raw, 'admins')
            .map((item) => SuperAdminUserModel.fromJson(item))
            .toList();
        state = state.copyWith(isLoading: false, admins: list);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: res.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadBuses() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.get(ApiConstants.superAdminBuses);
      if (res.data['success'] == true) {
        final raw = res.data['data'];
        final list = _extractList(raw, 'buses')
            .map((item) => SuperAdminBusModel.fromJson(item))
            .toList();
        state = state.copyWith(isLoading: false, buses: list);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: res.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadBiometricDevices() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.get(ApiConstants.superAdminBiometricDevices);
      if (res.data['success'] == true) {
        final raw = res.data['data'];
        final list = _extractList(raw, 'devices')
            .map((item) => SuperAdminBiometricModel.fromJson(item))
            .toList();
        state = state.copyWith(isLoading: false, biometricDevices: list);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: res.data['message']);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createSchool(Map<String, dynamic> schoolData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.post(ApiConstants.superAdminSchools, data: schoolData);
      if (res.data['success'] == true) {
        await loadSchools();
        await loadDashboard();
        state = state.copyWith(isLoading: false, successMessage: 'School registered successfully!');
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: res.data['message']);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateSchoolStatus(String schoolId, String status) async {
    try {
      final res = await _dio.patch(
        ApiConstants.superAdminSchoolStatus(schoolId),
        data: {'status': status},
      );
      if (res.data['success'] == true) {
        await loadSchools();
        await loadDashboard();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateSchoolModulesAndLimits({
    required String schoolId,
    required Map<String, dynamic> modules,
    required Map<String, dynamic> limits,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.patch(ApiConstants.superAdminSchoolModules(schoolId), data: {'modules': modules});
      await _dio.patch(ApiConstants.superAdminSchoolLimits(schoolId), data: {'limits': limits});
      await loadSchools();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Institution modules & limits saved successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> createAdmin(Map<String, dynamic> adminData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.post(ApiConstants.superAdminAdmins, data: adminData);
      if (res.data['success'] == true) {
        await loadAdmins();
        await loadDashboard();
        state = state.copyWith(isLoading: false, successMessage: 'Admin created successfully!');
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: res.data['message']);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateAdminStatus(String adminId, bool isSuspended) async {
    try {
      final res = await _dio.patch(
        ApiConstants.superAdminAdminStatus(adminId),
        data: {
          'isSuspended': isSuspended,
          'statusReason': isSuspended ? 'Suspended by Super Admin' : 'Access restored',
        },
      );
      if (res.data['success'] == true) {
        await loadAdmins();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateAdminPermissions(String adminId, Map<String, dynamic> permissions) async {
    try {
      final res = await _dio.patch(
        ApiConstants.superAdminAdminPermissions(adminId),
        data: {'permissions': permissions},
      );
      if (res.data['success'] == true) {
        await loadAdmins();
        state = state.copyWith(successMessage: 'Permissions updated successfully!');
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> simulateBusMovement(String busId) async {
    try {
      final lat = 28.6139 + (DateTime.now().millisecond % 50) * 0.001;
      final lng = 77.2090 + (DateTime.now().millisecond % 50) * 0.001;
      final speed = 25 + (DateTime.now().second % 35);

      final res = await _dio.patch(
        ApiConstants.superAdminSimulateBus(busId),
        data: {'latitude': lat, 'longitude': lng, 'speedKmph': speed},
      );
      if (res.data['success'] == true) {
        await loadBuses();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> syncBiometric(String deviceId) async {
    try {
      final res = await _dio.post(ApiConstants.superAdminSyncBiometric(deviceId));
      if (res.data['success'] == true) {
        await loadBiometricDevices();
        state = state.copyWith(successMessage: 'Biometric device synced successfully!');
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> sendBroadcast({
    required String title,
    required String message,
    required String target,
    String? schoolId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _dio.post(
        ApiConstants.superAdminNotificationsBroadcast,
        data: {
          'title': title,
          'message': message,
          'target': target,
          'schoolId': schoolId,
        },
      );
      if (res.data['success'] == true) {
        state = state.copyWith(isLoading: false, successMessage: 'Broadcast transmitted!');
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: res.data['message']);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final superAdminProvider = StateNotifierProvider<SuperAdminNotifier, SuperAdminState>(
  (ref) => SuperAdminNotifier(),
);
