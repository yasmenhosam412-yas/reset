abstract final class HomeTable {
  static const posts = 'posts';
  static const profiles = 'profiles';
  static const postComments = 'post_comments';
  static const friendRequests = 'friend_requests';
  static const gameChallenges = 'game_challenges';
  static const penaltyShootoutSessions = 'penalty_shootout_sessions';
  static const penaltyRoundPicks = 'penalty_round_picks';
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

abstract final class FriendRequestCols {
  static const id = 'id';
  static const fromUserId = 'from_user_id';
  static const toUserId = 'to_user_id';
  static const status = 'status';
}

abstract final class GameChallengeCols {
  static const id = 'id';
  static const fromUserId = 'from_user_id';
  static const toUserId = 'to_user_id';
  static const gameId = 'game_id';
  static const status = 'status';
  static const fromReady = 'from_ready';
  static const toReady = 'to_ready';
}

abstract final class FriendRequestStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const declined = 'declined';
}

abstract final class GameChallengeStatus {
  static const pending = 'pending';
  static const completed = 'completed';
}

abstract final class PenaltySessionCols {
  static const challengeId = 'challenge_id';
  static const roundIndex = 'round_index';
  static const fromGoals = 'from_goals';
  static const toGoals = 'to_goals';
  static const updatedAt = 'updated_at';
}

abstract final class PenaltyPickCols {
  static const challengeId = 'challenge_id';
  static const roundIndex = 'round_index';
  static const userId = 'user_id';
  static const pickKind = 'pick_kind';
  static const direction = 'direction';
  static const power = 'power';
  static const createdAt = 'created_at';
}

abstract final class PenaltyPickKind {
  static const shot = 'shot';
  static const dive = 'dive';
}
