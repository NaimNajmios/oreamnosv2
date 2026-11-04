import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/data/services/facebook_network_error.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';

DioException _error(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/me'),
  type: type,
);

void main() {
  test('maps Dio timeouts', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(
        facebookNetworkIssueFor(_error(type)),
        FacebookNetworkIssue.timeout,
      );
    }
  });

  test('maps connection, TLS, cancel and unknown', () {
    expect(
      facebookNetworkIssueFor(_error(DioExceptionType.connectionError)),
      FacebookNetworkIssue.connection,
    );
    expect(
      facebookNetworkIssueFor(_error(DioExceptionType.badCertificate)),
      FacebookNetworkIssue.tls,
    );
    expect(
      facebookNetworkIssueFor(_error(DioExceptionType.cancel)),
      FacebookNetworkIssue.cancelled,
    );
    expect(
      facebookNetworkIssueFor(_error(DioExceptionType.unknown)),
      FacebookNetworkIssue.unknown,
    );
  });

  test('friendly messages and transient flags', () {
    final timeout = FacebookApiException.fromGraph(
      null,
      null,
      isNetworkFailure: true,
      networkIssue: FacebookNetworkIssue.timeout,
    );
    expect(timeout.kind, FacebookApiErrorKind.network);
    expect(timeout.message, contains('took too long'));
    expect(timeout.isTransientNetwork, isTrue);

    final tls = FacebookApiException.fromGraph(
      null,
      null,
      isNetworkFailure: true,
      networkIssue: FacebookNetworkIssue.tls,
    );
    expect(tls.message, contains('Secure connection'));
    expect(tls.isTransientNetwork, isFalse);

    final cancelled = FacebookApiException.fromGraph(
      null,
      null,
      isNetworkFailure: true,
      networkIssue: FacebookNetworkIssue.cancelled,
    );
    expect(cancelled.isTransientNetwork, isFalse);
  });
}
