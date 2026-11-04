import 'package:dio/dio.dart';

import '../../domain/models/facebook_api_exception.dart';

/// Maps Dio's transport failure types to the user-facing network taxonomy.
FacebookNetworkIssue facebookNetworkIssueFor(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => FacebookNetworkIssue.timeout,
    DioExceptionType.connectionError => FacebookNetworkIssue.connection,
    DioExceptionType.badCertificate => FacebookNetworkIssue.tls,
    DioExceptionType.cancel => FacebookNetworkIssue.cancelled,
    DioExceptionType.unknown ||
    DioExceptionType.badResponse => FacebookNetworkIssue.unknown,
  };
}
