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
  final List<dynamic> syllabusLogs;
  final Map<String, dynamic>? syllabusOverview;
  final List<dynamic> availableClasses;
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
    this.syllabusLogs = const [],
    this.syllabusOverview,
    this.availableClasses = const [],
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
    List<dynamic>? syllabusLogs,
    Map<String, dynamic>? syllabusOverview,
    List<dynamic>? availableClasses,
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
      syllabusLogs: syllabusLogs ?? this.syllabusLogs,
      syllabusOverview: syllabusOverview ?? this.syllabusOverview,
      availableClasses: availableClasses ?? this.availableClasses,
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
    int maxMarks = 20,
    String instructions = '',
    List<Map<String, dynamic>> attachments = const [],
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
          'maxMarks': maxMarks,
          'instructions': instructions,
          'attachments': attachments,
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<List<dynamic>> fetchClassHomework(String classId, {String? subject}) async {
    try {
      final res = await _dio.get(
        ApiConstants.classHomework(classId),
        queryParameters: {
          if (subject != null && subject.isNotEmpty) 'subject': subject,
        },
      );
      return res.data['data'] as List<dynamic>? ?? [];
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchHomeworkSubmissions(String homeworkId) async {
    try {
      final res = await _dio.get(ApiConstants.homeworkSubmissions(homeworkId));
      return res.data['data'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return null;
    }
  }

  Future<bool> gradeHomeworkSubmission({
    required String homeworkId,
    required String studentId,
    required double marksObtained,
    String feedback = '',
    String status = 'GRADED',
  }) async {
    try {
      await _dio.post(
        ApiConstants.gradeHomework(homeworkId, studentId),
        data: {
          'marksObtained': marksObtained,
          'feedback': feedback,
          'status': status,
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<bool> deleteHomework(String homeworkId) async {
    try {
      await _dio.delete('${ApiConstants.homework}/$homeworkId');
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

  Future<List<dynamic>> fetchAvailableClasses() async {
    try {
      final res = await _dio.get(ApiConstants.teacherClasses);
      final classes = res.data['data'] as List<dynamic>? ?? [];
      state = state.copyWith(availableClasses: classes);
      return classes;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchSyllabusOverview({
    String? classId,
    String? subject,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.teacherSyllabusOverview,
        queryParameters: {
          if (classId != null && classId.isNotEmpty) 'classId': classId,
          if (subject != null && subject.isNotEmpty) 'subject': subject,
        },
      );
      final data = res.data['data'] as Map<String, dynamic>?;
      state = state.copyWith(syllabusOverview: data);
      return data;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return null;
    }
  }

  Future<List<dynamic>> fetchSyllabusLogs({
    String? classId,
    String? subject,
    String? date,
    String? status,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.teacherSyllabusLogs,
        queryParameters: {
          if (classId != null && classId.isNotEmpty) 'classId': classId,
          if (subject != null && subject.isNotEmpty) 'subject': subject,
          if (date != null && date.isNotEmpty) 'date': date,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final list = res.data['data'] as List<dynamic>? ?? [];
      state = state.copyWith(syllabusLogs: list);
      return list;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return [];
    }
  }

  Future<bool> createDailySyllabusLog({
    required String classId,
    required String subject,
    required String date,
    required String chapter,
    required String topic,
    required String dailyTarget,
    String status = 'COMPLETED',
    double completionPercentage = 0,
    int durationMinutes = 45,
    String nextClassTarget = '',
    List<Map<String, dynamic>> studyMaterials = const [],
    String notes = '',
  }) async {
    try {
      await _dio.post(
        ApiConstants.teacherSyllabusLogs,
        data: {
          'classId': classId,
          'subject': subject,
          'date': date,
          'chapter': chapter,
          'topic': topic,
          'dailyTarget': dailyTarget,
          'status': status,
          'completionPercentage': completionPercentage.round(),
          'durationMinutes': durationMinutes,
          'nextClassTarget': nextClassTarget,
          'studyMaterials': studyMaterials,
          'notes': notes,
        },
      );
      await fetchSyllabusLogs(classId: classId, subject: subject);
      await fetchSyllabusOverview(classId: classId, subject: subject);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<bool> updateDailySyllabusLog({
    required String logId,
    required Map<String, dynamic> data,
    String? classId,
    String? subject,
  }) async {
    try {
      await _dio.put(
        '${ApiConstants.teacherSyllabusLogs}/$logId',
        data: data,
      );
      await fetchSyllabusLogs(classId: classId, subject: subject);
      await fetchSyllabusOverview(classId: classId, subject: subject);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<bool> deleteDailySyllabusLog({
    required String logId,
    String? classId,
    String? subject,
  }) async {
    try {
      await _dio.delete('${ApiConstants.teacherSyllabusLogs}/$logId');
      await fetchSyllabusLogs(classId: classId, subject: subject);
      await fetchSyllabusOverview(classId: classId, subject: subject);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  // ================= Parent Communication Suite =================

  Future<List<dynamic>> fetchConversation(String otherUserId, {String? studentId}) async {
    try {
      final res = await _dio.get(
        ApiConstants.conversation(otherUserId),
        queryParameters: {
          if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
        },
      );
      return res.data['data'] as List<dynamic>? ?? [];
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return [];
    }
  }

  Future<bool> sendDirectMessage({
    required String recipientId,
    String? studentId,
    required String message,
    String type = 'INDIVIDUAL_MESSAGE',
    String title = '',
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      await _dio.post(
        ApiConstants.directMessages,
        data: {
          'recipientId': recipientId,
          if (studentId != null) 'studentId': studentId,
          'message': message,
          'type': type,
          'title': title,
          'attachments': attachments,
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<List<dynamic>> fetchClassAnnouncements(String classId) async {
    try {
      final res = await _dio.get(ApiConstants.classAnnouncementsList(classId));
      return res.data['data'] as List<dynamic>? ?? [];
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return [];
    }
  }

  Future<bool> sendClassAnnouncement({
    required String classId,
    required String title,
    required String message,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      await _dio.post(
        ApiConstants.classAnnouncements,
        data: {
          'classId': classId,
          'title': title,
          'message': message,
          'attachments': attachments,
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<bool> shareStudentProgress({
    required String studentId,
    String teacherRemarks = '',
    String overallGrade = 'A',
  }) async {
    try {
      await _dio.post(
        ApiConstants.shareProgress,
        data: {
          'studentId': studentId,
          'teacherRemarks': teacherRemarks,
          'overallGrade': overallGrade,
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<List<dynamic>> fetchMeetings() async {
    try {
      final res = await _dio.get(ApiConstants.meetings);
      return res.data['data'] as List<dynamic>? ?? [];
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return [];
    }
  }

  Future<bool> scheduleMeeting({
    required String parentId,
    required String studentId,
    required String classId,
    required String title,
    String agenda = '',
    required String meetingDate,
    required String timeSlot,
    String mode = 'IN_PERSON_AT_SCHOOL',
    String meetLinkOrRoom = 'Room 204',
  }) async {
    try {
      await _dio.post(
        ApiConstants.meetings,
        data: {
          'parentId': parentId,
          'studentId': studentId,
          'classId': classId,
          'title': title,
          'agenda': agenda,
          'meetingDate': meetingDate,
          'timeSlot': timeSlot,
          'mode': mode,
          'meetLinkOrRoom': meetLinkOrRoom,
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<bool> updateMeetingStatus({
    required String meetingId,
    required String status,
    String? teacherNotes,
  }) async {
    try {
      await _dio.patch(
        ApiConstants.updateMeeting(meetingId),
        data: {
          'status': status,
          if (teacherNotes != null) 'teacherNotes': teacherNotes,
        },
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return false;
    }
  }

  Future<List<dynamic>> fetchParentQueries() async {
    try {
      final res = await _dio.get(ApiConstants.parentQueries);
      return res.data['data'] as List<dynamic>? ?? [];
    } on DioException catch (e) {
      state = state.copyWith(errorMessage: e.error?.toString());
      return [];
    }
  }

  Future<bool> replyToParentQuery({
    required String queryId,
    required String replyMessage,
    String resolutionStatus = 'RESOLVED',
  }) async {
    try {
      await _dio.post(
        ApiConstants.replyParentQuery(queryId),
        data: {
          'replyMessage': replyMessage,
          'resolutionStatus': resolutionStatus,
        },
      );
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

