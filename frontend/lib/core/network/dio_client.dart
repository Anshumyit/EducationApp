import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/storage_service.dart';

class DioClient {
  static Dio? _dioInstance;

  static Dio get instance {
    if (_dioInstance != null) return _dioInstance!;

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Extract backend message if available
          String errorMessage = 'Network error. Please try again.';
          if (error.response?.data != null && error.response?.data is Map) {
            final data = error.response!.data as Map;
            if (data['message'] != null) {
              errorMessage = data['message'].toString();
            }
          }
          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: errorMessage,
              message: errorMessage,
            ),
          );
        },
      ),
    );

    _dioInstance = dio;
    return _dioInstance!;
  }
}
