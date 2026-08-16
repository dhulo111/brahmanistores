import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

const bool useProduction=false; // Change to true to use the live backend

const String localBaseUrl = 'http://10.87.225.137:3000/api';
const String productionBaseUrl = 'https://brahmanistores.vercel.app/api';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: useProduction ? productionBaseUrl : localBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    responseType: ResponseType.json,
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = Hive.box('auth').get('token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ));

  return dio;
});
