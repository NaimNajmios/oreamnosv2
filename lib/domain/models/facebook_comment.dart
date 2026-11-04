/// One Graph comment on a Page post.
class FacebookComment {
  const FacebookComment({
    required this.id,
    required this.message,
    this.authorId = '',
    this.authorName = 'Facebook user',
    this.createdAt,
    this.likeCount = 0,
    this.replyCount = 0,
    this.isHidden = false,
    this.canHide = false,
    this.canRemove = false,
    this.permalinkUrl = '',
  });

  final String id;
  final String message;
  final String authorId;
  final String authorName;
  final DateTime? createdAt;
  final int likeCount;
  final int replyCount;
  final bool isHidden;
  final bool canHide;
  final bool canRemove;
  final String permalinkUrl;

  FacebookComment copyWith({bool? isHidden}) {
    return FacebookComment(
      id: id,
      message: message,
      authorId: authorId,
      authorName: authorName,
      createdAt: createdAt,
      likeCount: likeCount,
      replyCount: replyCount,
      isHidden: isHidden ?? this.isHidden,
      canHide: canHide,
      canRemove: canRemove,
      permalinkUrl: permalinkUrl,
    );
  }

  @override
  bool operator ==(Object other) => other is FacebookComment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// One page of comments plus the cursor for the next page.
class FacebookCommentPage {
  const FacebookCommentPage({this.comments = const [], this.nextCursor});

  final List<FacebookComment> comments;
  final String? nextCursor;
}
