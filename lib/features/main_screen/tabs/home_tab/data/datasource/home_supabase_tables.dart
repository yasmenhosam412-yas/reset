abstract final class HomeTable {
  static const posts = 'posts';
  static const profiles = 'profiles';
  static const userNotifications = 'user_notifications';
  static const postComments = 'post_comments';
  static const friendRequests = 'friend_requests';
  static const gameChallenges = 'game_challenges';
  static const onlineChallengeSkillRewards = 'online_challenge_skill_rewards';
  static const penaltyShootoutSessions = 'penalty_shootout_sessions';
  static const penaltyRoundPicks = 'penalty_round_picks';
  static const rpsSessions = 'rps_sessions';
  static const fantasyDuelSessions = 'fantasy_duel_sessions';
  static const teamChallengeDailyClaims = 'team_challenge_daily_claims';
  static const teamLineupRaceEntries = 'team_lineup_race_entries';
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
  static const allowShare = 'allow_share';
  static const postVisibility = 'post_visibility';
  static const postType = 'post_type';
  static const adLink = 'ad_link';
}

abstract final class PostCommentCols {
  static const id = 'id';
  static const postId = 'post_id';
  static const userId = 'user_id';
  static const comment = 'comment';
  static const createdAt = 'created_at';
}

abstract final class UserNotificationCols {
  static const id = 'id';
  static const userId = 'user_id';
  static const kind = 'kind';
  static const title = 'title';
  static const body = 'body';
  static const data = 'data';
  static const createdAt = 'created_at';
}

abstract final class ProfileCols {
  static const id = 'id';
  static const username = 'username';
  static const avatarUrl = 'avatar_url';
  static const teamSkillPoints = 'team_skill_points';
  static const teamSquad = 'team_squad';
  static const acceptsMatchInvites = 'accepts_match_invites';
  static const fcmToken = 'fcm_token';
  static const pushNotificationsEnabled = 'push_notifications_enabled';
}

abstract final class TeamChallengeClaimCols {
  static const userId = 'user_id';
  static const challengeKey = 'challenge_key';
  static const claimDay = 'claim_day';
}

abstract final class TeamLineupRaceCols {
  static const raceKey = 'race_key';
  static const userId = 'user_id';
  static const score = 'score';
  static const teamName = 'team_name';
  static const submittedAt = 'submitted_at';
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

abstract final class OnlineChallengeSkillRewardCols {
  static const challengeId = 'challenge_id';
  static const winnerUserId = 'winner_user_id';
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

abstract final class RpsSessionCols {
  static const challengeId = 'challenge_id';
  static const scoreFrom = 'score_from';
  static const scoreTo = 'score_to';
  static const fromPick = 'from_pick';
  static const toPick = 'to_pick';
  static const roundSeq = 'round_seq';
  static const status = 'status';
  static const updatedAt = 'updated_at';
}

abstract final class FantasyDuelSessionCols {
  static const challengeId = 'challenge_id';
  static const deckSeed = 'deck_seed';
  static const fromTrio = 'from_trio';
  static const toTrio = 'to_trio';
  static const updatedAt = 'updated_at';
  static const roundNumber = 'round_number';
  static const fromMatchWins = 'from_match_wins';
  static const toMatchWins = 'to_match_wins';
  static const matchComplete = 'match_complete';
}
