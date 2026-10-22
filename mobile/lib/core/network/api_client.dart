import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Singleton API Client for Trueqer.
/// Adheres strictly to the "Dumb Client" architecture:
/// All mutations and business queries go through the Serverless API Gateway.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() => _instance;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Firebase OAuth2 / ID Token
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final token = await user.getIdToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
          } catch (e) {
            debugPrint('[ApiClient] Error fetching auth token: $e');
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          debugPrint(
            '[ApiClient] Error [${error.response?.statusCode}]: ${error.response?.data}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  static String _getBaseUrl() {
    if (kReleaseMode) {
      return 'https://us-central1-trueqer-app.cloudfunctions.net/api';
    }

    // In debug mode, default to local Prism Mock Server or local emulator:
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:4010'; // Android emulator to host machine
    } else {
      return 'http://127.0.0.1:4010'; // iOS simulator / Desktop / Web
    }
  }
}
