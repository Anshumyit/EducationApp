import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/storage_service.dart';
import '../domain/models/user_model.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? token;
  final String? errorMessage;
  final String? pendingAdminUserId;
  final String? lastGeneratedOtp;
  final bool isPendingApproval;

  AuthState({
    this.isLoading = false,
    this.user,
    this.token,
    this.errorMessage,
    this.pendingAdminUserId,
    this.lastGeneratedOtp,
    this.isPendingApproval = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? token,
    String? errorMessage,
    String? pendingAdminUserId,
    String? lastGeneratedOtp,
    bool? isPendingApproval,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingAdminUserId: pendingAdminUserId ?? this.pendingAdminUserId,
      lastGeneratedOtp: lastGeneratedOtp ?? this.lastGeneratedOtp,
      isPendingApproval: isPendingApproval ?? this.isPendingApproval,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    checkSession();
  }

  final Dio _dio = DioClient.instance;

  Future<void> checkSession() async {
    final token = StorageService.getToken();
    final userMap = StorageService.getUser();

    if (token != null && userMap != null) {
      state = state.copyWith(
        token: token,
        user: UserModel.fromJson(userMap),
      );
    }
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, clearError: true, isPendingApproval: false);

    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'identifier': identifier, 'password': password},
      );

      final data = response.data['data'];
      final token = data['token'];
      final user = UserModel.fromJson(data['user']);

      await StorageService.saveToken(token);
      await StorageService.saveUser(user.toJson());

      state = state.copyWith(
        isLoading: false,
        token: token,
        user: user,
      );
      return true;
    } on DioException catch (e) {
      final message = e.error?.toString() ?? 'Login failed. Please check your credentials.';
      final isPending = message.contains('PENDING approval');

      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
        isPendingApproval: isPending,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> registerAdmin({
    required String name,
    required String? email,
    required String? phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _dio.post(
        ApiConstants.registerAdmin,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      final data = response.data['data'];
      state = state.copyWith(
        isLoading: false,
        pendingAdminUserId: data['userId'],
        lastGeneratedOtp: data['otpCode'],
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.error?.toString() ?? 'Admin registration failed',
      );
      return false;
    }
  }

  Future<bool> verifyAdminOtp(String otp) async {
    if (state.pendingAdminUserId == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _dio.post(
        ApiConstants.verifyOtp,
        data: {
          'userId': state.pendingAdminUserId,
          'otp': otp,
        },
      );

      final data = response.data['data'];
      final token = data['token'];
      final user = UserModel.fromJson(data['user']);

      await StorageService.saveToken(token);
      await StorageService.saveUser(user.toJson());

      state = state.copyWith(
        isLoading: false,
        token: token,
        user: user,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.error?.toString() ?? 'OTP verification failed',
      );
      return false;
    }
  }

  Future<bool> registerTeacher({
    required String name,
    required String? email,
    required String? phone,
    required String password,
    required List<String> subjects,
    required String qualification,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _dio.post(
        ApiConstants.registerTeacher,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'subjects': subjects,
          'qualification': qualification,
        },
      );

      state = state.copyWith(isLoading: false, isPendingApproval: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.error?.toString() ?? 'Teacher registration failed',
      );
      return false;
    }
  }

  Future<bool> registerParent({
    required String name,
    required String? email,
    required String? phone,
    required String password,
    required String address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _dio.post(
        ApiConstants.registerParent,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'address': address,
        },
      );

      state = state.copyWith(isLoading: false, isPendingApproval: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.error?.toString() ?? 'Parent registration failed',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clearAll();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
