abstract final class HomeTable {
  static const posts = 'posts';
  static const profiles = 'profiles';
  static const postComments = 'post_comments';
}

abstract final class HomeStorage {
  static const postImagesBucket = 'post_images';
}

abstract final class PostCols {
  static const id = 'id';
  static const userId = 'user_id';
  static const postImage = 'post_image';
  static const postContent = 'post_content';
  static const likes = 'likes';
  static const createdAt = 'created_at';
}

abstract final class PostCommentCols {
  static const id = 'id';
  static const postId = 'post_id';
  static const userId = 'user_id';
  static const comment = 'comment';
}

abstract final class ProfileCols {
  static const id = 'id';
  static const username = 'username';
  static const avatarUrl = 'avatar_url';
}
