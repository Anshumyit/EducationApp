import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class ParentState {
  final bool isLoading;
  final List<dynamic> children;
  final int selectedChildIndex;
  final Map<String, dynamic>? childDashboard;
  final List<dynamic> homeworkList;
  final List<dynamic> examResults;
  final Map<String, dynamic>? feeData;
  final List<dynamic> holidays;
  final List<dynamic> myLeaves;
  final String? errorMessage;

  ParentState({
    this.isLoading = false,
    this.children = const [],
    this.selectedChildIndex = 0,
    this.childDashboard,
    this.homeworkList = const [],
    this.examResults = const [],
    this.feeData,
    this.holidays = const [],
    this.myLeaves = const [],
    this.errorMessage,
  });

  dynamic get currentChild =>
      children.isNotEmpty && selectedChildIndex < children.length ? children[selectedChildIndex] : null;

  ParentState copyWith({
    bool? isLoading,
    List<dynamic>? children,
    int? selectedChildIndex,
    Map<String, dynamic>? childDashboard,
    List<dynamic>? homeworkList,
    List<dynamic>? examResults,
    Map<String, dynamic>? feeData,
    List<dynamic>? holidays,
    List<dynamic>? myLeaves,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ParentState(
      isLoading: isLoading ?? this.isLoading,
      children: children ?? this.children,
      selectedChildIndex: selectedChildIndex ?? this.selectedChildIndex,
      childDashboard: childDashboard ?? this.childDashboard,
      homeworkList: homeworkList ?? this.homeworkList,
      examResults: examResults ?? this.examResults,
      feeData: feeData ?? this.feeData,
      holidays: holidays ?? this.holidays,
      myLeaves: myLeaves ?? this.myLeaves,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ParentNotifier extends StateNotifier<ParentState> {
  ParentNotifier() : super(ParentState());

  final Dio _dio = DioClient.instance;

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final childrenRes = await _dio.get(ApiConstants.parentChildren);
      final children = childrenRes.data['data'] as List<dynamic>? ?? [];

      state = state.copyWith(children: children);

      if (children.isNotEmpty) {
        final child = children[state.selectedChildIndex];
        await loadChildDetails(child);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.error?.toString());
    }
  }

  void selectChild(int index) {
    if (index >= 0 && index < state.children.length) {
      state = state.copyWith(selectedChildIndex: index);
      loadChildDetails(state.children[index]);
    }
  }

  Future<void> loadChildDetails(dynamic child) async {
    try {
      final studentId = child['_id'];
      final classId = child['classId'] is Map ? child['classId']['_id'] : child['classId'];

      final dashboardRes = await _dio.get('${ApiConstants.parentDashboard}/$studentId/dashboard');
      final homeworkRes = await _dio.get('${ApiConstants.homework}/class/$classId');
      final examsRes = await _dio.get('${ApiConstants.studentExams}/$studentId');
      final feesRes = await _dio.get('${ApiConstants.studentFees}/$studentId');
      final holidaysRes = await _dio.get(ApiConstants.holidays);
      final leavesRes = await _dio.get(ApiConstants.myLeaves);

      state = state.copyWith(
        isLoading: false,
        childDashboard: dashboardRes.data['data'],
        homeworkList: homeworkRes.data['data'] ?? [],
        examResults: examsRes.data['data'] ?? [],
        feeData: feesRes.data['data'],
        holidays: holidaysRes.data['data'] ?? [],
        myLeaves: leavesRes.data['data'] ?? [],
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.error?.toString());
    }
  }

  Future<bool> submitLeaveRequest({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      await _dio.post(
        ApiConstants.submitLeave,
        data: {
          'studentId': studentId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'reason': reason,
        },
      );
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<bool> payFee(String feeRecordId, double amount) async {
    try {
      await _dio.post(
        '${ApiConstants.payFee}/$feeRecordId',
        data: {'amount': amount},
      );
      await loadDashboard();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }
}

final parentProvider = StateNotifierProvider<ParentNotifier, ParentState>((ref) {
  return ParentNotifier();
});
