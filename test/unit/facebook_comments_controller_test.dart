import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oreamnos/core/network/api_client.dart';
import 'package:oreamnos/data/services/facebook_comments_service.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
import 'package:oreamnos/domain/models/facebook_comment.dart';
import 'package:oreamnos/ui/features/facebook/view_models/facebook_comments_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubComments extends FacebookCommentsService {
  _StubComments(this.pages, {this.error}) : super(ApiClient());

  final List<FacebookCommentPage> pages;
  final FacebookApiException? error;
  int listCalls = 0;
  final List<String> replies = [];
  final List<String> hidden = [];
  final List<String> deleted = [];

  @override
  Future<FacebookCommentPage> list({
    required String postId,
    required String token,
    String? after,
    int limit = 25,
  }) async {
    if (error != null) throw error!;
    final page = pages[listCalls.clamp(0, pages.length - 1)];
    listCalls++;
    return page;
  }

  @override
  Future<void> reply({
    required String commentId,
    required String token,
    required String message,
  }) async {
    replies.add('$commentId:$message');
  }

  @override
  Future<void> setHidden({
    required String commentId,
    required String token,
    required bool hidden,
  }) async {
    this.hidden.add('$commentId:$hidden');
  }

  @override
  Future<void> delete({
    required String commentId,
    required String token,
  }) async {
    deleted.add(commentId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService prefs;
  late _StubComments service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final raw = await SharedPreferences.getInstance();
    prefs = PreferencesService(
      prefs: raw,
      secureStorage: FlutterSecureStorage(),
    );
    await prefs.setFacebookPageToken('page-token');
    service = _StubComments([
      FacebookCommentPage(
        comments: const [
          FacebookComment(
            id: 'c1',
            message: 'First',
            authorName: 'A',
            canHide: true,
            canRemove: true,
          ),
        ],
        nextCursor: 'cursor-2',
      ),
      FacebookCommentPage(
        comments: const [
          FacebookComment(id: 'c1', message: 'First'),
          FacebookComment(id: 'c2', message: 'Second'),
        ],
      ),
    ]);
  });

  FacebookCommentsController controller() => FacebookCommentsController(
    postId: 'p1',
    service: service,
    preferences: prefs,
  );

  test('load then loadMore appends and deduplicates by id', () async {
    final c = controller();
    await c.load();
    expect(c.state.comments.map((e) => e.id), ['c1']);
    expect(c.state.nextCursor, 'cursor-2');

    await c.loadMore();
    expect(c.state.comments.map((e) => e.id), ['c1', 'c2']);
    expect(c.state.nextCursor, isNull);
    expect(c.state.hasMore, isFalse);
  });

  test('toggleHidden updates only after success', () async {
    final c = controller();
    await c.load();
    final error = await c.toggleHidden(c.state.comments.single);
    expect(error, isNull);
    expect(c.state.comments.single.isHidden, isTrue);
    expect(service.hidden, ['c1:true']);
  });

  test('delete removes the comment locally', () async {
    final c = controller();
    await c.load();
    final error = await c.delete(c.state.comments.single);
    expect(error, isNull);
    expect(c.state.comments, isEmpty);
    expect(service.deleted, ['c1']);
  });

  test('permission failure preserves the old list', () async {
    final failing = _StubComments(
      const [],
      error: const FacebookApiException(
        kind: FacebookApiErrorKind.permission,
        message: 'Missing pages_manage_engagement.',
      ),
    );
    final c = FacebookCommentsController(
      postId: 'p1',
      service: failing,
      preferences: prefs,
    );
    await c.load();
    expect(c.state.comments, isEmpty);
    expect(c.state.error, contains('pages_manage_engagement'));
  });

  test('no token returns a connect message', () async {
    await prefs.setFacebookPageToken('');
    final c = FacebookCommentsController(
      postId: 'p1',
      service: service,
      preferences: prefs,
    );
    await c.load();
    expect(c.state.error, 'Connect your Page first.');
    expect(service.listCalls, 0);
  });
}
