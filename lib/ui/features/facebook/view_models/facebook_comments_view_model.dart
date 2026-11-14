import 'package:flutter/foundation.dart';

import 'package:oreamnos/core/di/injection.dart';
import 'package:oreamnos/data/services/facebook_comments_service.dart';
import 'package:oreamnos/data/services/facebook_expiry_signal.dart';
import 'package:oreamnos/data/services/preferences_service.dart';
import 'package:oreamnos/domain/models/facebook_api_exception.dart';
import 'package:oreamnos/domain/models/facebook_comment.dart';

class FacebookCommentsState {
  const FacebookCommentsState({
    this.comments = const [],
    this.loading = false,
    this.loadingMore = false,
    this.busy = false,
    this.nextCursor,
    this.error,
    this.needsReconnect = false,
    this.permissionDenied = false,
    this.replies = const {},
    this.loadingReplyIds = const {},
    this.expandedReplyIds = const {},
    this.replyErrors = const {},
  });

  final List<FacebookComment> comments;
  final bool loading;
  final bool loadingMore;
  final bool busy;
  final String? nextCursor;
  final String? error;
  final bool needsReconnect;
  final bool permissionDenied;
  final Map<String, List<FacebookComment>> replies;
  final Set<String> loadingReplyIds;
  final Set<String> expandedReplyIds;
  final Map<String, String> replyErrors;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  FacebookCommentsState copyWith({
    List<FacebookComment>? comments,
    bool? loading,
    bool? loadingMore,
    bool? busy,
    Object? nextCursor = _sentinel,
    Object? error = _sentinel,
    bool? needsReconnect,
    bool? permissionDenied,
    Map<String, List<FacebookComment>>? replies,
    Set<String>? loadingReplyIds,
    Set<String>? expandedReplyIds,
    Map<String, String>? replyErrors,
  }) {
    return FacebookCommentsState(
      comments: comments ?? this.comments,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      busy: busy ?? this.busy,
      nextCursor: nextCursor == _sentinel
          ? this.nextCursor
          : nextCursor as String?,
      error: error == _sentinel ? this.error : error as String?,
      needsReconnect: needsReconnect ?? this.needsReconnect,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      replies: replies ?? this.replies,
      loadingReplyIds: loadingReplyIds ?? this.loadingReplyIds,
      expandedReplyIds: expandedReplyIds ?? this.expandedReplyIds,
      replyErrors: replyErrors ?? this.replyErrors,
    );
  }

  static const Object _sentinel = Object();
}

/// Screen-scoped comments controller. Loads pages, deduplicates by id, and
/// applies reply/hide/delete actions only after Graph success.
class FacebookCommentsController extends ChangeNotifier {
  FacebookCommentsController({
    required this.postId,
    FacebookCommentsService? service,
    PreferencesService? preferences,
  }) : _service = service ?? getIt<FacebookCommentsService>(),
       _preferences = preferences ?? getIt<PreferencesService>();

  final String postId;
  final FacebookCommentsService _service;
  final PreferencesService _preferences;

  FacebookCommentsState _state = const FacebookCommentsState();
  FacebookCommentsState get state => _state;

  Future<String?> _token() async {
    final token = await _preferences.getFacebookPageToken() ?? '';
    return token.isEmpty ? null : token;
  }

  Future<void> load() async {
    if (_state.loading) return;
    _state = _state.copyWith(loading: true, error: null);
    notifyListeners();
    final token = await _token();
    if (token == null) {
      _state = _state.copyWith(
        loading: false,
        error: 'Connect your Page first.',
      );
      notifyListeners();
      return;
    }
    try {
      final page = await _service.list(postId: postId, token: token);
      _state = _state.copyWith(
        loading: false,
        comments: page.comments,
        nextCursor: page.nextCursor,
        error: null,
        needsReconnect: false,
        permissionDenied: false,
      );
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) FacebookExpirySignal.report();
      _state = _state.copyWith(
        loading: false,
        error: e.message,
        needsReconnect: e.needsReconnect,
        permissionDenied: e.kind == FacebookApiErrorKind.permission,
      );
    } catch (_) {
      _state = _state.copyWith(
        loading: false,
        error: 'Could not load comments. Try again.',
      );
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_state.loadingMore || !_state.hasMore) return;
    _state = _state.copyWith(loadingMore: true, error: null);
    notifyListeners();
    final token = await _token();
    if (token == null) {
      _state = _state.copyWith(
        loadingMore: false,
        error: 'Connect your Page first.',
      );
      notifyListeners();
      return;
    }
    try {
      final page = await _service.list(
        postId: postId,
        token: token,
        after: _state.nextCursor,
      );
      final seen = _state.comments.map((c) => c.id).toSet();
      final merged = [
        ..._state.comments,
        ...page.comments.where((c) => seen.add(c.id)),
      ];
      _state = _state.copyWith(
        loadingMore: false,
        comments: merged,
        nextCursor: page.nextCursor,
        error: null,
        permissionDenied: false,
      );
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) FacebookExpirySignal.report();
      _state = _state.copyWith(
        loadingMore: false,
        error: e.message,
        needsReconnect: e.needsReconnect,
        permissionDenied: e.kind == FacebookApiErrorKind.permission,
      );
    } catch (_) {
      _state = _state.copyWith(
        loadingMore: false,
        error: 'Could not load more comments.',
      );
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  /// Expands or collapses the replies under [comment]. Replies are fetched
  /// lazily once and kept until the comment is replied to again.
  Future<void> toggleReplies(FacebookComment comment) async {
    final id = comment.id;
    if (_state.expandedReplyIds.contains(id)) {
      _state = _state.copyWith(
        expandedReplyIds: {..._state.expandedReplyIds}..remove(id),
      );
      notifyListeners();
      return;
    }
    _state = _state.copyWith(
      expandedReplyIds: {..._state.expandedReplyIds, id},
    );
    notifyListeners();
    if (!_state.replies.containsKey(id)) {
      await _loadReplies(id);
    }
  }

  Future<void> retryReplies(FacebookComment comment) =>
      _loadReplies(comment.id);

  Future<void> _loadReplies(String commentId) async {
    if (_state.loadingReplyIds.contains(commentId)) return;
    final token = await _token();
    if (token == null) {
      _state = _state.copyWith(
        replyErrors: {
          ..._state.replyErrors,
          commentId: 'Connect your Page first.',
        },
      );
      notifyListeners();
      return;
    }
    _state = _state.copyWith(
      loadingReplyIds: {..._state.loadingReplyIds, commentId},
      replyErrors: {..._state.replyErrors}..remove(commentId),
    );
    notifyListeners();
    try {
      final page = await _service.fetchReplies(
        commentId: commentId,
        token: token,
      );
      _state = _state.copyWith(
        replies: {..._state.replies, commentId: page.comments},
        loadingReplyIds: {..._state.loadingReplyIds}..remove(commentId),
      );
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) FacebookExpirySignal.report();
      _state = _state.copyWith(
        loadingReplyIds: {..._state.loadingReplyIds}..remove(commentId),
        replyErrors: {..._state.replyErrors, commentId: e.message},
        needsReconnect: e.needsReconnect,
      );
    } catch (_) {
      _state = _state.copyWith(
        loadingReplyIds: {..._state.loadingReplyIds}..remove(commentId),
        replyErrors: {
          ..._state.replyErrors,
          commentId: 'Could not load replies. Try again.',
        },
      );
    }
    notifyListeners();
  }

  Future<String?> reply(FacebookComment comment, String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return 'Write a reply first.';
    final token = await _token();
    if (token == null) return 'Connect your Page first.';
    try {
      await _service.reply(
        commentId: comment.id,
        token: token,
        message: trimmed,
      );
      final wasExpanded = _state.expandedReplyIds.contains(comment.id);
      _state = _state.copyWith(
        replies: {..._state.replies}..remove(comment.id),
      );
      await load();
      if (wasExpanded) await _loadReplies(comment.id);
      return null;
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) FacebookExpirySignal.report();
      _state = _state.copyWith(needsReconnect: e.needsReconnect);
      notifyListeners();
      return e.message;
    } catch (_) {
      return 'Could not post the reply. Try again.';
    }
  }

  Future<String?> toggleHidden(FacebookComment comment) async {
    final token = await _token();
    if (token == null) return 'Connect your Page first.';
    final hidden = !comment.isHidden;
    try {
      await _service.setHidden(
        commentId: comment.id,
        token: token,
        hidden: hidden,
      );
      _state = _state.copyWith(
        comments: [
          for (final item in _state.comments)
            item.id == comment.id ? item.copyWith(isHidden: hidden) : item,
        ],
      );
      notifyListeners();
      return null;
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) FacebookExpirySignal.report();
      _state = _state.copyWith(needsReconnect: e.needsReconnect);
      notifyListeners();
      return e.message;
    } catch (_) {
      return 'Could not update the comment. Try again.';
    }
  }

  Future<String?> delete(FacebookComment comment) async {
    final token = await _token();
    if (token == null) return 'Connect your Page first.';
    try {
      await _service.delete(commentId: comment.id, token: token);
      _state = _state.copyWith(
        comments: _state.comments.where((c) => c.id != comment.id).toList(),
      );
      notifyListeners();
      return null;
    } on FacebookApiException catch (e) {
      if (e.needsReconnect) FacebookExpirySignal.report();
      _state = _state.copyWith(needsReconnect: e.needsReconnect);
      notifyListeners();
      return e.message;
    } catch (_) {
      return 'Could not delete the comment. Try again.';
    }
  }
}
