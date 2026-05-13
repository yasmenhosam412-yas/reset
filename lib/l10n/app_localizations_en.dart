// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'New Project';

  @override
  String get loggedInSuccessfully => 'Logged in successfully';

  @override
  String get loginHeroTitle => 'Let\'s get you back in.';

  @override
  String get loginHeroSubtitle =>
      'Manage your feed, connect with people, and keep your activity in sync.';

  @override
  String get signIn => 'Sign in';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get validEmailRequired => 'Enter a valid email';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordAtLeast6 => 'Password must be at least 6 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get continueText => 'Continue';

  @override
  String get newHere => 'New here?';

  @override
  String get createAccount => 'Create account';

  @override
  String get accountCreatedSuccessfully => 'Account created successfully';

  @override
  String get signupFriendlyUsernameTaken =>
      'That username is already taken. Please choose another one.';

  @override
  String get signupHeroTitle => 'Create your account';

  @override
  String get signupHeroSubtitle =>
      'Join now and start building your profile and activity.';

  @override
  String get signUp => 'Sign up';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'yourname';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get usernameAtLeast3 => 'Username must be at least 3 characters';

  @override
  String get alreadyMember => 'Already a member?';

  @override
  String get login => 'Login';

  @override
  String get forgotOtpInstructionSnack =>
      'Enter the code from your email, then choose a new password.';

  @override
  String get passwordUpdatedSnack =>
      'Password updated. Sign in with your new password.';

  @override
  String get forgotHeroTitleStep1 => 'Recover your account';

  @override
  String get forgotHeroTitleStep2 => 'Verify and reset password';

  @override
  String get forgotHeroSubtitleStep1 =>
      'We will send a one-time recovery code to your email.';

  @override
  String get forgotHeroSubtitleStep2 =>
      'Enter the code from your email and set a new password.';

  @override
  String get forgotStep1Title => 'Step 1: Request code';

  @override
  String get sendCode => 'Send code';

  @override
  String get rememberedIt => 'Remembered it?';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get forgotStep2Title => 'Step 2: Verify and update';

  @override
  String codeSentTo(Object email) {
    return 'Code sent to $email';
  }

  @override
  String get verificationCode => 'Verification code';

  @override
  String get verificationCodeHint => '6-8 digit code';

  @override
  String get codeRequired => 'Code is required';

  @override
  String get codeTooShort => 'Code looks too short';

  @override
  String get newPassword => 'New password';

  @override
  String get atLeast6Chars => 'At least 6 characters';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get verifyAndUpdatePassword => 'Verify code & update password';

  @override
  String get wrongEmail => 'Wrong email?';

  @override
  String get useDifferentEmail => 'Use a different one';

  @override
  String get newPost => 'New post';

  @override
  String get postTypeDescriptionPost => 'Post: regular community updates.';

  @override
  String get postTypeDescriptionAnnouncement =>
      'Announcement: for important updates.';

  @override
  String get postTypeDescriptionCelebration =>
      'Celebration: share wins and happy moments.';

  @override
  String get postTypeDescriptionAds =>
      'Ads: promote products, events, or offers.';

  @override
  String get postTypePost => 'Post';

  @override
  String get postTypeAnnouncement => 'Announcement';

  @override
  String get postTypeCelebration => 'Celebration';

  @override
  String get postTypeAds => 'Ads';

  @override
  String get adLink => 'Ad link';

  @override
  String get adLinkHint => 'https://example.com';

  @override
  String get friendsVisibilityHint =>
      'Friends only: only you and accepted friends can see this post.';

  @override
  String get generalVisibilityHint =>
      'General post: visible to all users in the app.';

  @override
  String get general => 'General';

  @override
  String get friendsOnly => 'Friends only';

  @override
  String get postContentHint => 'What is on your mind?';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get addVideo => 'Add video';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get allowReposts => 'Allow reposts';

  @override
  String get adsCannotRepost => 'Ads cannot be reposted.';

  @override
  String get othersCanShare => 'Others can share this to the home feed.';

  @override
  String get repostHidden => 'Repost is hidden for this post.';

  @override
  String get posting => 'Posting...';

  @override
  String get post => 'Post';

  @override
  String get postTextEmptyError => 'Post text cannot be empty.';

  @override
  String get adLinkInvalidError =>
      'Ad link is required and must be a valid http/https URL.';

  @override
  String get react => 'React';

  @override
  String get tapAgainToRemoveReaction => 'Tap again to remove your reaction.';

  @override
  String get visitAd => 'Visit ad';

  @override
  String get repostToHomeFeed => 'Repost to home feed';

  @override
  String get invalidAdLink => 'Invalid ad link.';

  @override
  String get couldNotOpenAdLink => 'Could not open ad link.';

  @override
  String get couldNotOpenLink => 'Could not open this link.';

  @override
  String get shared => 'Shared';

  @override
  String homeReactionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reactions',
      one: '1 reaction',
    );
    return '$_temp0';
  }

  @override
  String get saving => 'Saving...';

  @override
  String get editPost => 'Edit post';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYetBeFirst => 'No comments yet.\nBe the first to reply.';

  @override
  String get writeAComment => 'Write a comment...';

  @override
  String get mentionUsersHint =>
      'Type @ to mention friends, the author, or people who commented.';

  @override
  String get noMentionMatches => 'No matching names for this post.';

  @override
  String get deleteCommentQuestion => 'Delete this comment?';

  @override
  String get deleteCommentMessage =>
      'Your comment will be removed for everyone.';

  @override
  String get blockUser => 'Block';

  @override
  String blockUserTitle(String username) {
    return 'Block $username?';
  }

  @override
  String get blockUserMessage =>
      'You will stop seeing each other\'s posts here. Friend links and pending invites with this person are removed.';

  @override
  String get userBlockedSnackbar => 'User blocked.';

  @override
  String get blockedUsersTitle => 'Blocked accounts';

  @override
  String get openBlockedUsersSubtitle =>
      'People you blocked — unblock to see their posts again.';

  @override
  String get noBlockedUsers => 'You have not blocked anyone.';

  @override
  String get unblockUser => 'Unblock';

  @override
  String unblockUserTitle(String username) {
    return 'Unblock $username?';
  }

  @override
  String get unblockUserMessage =>
      'They can appear in your feeds and reach you again according to normal app rules.';

  @override
  String userUnblockedSnackbar(String username) {
    return '$username unblocked';
  }

  @override
  String get reportUser => 'Report';

  @override
  String reportUserTitle(String username) {
    return 'Report $username';
  }

  @override
  String get reportUserDescription =>
      'Choose the option that best describes the problem. Our team reviews every report.';

  @override
  String get reportUserReasonPrompt => 'What is the issue?';

  @override
  String get reportReasonHarassment => 'Harassment or bullying';

  @override
  String get reportReasonSpam => 'Spam or misleading';

  @override
  String get reportReasonHate => 'Hate or discrimination';

  @override
  String get reportReasonSexual => 'Sexual content';

  @override
  String get reportReasonViolence => 'Violence or threats';

  @override
  String get reportReasonImpersonation => 'Impersonation or fake account';

  @override
  String get reportReasonScam => 'Scam or fraud';

  @override
  String get reportReasonOther => 'Something else';

  @override
  String get reportUserOtherDetailsHint =>
      'Briefly describe what happened (optional)';

  @override
  String get reportUserDetailsLabel => 'Details (optional)';

  @override
  String get reportSubmittedSnackbar => 'Thanks — we received your report.';

  @override
  String get thisIsYourPost => 'This is your post.';

  @override
  String get deletePost => 'Delete post';

  @override
  String get alreadyConnectedNoRequestNeeded =>
      'You are already connected - no new request needed.';

  @override
  String get sendFriendRequest => 'Send friend request';

  @override
  String get sendChallenge => 'Send challenge';

  @override
  String get deletePostQuestion => 'Delete post?';

  @override
  String get deletePostMessage =>
      'This removes your post and its comments for everyone.';

  @override
  String challengeTarget(Object name) {
    return 'Challenge $name';
  }

  @override
  String get challengeInfoBody =>
      'Win the match for +10 team skill points (Team tab). Your friend loses nothing if they do not win.';

  @override
  String get chooseAGame => 'Choose a game';

  @override
  String get send => 'Send';

  @override
  String get explorePeople => 'Explore people';

  @override
  String get searchByUsername => 'Search by username...';

  @override
  String get explorePeopleHint =>
      'Type at least 2 characters. Find someone new or add them as a friend.';

  @override
  String get jumpInMeetPlayers => 'Jump in and meet players';

  @override
  String noUsernamesMatch(Object query) {
    return 'No usernames match \"$query\".';
  }

  @override
  String get exploreLinkFriend => 'Friends - open posts from the feed context';

  @override
  String get exploreLinkPendingOutgoing => 'Request sent - waiting for them';

  @override
  String get exploreLinkPendingIncoming =>
      'Wants to connect - accept on Profile';

  @override
  String get exploreLinkNone => 'Not connected yet';

  @override
  String get noPostsFromProfileYet =>
      'No posts from this profile in your feed yet. Pull to refresh on Home.';

  @override
  String get noPostsYetTapNewPost =>
      'No posts yet.\nTap New post to share something.';

  @override
  String get noPostsFoundForFilter =>
      'No posts found.\nTry another category or All.';

  @override
  String get cantRepostOwnPost => 'You can\'t repost your own post.';

  @override
  String get thisPostCannotBeReposted => 'This post cannot be reposted.';

  @override
  String get someone => 'Someone';

  @override
  String fromAuthor(Object author) {
    return 'From $author';
  }

  @override
  String get imageAttachedToRepost => 'Image is attached to this repost.';

  @override
  String get addCommentOptional => 'Add a comment (optional)...';

  @override
  String get publishRepost => 'Publish repost';

  @override
  String get repostPublished => 'Repost published';

  @override
  String get add => 'Add';

  @override
  String get saves => 'Saves';

  @override
  String get saveToSaves => 'Save to Saves';

  @override
  String get removeFromSaves => 'Remove from Saves';

  @override
  String get postSavedToSaves => 'Saved to your list.';

  @override
  String get postRemovedFromSaves => 'Removed from your list.';

  @override
  String get savedPostsEmpty =>
      'No saved posts yet. Tap the bookmark on a post in your feed.';

  @override
  String get openSavedPosts => 'Open saved posts';

  @override
  String get privacySecurity => 'Privacy & security';

  @override
  String get rateTheApp => 'Rate the app';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get pushNotificationsSubtitle =>
      'Turn off to stop server pushes and in-app notification mirrors. Your device token is removed so nothing is sent until you turn this back on.';

  @override
  String get matchInvites => 'Match invites';

  @override
  String get matchInvitesSubtitle =>
      'Off: you won\'t see incoming invites and friends won\'t see you for online challenges';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutQuestion => 'Sign out?';

  @override
  String get signOutMessage =>
      'You will need to sign in again to use your account.';

  @override
  String get cancel => 'Cancel';

  @override
  String get signedOut => 'Signed out';

  @override
  String get comingSoon => 'Coming soon.';

  @override
  String get profile => 'Profile';

  @override
  String get overview => 'Overview';

  @override
  String get friendRequests => 'Friend requests';

  @override
  String get noPendingFriendRequests => 'No pending friend requests.';

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get account => 'Account';

  @override
  String get couldNotLoadProfile => 'Could not load profile';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get usernameAllowedHint => 'letters, numbers, spaces, underscore';

  @override
  String get enterUsername => 'Enter a username';

  @override
  String get usernameAllowedChars =>
      'Use only letters, numbers, spaces, and underscore';

  @override
  String get newPhotoSelected => 'New photo selected';

  @override
  String get chooseProfilePhoto => 'Choose profile photo';

  @override
  String get save => 'Save';

  @override
  String get noNewPhoto => 'No new photo';

  @override
  String get notifications => 'Notifications';

  @override
  String get allCaughtUp => 'You are all caught up';

  @override
  String get notificationsCaughtUpSubtitle =>
      'You will only see clear alerts for likes, comments, invites, and room invites here. Pull down to refresh for the latest updates.';

  @override
  String get notifSomeoneReacted => 'Someone reacted to your post.';

  @override
  String get notifSomeoneCommented => 'Someone commented on your post.';

  @override
  String get notifYouWereMentioned => 'You were mentioned in a comment.';

  @override
  String get notifMentionOpenHint =>
      'Open the post to read the comment you were tagged in.';

  @override
  String get notifFriendInvite => 'You received a new friend invite.';

  @override
  String get notifRoomInviteWaiting => 'You have a room invite waiting.';

  @override
  String get notifNewNotification => 'You have a new notification.';

  @override
  String get notifReviewInvite =>
      'Review this invite and decide whether to accept or decline.';

  @override
  String get notifReviewInviteShort =>
      'Review this invite and choose Accept or Decline.';

  @override
  String get notifPostLikeOpenHint =>
      'Open the post to see who reacted and join the conversation.';

  @override
  String get notifPostCommentOpenHint =>
      'Open comments to read and reply from your feed.';

  @override
  String get notifFriendRequestAcceptedStatus =>
      'This friend request was accepted.';

  @override
  String get notifFriendRequestNoLongerPending =>
      'This friend request is no longer pending.';

  @override
  String get notifPartyRoomInviteOpenHint =>
      'Join your room invite from the Online tab when you are ready.';

  @override
  String get friendRequestNoLongerValid =>
      'This friend request is no longer valid (account/request removed).';

  @override
  String get friendRequestAccepted => 'Friend request accepted.';

  @override
  String get friendRequestDeclined => 'Friend request declined.';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get declined => 'Declined.';

  @override
  String get decline => 'Decline';

  @override
  String get accept => 'Accept';

  @override
  String get matchAccepted => 'Match accepted';

  @override
  String get opponent => 'Opponent';

  @override
  String get game => 'Game';

  @override
  String get ready => 'Ready';

  @override
  String get couldNotLoadOnline => 'Could not load Online';

  @override
  String get tryAgain => 'Try again';

  @override
  String get online => 'Online';

  @override
  String get onlineHeaderSubtitle =>
      'Match with friends, party rooms, and quick games';

  @override
  String get friends => 'Friends';

  @override
  String get tapFriendToChallenge => 'Tap someone to send an online challenge';

  @override
  String get partyRooms => 'Party rooms';

  @override
  String get partyRoomsSubtitle => 'Invites and rooms you have joined';

  @override
  String get playInvites => 'Play invites';

  @override
  String get playInvitesSubtitle => 'Friends invited you to a match';

  @override
  String get refresh => 'Refresh';

  @override
  String get noPendingInvites => 'No pending invites.';

  @override
  String get activeMatches => 'Active matches';

  @override
  String get tapReadyWhenSet => 'Tap Ready when you are set to play';

  @override
  String get games => 'Games';

  @override
  String get gamesSubtitle => 'Practice vs AI or open a party room';

  @override
  String get rateAppFromPhoneHint =>
      'Rate us from your phone\'s app store once the app is published.';

  @override
  String get couldNotOpenStoreLink => 'Could not open the store link.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountQuestion => 'Delete account?';

  @override
  String get deleteAccountMessage =>
      'This will permanently delete your account and data.';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get failedToDeleteAccount => 'Failed to delete account';

  @override
  String get delete => 'Delete';

  @override
  String get thisPlayer => 'this player';

  @override
  String get removeFriendQuestion => 'Remove friend?';

  @override
  String removeFriendMessage(Object name) {
    return '$name will be removed from your friends. You can send a new request later from Home.';
  }

  @override
  String get remove => 'Remove';

  @override
  String removedFromFriends(Object name) {
    return '$name removed from friends';
  }

  @override
  String get retry => 'Retry';

  @override
  String get noFriendsYet => 'No friends yet';

  @override
  String get friendsEmptyHint =>
      'Accept requests below or send one from someone\'s post on Home.';

  @override
  String get player => 'Player';

  @override
  String get removeFriend => 'Remove friend';

  @override
  String get draw => 'Draw';

  @override
  String get youWon => 'You won';

  @override
  String get youLost => 'You lost';

  @override
  String get historyAndLiveInvites => 'History & live invites';

  @override
  String get loadingYourMatches => 'Loading your matches...';

  @override
  String get couldNotLoadChallenges => 'Couldn\'t load challenges';

  @override
  String get noChallengesYet => 'No challenges yet';

  @override
  String get challengesEmptyHint =>
      'Invite a friend from Home or the Online tab - finished games show up here with results.';

  @override
  String get vsPrefix => 'vs ';

  @override
  String get helpGetStarted => 'Get started';

  @override
  String get helpQMainTabs => 'What are the main tabs?';

  @override
  String get helpAMainTabs =>
      'Home is your social feed and friends. Online is live challenges and games with people you know. Team is your six-player squad, training, and squad battles. Profile is your account, requests, and settings.';

  @override
  String get helpQAddFriends => 'How do I add friends?';

  @override
  String get helpAAddFriends =>
      'Send a request from Home. The other person accepts under Profile -> Friend requests. You both need an account.';

  @override
  String get helpQTeamTab => 'How does the Team tab work?';

  @override
  String get helpATeamTab =>
      'Create a team, name your players, then train stats with skill points. You can run daily challenges, lineup races, friend spars, and a solo Academy friendly for extra points-check each card for rules and limits.';

  @override
  String get helpQSaveSquad => 'Why can\'t I save my squad?';

  @override
  String get helpASaveSquad =>
      'Make sure you are signed in and online. Open Team after login so your squad can sync to your profile.';

  @override
  String get helpTroubleshooting => 'Troubleshooting';

  @override
  String get helpQStuck => 'Something looks stuck';

  @override
  String get helpAStuck =>
      'Pull to refresh on Profile. For Online, use refresh where shown. If a game won\'t load, go back and open the challenge again.';

  @override
  String get helpQSignedOut => 'I signed out by accident';

  @override
  String get helpASignedOut =>
      'Sign in again from the login screen with the same email. Your cloud data stays tied to your account.';

  @override
  String get contact => 'Contact';

  @override
  String get privacyYourAccountData => 'Your account and data';

  @override
  String get privacyYourAccountDataBody =>
      'You sign in with email and password. Your session is managed securely by our backend (Supabase Auth). We store the profile information you choose to save, such as display name and avatar.';

  @override
  String get privacyDataUsageTitle => 'What we use your data for';

  @override
  String get privacyDataUsageHome =>
      'Home and social features: posts, comments, likes, and friend requests.';

  @override
  String get privacyDataUsageOnline =>
      'Online play: challenges, match state, and related game records.';

  @override
  String get privacyDataUsageTeam =>
      'Team mode: squad lineup, skill points, daily challenges, and leaderboards.';

  @override
  String get privacyFriendsVisibilityTitle => 'Friends and visibility';

  @override
  String get privacyFriendsVisibilityBody =>
      'When you accept a friend request, each of you can interact in features that require friends (for example invites and team battles). Declined requests are not shown as active connections.';

  @override
  String get privacySecurityTipsTitle => 'Security tips';

  @override
  String get privacyTipStrongPassword =>
      'Use a strong, unique password for this app.';

  @override
  String get privacyTipSignOutShared =>
      'Sign out from Profile when using a shared device.';

  @override
  String get privacyTipUnauthorizedAccess =>
      'If you suspect unauthorized access, change your password and sign out everywhere from your account provider if available.';

  @override
  String get privacyQuestionsTitle => 'Questions';

  @override
  String get privacyQuestionsBody =>
      'This screen is a product summary, not a legal contract. For formal terms or data requests, contact the team that operates this app. Use the full privacy policy link below for the detailed version.';

  @override
  String get privacyFullPolicyTitle => 'Full privacy policy';

  @override
  String get privacyFullPolicyOpen => 'View in browser';

  @override
  String get privacySafetyTitle => 'Safety and reporting';

  @override
  String privacySafetyBody(Object email) {
    return 'Joy lets everyone share posts. If you see abuse, someone at risk, or illegal material—including anything that sexualizes minors—email $email with what you saw and any details that help us find the post (for example author name and approximate time). We review reports and act per our rules and applicable law.';
  }

  @override
  String get privacyCouldNotOpenPolicyLink =>
      'Could not open the privacy policy link.';

  @override
  String get practiceVsAi => 'Practice vs AI';

  @override
  String get singleDeviceNotOnlineMatch =>
      'Single device - not an online match.';

  @override
  String get singleDeviceChallengeFriendHint =>
      'Single device - challenge a friend online for a real duel.';

  @override
  String get singleDeviceSameDuelHint =>
      'Single device - same duel online vs a friend.';

  @override
  String vsAiNotAvailableYet(Object title) {
    return '$title vs AI is not available yet.';
  }

  @override
  String createRoomTitle(Object title) {
    return 'Create $title room';
  }

  @override
  String get roomSize => 'Room size';

  @override
  String playersMax(Object count) {
    return '$count players max';
  }

  @override
  String inviteExactlyFriends(Object count) {
    return 'Invite exactly $count friends';
  }

  @override
  String get creating => 'Creating...';

  @override
  String get createRoom => 'Create room';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get noFriendsYetAcceptFromHome =>
      'No friends yet. Accept requests from Home.';

  @override
  String get friend => 'Friend';

  @override
  String get invitedYouToPlay => ' invited you to play ';

  @override
  String get activeMatchesMultiHint =>
      'Each card is a separate game. Mark Ready per match; when both players are ready on a card, you can start that game from there.';

  @override
  String get bothPlayersReady => 'Both players ready.';

  @override
  String readyStatusLine(Object youStatus, Object themStatus) {
    return 'You: $youStatus - Them: $themStatus';
  }

  @override
  String get notReady => 'Not ready';

  @override
  String get waiting => 'Waiting';

  @override
  String get waitingForOpponent => 'Waiting for opponent';

  @override
  String get noPartyRoomInvitesYet => 'No party room invites yet.';

  @override
  String inHostsPartyRoom(Object host) {
    return 'In $host\'s party room';
  }

  @override
  String hostInvitedYou(Object host) {
    return '$host invited you';
  }

  @override
  String gameUpToPlayers(Object game, Object players) {
    return '$game - up to $players players';
  }

  @override
  String get leave => 'Leave';

  @override
  String get openLobby => 'Open lobby';

  @override
  String get joinRoom => 'Join room';

  @override
  String get aPlayer => 'A player';

  @override
  String playerLeftGameRoom(Object name) {
    return '$name left the game room.';
  }

  @override
  String playersLeftGameRoom(int count) {
    return '$count players left the game room.';
  }

  @override
  String get unsupportedRoomGame => 'Unsupported room game.';

  @override
  String get openSlot => 'Open slot';

  @override
  String slotNumber(int index) {
    return 'SLOT $index';
  }

  @override
  String get waitingForInvite => 'Waiting for invite...';

  @override
  String get readyRoom => 'READY ROOM';

  @override
  String get readyRoomSubtitle =>
      'Friends accept the invite under Online -> Party room invites. No code to copy - the run starts when every slot is filled.';

  @override
  String joinedOutOf(int joined, int max) {
    return '$joined / $max';
  }

  @override
  String get fullSquad => 'FULL SQUAD';

  @override
  String get recruiting => 'RECRUITING';

  @override
  String get roster => 'ROSTER';

  @override
  String get launchGame => 'LAUNCH GAME';

  @override
  String get waitingForPlayers => 'WAITING FOR PLAYERS';

  @override
  String get you => 'You';

  @override
  String playerNumber(int number) {
    return 'Player $number';
  }

  @override
  String flashMatchOnlineDesc(int rounds) {
    return 'Each round gets harder with more icons and stronger penalties; gentle reshuffle appears only in late rounds - $rounds rounds. Lower total time wins.';
  }

  @override
  String flashMatchOfflineDesc(int rounds) {
    return 'Pass the phone: $rounds rounds each; harder via grid growth and penalties, with light late-round reshuffle (time window stays fair). Lowest total wins.';
  }

  @override
  String get loadingRoom => 'Loading room...';

  @override
  String waitingJoinedOutOf(int joined, int max) {
    return 'Waiting: $joined / $max';
  }

  @override
  String get tapStartWhenReady => 'Tap start when ready.';

  @override
  String playerTurnNext(Object player) {
    return '$player - your turn next.';
  }

  @override
  String get runComplete => 'Run complete!';

  @override
  String get matchOver => 'Match over!';

  @override
  String playerRoundProgress(Object player, int round, int total) {
    return '$player · Round $round / $total';
  }

  @override
  String get memorize => 'MEMORIZE';

  @override
  String flashMatchCueMetaBasic(int flashMs, int choices) {
    return '$flashMs ms · $choices choices';
  }

  @override
  String flashMatchCueMetaWithReshuffle(
    int flashMs,
    int choices,
    int scrambleMs,
  ) {
    return '$flashMs ms · $choices choices · reshuffle ${scrambleMs}ms';
  }

  @override
  String get tapTheMatch => 'TAP THE MATCH';

  @override
  String penaltyMs(int ms) {
    return 'Penalty +$ms ms';
  }

  @override
  String get startNextPlayer => 'START NEXT PLAYER';

  @override
  String get startMatch => 'START MATCH';

  @override
  String winnerWithMs(Object name, int ms) {
    return 'Winner: $name ($ms ms)';
  }

  @override
  String tieAtMsPlayers(int ms, Object players) {
    return 'Tie at $ms ms: $players';
  }

  @override
  String totalMs(int ms) {
    return 'Total: $ms ms';
  }

  @override
  String get playAgain => 'Play again';

  @override
  String get roomBoard => 'Room board';

  @override
  String get noScoresYet => 'No scores yet.';

  @override
  String totalMsLabel(Object value) {
    return '$value ms';
  }

  @override
  String get totals => 'Totals';

  @override
  String get rpsInvalidThrow => 'Invalid throw';

  @override
  String get rpsNotInThisMatch => 'You are not in this match';

  @override
  String get rpsMatchAlreadyFinished => 'Match already finished';

  @override
  String get rpsAlreadyLockedForRound => 'Already locked for this round';

  @override
  String get roundComplete => 'Round complete';

  @override
  String get drawReplayRound => 'Draw - replay the round';

  @override
  String get youTakeRound => 'You take the round';

  @override
  String get aiTakesRound => 'AI takes the round';

  @override
  String get challengerWinsRound => 'Challenger wins the round';

  @override
  String get hostWinsRound => 'Host wins the round';

  @override
  String opponentTakesRound(Object name) {
    return '$name takes the round';
  }

  @override
  String get couldNotResetBout =>
      'Could not reset the bout. Check connection, then try again.';

  @override
  String rpsSetNumber(int number) {
    return 'Set $number';
  }

  @override
  String get chooseYourThrow => 'Choose your throw';

  @override
  String get boutFinished => 'Bout finished';

  @override
  String tapCardRevealVs(Object name) {
    return 'Tap a card - simultaneous reveal vs $name';
  }

  @override
  String get waitingForRound => 'Waiting for the round...';

  @override
  String get sendingYourPick => 'Sending your pick...';

  @override
  String get opponentStillChoosing => 'Opponent is still choosing...';

  @override
  String get aiThinking => 'AI is thinking...';

  @override
  String get rpsRock => 'Rock';

  @override
  String get rpsPaper => 'Paper';

  @override
  String get rpsScissors => 'Scissors';

  @override
  String get throwLockedIn => 'Throw locked in';

  @override
  String get hiddenUntilBothThrow =>
      'Hidden from your opponent until both sides throw.';

  @override
  String get aiPickingNext => 'Hang tight - AI is picking next.';

  @override
  String get scoreboard => 'Scoreboard';

  @override
  String firstToRoundWinsTakesBout(int count) {
    return 'First to $count round wins takes the bout';
  }

  @override
  String throwLabelWithHint(Object label, Object hint) {
    return 'Throw $label. $hint';
  }

  @override
  String get crushesScissors => 'Crushes scissors';

  @override
  String get coversRock => 'Covers rock';

  @override
  String get cutsPaper => 'Cuts paper';

  @override
  String get deadHeat => 'Dead heat';

  @override
  String get honorSharedRematch => 'Honor shared - rematch for the crown?';

  @override
  String get whatABoutSoakItIn => 'What a bout - soak it in!';

  @override
  String get closeFightRematch => 'Close fight - one tap away from a rematch.';

  @override
  String get challengerSideWins => 'Challenger side wins';

  @override
  String get hostSideWins => 'Host side wins';

  @override
  String get boutOver => 'Bout over';

  @override
  String rpsShareBody(
    Object opponent,
    int leftScore,
    int rightScore,
    Object leftLabel,
    Object rightLabel,
    Object headline,
  ) {
    return 'Rock paper scissors vs $opponent\nFinal: $leftScore — $rightScore ($leftLabel / $rightLabel)\n$headline';
  }

  @override
  String youWinDuelScore(int mine, int opp) {
    return 'You win the duel $mine–$opp';
  }

  @override
  String opponentWinsDuelScore(Object name, int mine, int opp) {
    return '$name wins the duel $mine–$opp';
  }

  @override
  String get pickOnlyFromSquadSheet =>
      'Pick only players from your squad sheet.';

  @override
  String get couldNotSubmitPicks => 'Could not submit picks';

  @override
  String get alreadySubmittedOrSyncIssue => 'Already submitted or sync issue';

  @override
  String youTakeRoundZones(int you, int opp) {
    return 'You take this round ($you–$opp zones)';
  }

  @override
  String opponentTakesRoundZones(Object name, int you, int opp) {
    return '$name takes this round ($you–$opp zones)';
  }

  @override
  String zonesDrawnYouEdgeStrength(int you, int opp) {
    return 'Zones drawn - you edge on strength ($you–$opp)';
  }

  @override
  String zonesDrawnOpponentEdges(Object name, int you, int opp) {
    return 'Zones drawn - $name edges ($you–$opp)';
  }

  @override
  String get honorsEvenDrawnRoundNoPoint =>
      'Honors even - drawn round (no point)';

  @override
  String get couldNotSyncRoundTryAgain => 'Could not sync round - try again';

  @override
  String get couldNotStartRematch =>
      'Could not start a rematch. Check connection, then try again.';

  @override
  String fantasyYourSquadSubtitle(int cards, int starters) {
    return '$cards cards · start $starters · read suit vs pitch call per zone';
  }

  @override
  String get lastRound => 'Last round';

  @override
  String get cardsLockedSeeResultBelow => 'Cards locked - see result below';

  @override
  String startersCount(int picked, int total) {
    return 'Starters ($picked/$total)';
  }

  @override
  String get clear => 'Clear';

  @override
  String get lockLineup => 'Lock lineup';

  @override
  String get lineupLocked => 'Lineup locked';

  @override
  String waitingForOpponentToSubmit(Object name) {
    return 'Waiting for $name to submit...';
  }

  @override
  String nextRoundScoreTarget(int mine, int opp, int target) {
    return 'Next round ($mine–$opp · first to $target)';
  }

  @override
  String fantasyDuelShareBody(
    Object opponent,
    int mine,
    int opp,
    int target,
    Object summary,
  ) {
    return 'Fantasy card duel vs $opponent\nRound wins: $mine — $opp (first to $target)\n$summary';
  }

  @override
  String get fantasyZoneLeftWing => 'Left wing';

  @override
  String get fantasyZoneNo10 => 'No. 10';

  @override
  String get fantasyZoneWideBack => 'Wide back';

  @override
  String get matchday => 'Matchday';

  @override
  String get vsUpper => 'VS';

  @override
  String get squadManager => 'Squad manager';

  @override
  String roundNumber(int number) {
    return 'ROUND $number';
  }

  @override
  String firstToRoundWinsVsFriend(int count) {
    return 'First to $count round wins · vs friend';
  }

  @override
  String firstToRoundWins(int count) {
    return 'First to $count round wins';
  }

  @override
  String secondsShort(int seconds) {
    return '${seconds}s';
  }

  @override
  String get howDuelWorks => 'How the duel works';

  @override
  String get tapToExpandRules => 'Tap to expand rules';

  @override
  String fantasyRule1(int squadSize) {
    return 'You draw $squadSize cards — shirt # is base value. Each card has a suit (Blitz / Maestro / Iron) from its role.';
  }

  @override
  String fantasyRule2(int starters, Object zone1, Object zone2, Object zone3) {
    return 'Tap $starters cards in lock order: $zone1 -> $zone2 -> $zone3.';
  }

  @override
  String fantasyRule3(int bonus) {
    return 'The pitch calls one suit per zone (see strip below). If your card’s suit matches that call, add +$bonus before comparing - raw shirt # alone can lose.';
  }

  @override
  String get fantasyRule4 =>
      'Win more zones than your opponent; if zones are split, total effective value (base + suit + bonuses) decides.';

  @override
  String fantasyRuleOffline(int count) {
    return 'Offline duel: first to $count round wins; each round is a fresh hand and pitch.';
  }

  @override
  String fantasyRuleOnline(int count) {
    return 'Online: first to $count round wins - after each reveal both players get a new deck from the server for the next lock-in.';
  }

  @override
  String fantasyPitchMatchBonus(int bonus) {
    return '+$bonus pitch match';
  }

  @override
  String get noSuitMatch => 'No suit match';

  @override
  String fantasySuitBonusWithName(int bonus, Object suitName) {
    return '+$bonus $suitName';
  }

  @override
  String everyoneMustFinishRoundsBeforeNewRun(int rounds) {
    return 'Everyone must finish all $rounds rounds before a new run.';
  }

  @override
  String timeRanOutBeforeFinishingRoundsLose(int rounds) {
    return 'Time ran out before finishing all $rounds rounds. You lose - score does not matter.';
  }

  @override
  String tooEarlyTryAgain(int left, int max) {
    return 'Too early. Try again ($left/$max left).';
  }

  @override
  String get roundFailedAfterEarlyTaps => 'Round failed after 3 early taps.';

  @override
  String roundFailedPenaltyMs(int ms) {
    return 'Round failed (3 early taps). Penalty: ${ms}ms.';
  }

  @override
  String playerUpNextPreviousTurnFailed(Object player) {
    return '$player up next. Previous turn failed (3 early taps).';
  }

  @override
  String get turnFailedAfterEarlyTaps => 'Turn failed after 3 early taps.';

  @override
  String waitingOpponentFinishRounds(int rounds) {
    return 'Waiting for opponent to finish all $rounds rounds...';
  }

  @override
  String youWinOpponentTimedOut(Object name) {
    return 'You win - $name ran out of time before finishing all rounds.';
  }

  @override
  String waitingUserFinishRounds(Object name, int rounds) {
    return 'Waiting for $name to finish all $rounds rounds...';
  }

  @override
  String youWinTotalVs(int myTotal, Object name, int oppTotal) {
    return 'You win! Total: $myTotal ms vs $name: $oppTotal ms';
  }

  @override
  String opponentWinsTotalVs(Object name, int oppTotal, int myTotal) {
    return '$name wins. Total: $oppTotal ms vs your $myTotal ms';
  }

  @override
  String finalDrawTotals(int total) {
    return 'Final draw: both totals are $total ms';
  }

  @override
  String reactionRelayOnlineSubtitle(int seconds) {
    return 'Classic taps -> then chase the target. Beat the clock: $seconds s for all 5.';
  }

  @override
  String reactionRelayOfflineSubtitle(int seconds) {
    return 'Pass & play. Rounds 1-2 static GO - 3-5 moving target. $seconds s total.';
  }

  @override
  String playersCount(int count) {
    return '$count players';
  }

  @override
  String get chaseUpper => 'CHASE';

  @override
  String get classicUpper => 'CLASSIC';

  @override
  String roundShortProgress(int round, int total) {
    return 'R$round / $total';
  }

  @override
  String get nextRound => 'Next round';

  @override
  String waitAllPlayersFinishThenReset(int rounds) {
    return 'Wait until every player finishes all $rounds rounds. Then you can start a new run and scores reset for everyone.';
  }

  @override
  String get yourRun => 'Your run';

  @override
  String get noSplitsYetStartMatch => 'No splits yet - start the match.';

  @override
  String get ms => 'ms';

  @override
  String get roundLog => 'Round log';

  @override
  String get winsAppearAfterEachRound => 'Wins appear here after each round.';

  @override
  String roundMsLabel(int round) {
    return 'Round $round · ms';
  }

  @override
  String get thisFriend => 'this friend';

  @override
  String get editYourPostHint => 'Edit your post...';

  @override
  String get postToFeed => 'Post to feed';

  @override
  String get addSomeTextToPost => 'Add some text to post';

  @override
  String get postedToHomeFeed => 'Posted to your home feed';

  @override
  String get homePostDeleted => 'Post deleted';

  @override
  String get homePostUpdated => 'Post updated';

  @override
  String get homePostPublished => 'Post published';

  @override
  String alreadyFriendsWith(Object name) {
    return 'You are already friends with $name.';
  }

  @override
  String friendRequestSentTo(Object name) {
    return 'Friend request sent to $name';
  }

  @override
  String get undoFriendRequest => 'Undo';

  @override
  String get friendRequestWithdrawn => 'Friend request cancelled.';

  @override
  String challengeSentTo(Object game, Object name) {
    return '$game challenge sent to $name';
  }

  @override
  String leftTheMatch(Object name, Object game) {
    return '$name left the $game match.';
  }

  @override
  String get opponentLeftMatch => 'Opponent left the match.';

  @override
  String get matchNoLongerAvailable => 'This match is no longer available.';

  @override
  String get challengeDeclined => 'Challenge declined.';

  @override
  String get challengeAccepted => 'Challenge accepted.';

  @override
  String get challengeAcceptedHasOtherMatches =>
      'Match accepted. You already have other active matches - use Active matches for each game and Ready.';

  @override
  String get readyWaitingForOpponent =>
      'You\'re ready - waiting for your opponent.';

  @override
  String get reactionLike => 'Like';

  @override
  String get reactionLove => 'Love';

  @override
  String get reactionHaha => 'Haha';

  @override
  String get reactionWow => 'Wow';

  @override
  String get reactionSad => 'Sad';

  @override
  String get reactionCare => 'Care';

  @override
  String roundsLabel(int count) {
    return 'Rounds $count';
  }

  @override
  String get finished => 'Finished';

  @override
  String get inProgress => 'In progress';

  @override
  String get betweenRounds => 'Between rounds';

  @override
  String get resetMatch => 'Reset match';

  @override
  String get restartRound => 'Restart round';

  @override
  String get startRound => 'Start round';

  @override
  String get reactionRelayStartRoundHint =>
      'Start round 1. Each player gets one reaction chance per round.';

  @override
  String get reactionRelayYouPlayThisRound =>
      'You play this round on your device. Tap arm when ready.';

  @override
  String reactionRelayPassPhoneTo(Object player) {
    return 'Pass the phone to $player. Tap arm when ready.';
  }

  @override
  String get arm => 'Arm';

  @override
  String get waitForGo => 'Wait for GO...';

  @override
  String get goTap => 'GO! TAP!';

  @override
  String roundWinnerMs(int round, Object player, int ms) {
    return 'Round $round winner: $player ($ms ms)';
  }

  @override
  String get yourRunFinished => 'Your run finished.';

  @override
  String get noChampionYet => 'No champion yet.';

  @override
  String championLabel(Object name) {
    return 'Champion: $name';
  }

  @override
  String bestReactionMs(int ms) {
    return 'Best reaction: $ms ms';
  }

  @override
  String get submitting => 'Submitting...';

  @override
  String get submitScore => 'Submit score';

  @override
  String get roomLeaderboard => 'Room leaderboard';

  @override
  String get winnersQueue => 'Winners queue';

  @override
  String get noRoundsFinishedYet => 'No rounds finished yet.';

  @override
  String get finalWinnersRanking => 'Final winners ranking';

  @override
  String get currentStandings => 'Current standings';

  @override
  String get noFinalRankingYet => 'No final ranking yet.';

  @override
  String get wins => 'wins';

  @override
  String get wait => 'Wait';

  @override
  String get rpsHeaderTitle => 'Rock · Paper · Scissors';

  @override
  String rpsHeaderOnlineSubtitle(Object name) {
    return 'vs $name · live bout';
  }

  @override
  String rpsHeaderOfflineSubtitle(Object name) {
    return 'Practice vs $name';
  }

  @override
  String get throwLabel => 'Throw';

  @override
  String get challenger => 'Challenger';

  @override
  String get host => 'Host';

  @override
  String get rpsPaperCoversRockChallengerWins =>
      'Paper covers rock · challenger wins the throw';

  @override
  String get rpsPaperCoversRockHostWins =>
      'Paper covers rock · host wins the throw';

  @override
  String get rpsChallengerWinsThrow => 'Challenger wins the throw';

  @override
  String get rpsHostWinsThrow => 'Host wins the throw';

  @override
  String couldNotCloseOutMatch(Object message) {
    return 'Could not close out match: $message';
  }

  @override
  String couldNotSubmitPick(Object message) {
    return 'Could not submit pick: $message';
  }

  @override
  String whoGoal(Object name) {
    return '$name - GOAL!';
  }

  @override
  String whoSaved(Object name) {
    return '$name - saved!';
  }

  @override
  String get penaltyDirFarLeft => 'Far left';

  @override
  String get penaltyDirLeft => 'Left';

  @override
  String get penaltyDirCenter => 'Center';

  @override
  String get penaltyDirRight => 'Right';

  @override
  String get penaltyDirFarRight => 'Far right';

  @override
  String get penaltyDragReleaseShoot => 'Drag sideways, release to shoot';

  @override
  String get penaltyDragReleaseDive => 'Drag sideways, release to dive';

  @override
  String get penaltyLaneLeft => 'LEFT';

  @override
  String get penaltyLaneCenter => 'CENTER';

  @override
  String get penaltyLaneRight => 'RIGHT';

  @override
  String get penaltyLaneFarLeftShort => 'FL';

  @override
  String get penaltyLaneLeftShort => 'L';

  @override
  String get penaltyLaneCenterShort => 'C';

  @override
  String get penaltyLaneRightShort => 'R';

  @override
  String get penaltyLaneFarRightShort => 'FR';

  @override
  String penaltyRoundProgress(int round, int total) {
    return 'Round $round / $total';
  }

  @override
  String get penaltyRoundPicksInProgress => 'Round picks in progress...';

  @override
  String opponentWins(Object name) {
    return '$name wins';
  }

  @override
  String get shootoutWinSubline => 'Clinical finishing - share the highlight!';

  @override
  String get shootoutLossSubline => 'Heartbreaker - one more shootout?';

  @override
  String get shootoutDrawSubline => 'Deadlock on the line - honor is even.';

  @override
  String get shootoutOver => 'Shootout over';

  @override
  String youVsOpponentScore(int myGoals, Object opponent, int oppGoals) {
    return 'You $myGoals  —  $opponent $oppGoals';
  }

  @override
  String get shareToHomeFeed => 'Share to home feed';

  @override
  String penaltyShootoutShareBody(
    Object opponent,
    int myGoals,
    int oppGoals,
    Object winnerLine,
  ) {
    return 'Penalty shootout vs $opponent\nFinal: $myGoals — $oppGoals\n$winnerLine';
  }

  @override
  String get shareResult => 'Share result';

  @override
  String get goalLanes => 'Goal lanes';

  @override
  String get goalLanesClassicTooltip => 'Left · center · right';

  @override
  String get goalLanesWideTooltip => 'Far left through far right';

  @override
  String get savingPickToServer => 'Saving your pick to the server...';

  @override
  String pickSavedWaitingFor(Object name) {
    return 'Pick saved - waiting for $name...';
  }

  @override
  String shotDiveSummary(Object shot, Object dive) {
    return 'Shot $shot · Dive $dive';
  }

  @override
  String get onlineGamePenaltyShootout => 'Penalty shootout';

  @override
  String get onlineGameRockPaperScissors => 'Rock paper scissors';

  @override
  String get onlineGameFantasyCards => 'Fantasy cards';

  @override
  String get onlineGameReactionRelay => 'Reaction relay';

  @override
  String get onlineGameFlashMatch => 'Flash match';

  @override
  String onlineGameFallback(Object gameId) {
    return 'Game #$gameId';
  }

  @override
  String get onlinePartyGameTwoToFive =>
      'Party game - 2-5 players on one device';

  @override
  String get onlinePartyGameRoundsGetHarder =>
      'Party game - rounds get harder (flash, grid, penalties)';

  @override
  String get aiLabel => 'AI';

  @override
  String matchVsOpponent(Object name) {
    return 'Match vs $name';
  }

  @override
  String noScreenForGameIdYet(Object gameId) {
    return 'No screen for game ID $gameId yet.';
  }

  @override
  String get posts => 'Posts';

  @override
  String get challenges => 'Challenges';

  @override
  String get couldNotFindPostInFeed => 'Couldn\'t find that post on the feed.';

  @override
  String get feedTipPullToRefresh => 'Pull down on the list to refresh posts.';

  @override
  String get feedTipTapName =>
      'Tap someone\'s name to add them or send a game challenge.';

  @override
  String get feedTipExplorePeople =>
      'Use Explore people under Jump in to search players by username.';

  @override
  String get feedTipTopLiked => 'Switch to Top liked to see what\'s trending.';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get tapForFeedTip => 'Tap for a feed tip - your community hub';

  @override
  String get backToTop => 'Back to top';

  @override
  String get jumpIn => 'Jump in';

  @override
  String get quickNewPostTooltip => 'New post - share an update';

  @override
  String get quickOnlineTooltip => 'Play online - challenges & duels';

  @override
  String get quickAlertsTooltip => 'Alerts - replies & invites';

  @override
  String get quickBattlesTooltip => 'Battles - team events';

  @override
  String get quickProfileTooltip => 'Profile - you & friends';

  @override
  String get quickPeopleTooltip => 'Explore people - search & friend requests';

  @override
  String get alerts => 'Alerts';

  @override
  String get battles => 'Battles';

  @override
  String get people => 'People';

  @override
  String get latest => 'Latest';

  @override
  String get topLiked => 'Top liked';

  @override
  String get all => 'All';

  @override
  String get announce => 'Announce';

  @override
  String get celebrate => 'Celebrate';

  @override
  String get teamBattleCosmicDiceTitle => 'Cosmic dice';

  @override
  String get teamBattleCosmicDiceSubtitle =>
      'One roll (1-999) per UTC day - highest wins.';

  @override
  String get teamBattleReflexTitle => 'Green-light reflex';

  @override
  String get teamBattleReflexSubtitle =>
      'Wait for green, then tap - fastest reaction ranks higher.';

  @override
  String get teamBattleOracleTitle => 'Oracle digit';

  @override
  String get teamBattleOracleSubtitle =>
      'Pick a digit 0-9. A daily hash picks the winning number.';

  @override
  String get teamBattleBlitzTitle => 'Five-second blitz';

  @override
  String get teamBattleBlitzSubtitle =>
      'How many taps in 5 seconds? Best score today stays on the board.';

  @override
  String get teamBattleHighLowTitle => 'High-low prophet';

  @override
  String get teamBattleHighLowSubtitle =>
      'The app rolls 0-99 once per day (UTC). Pick low (0-49) or high (50-99).';

  @override
  String teamPicked(Object value) {
    return 'picked $value';
  }

  @override
  String get teamEntered => 'Entered';

  @override
  String teamYourRoll(Object value) {
    return 'Your roll: $value';
  }

  @override
  String teamYourBestMs(Object value) {
    return 'Your best: $value ms';
  }

  @override
  String get teamSubmitted => 'Submitted';

  @override
  String get teamSubmittedToday => 'Submitted for today.';

  @override
  String teamYouPickedFair(Object value) {
    return 'You picked $value. The winning digit is not shown here (fair play).';
  }

  @override
  String teamYourBestTaps(Object value) {
    return 'Your best: $value taps';
  }

  @override
  String teamYouChoseFair(Object value) {
    return 'You chose $value. The hidden number is not shown here (fair play).';
  }

  @override
  String teamRolledSubmit(Object value) {
    return 'You rolled $value. Submit for today?';
  }

  @override
  String get submit => 'Submit';

  @override
  String teamLockedIn(Object roll, Object period) {
    return 'Locked in: $roll for $period (UTC).';
  }

  @override
  String teamSavedMs(Object value) {
    return 'Saved: $value ms';
  }

  @override
  String teamScoreMs(Object value) {
    return '$value ms';
  }

  @override
  String get teamLockPick => 'Lock pick';

  @override
  String get teamOracleSavedFair =>
      'Pick saved. The oracle digit stays hidden here so everyone plays fair.';

  @override
  String teamTapsSaved(Object value) {
    return '$value taps saved.';
  }

  @override
  String teamScoreTaps(Object value) {
    return '$value taps';
  }

  @override
  String get teamHighLowQuestion =>
      'Will today\'s hidden number be low (0-49) or high (50-99)?';

  @override
  String get teamLowRange => 'Low (0-49)';

  @override
  String get teamHighRange => 'High (50-99)';

  @override
  String get teamHighLowSavedFair =>
      'Choice saved. The daily number stays hidden here so everyone plays fair.';

  @override
  String get play => 'Play';

  @override
  String get teamBeatRecord => 'Beat record';

  @override
  String get teamDoneToday => 'Done today';

  @override
  String get teamBattles => 'Team battles';

  @override
  String get teamSignInHint => 'Sign in to join today\'s global battles.';

  @override
  String get globalBattles => 'Global battles';

  @override
  String teamUtcDayBoards(Object period) {
    return 'UTC day $period - everyone in the app shares these boards.';
  }

  @override
  String get teamYesterdaysChampions => 'Yesterday\'s champions';

  @override
  String teamChampionsSubtitle(Object period) {
    return 'UTC day $period - top score per battle. A notification goes out every day at 12:00 PM on this device.';
  }

  @override
  String get teamNoChampion => '-';

  @override
  String get teamTopPlayers => 'Top players';

  @override
  String get teamNoScoresYet => 'No scores yet - be the first.';

  @override
  String get teamWaitForGreenHint =>
      'Wait for GREEN. Early tap resets the round.';

  @override
  String get teamGreenTapNow => 'GREEN! Tap now.';

  @override
  String get teamTooEarlyWaitGreen => 'Too early! Wait for GREEN.';

  @override
  String get teamTapNow => 'TAP!';

  @override
  String get teamWaitEllipsis => 'Wait...';

  @override
  String get abort => 'Abort';

  @override
  String teamSecondsLeftTapAnywhere(Object seconds) {
    return '$seconds s left - tap anywhere';
  }

  @override
  String get team => 'Team';

  @override
  String get teamEmptyIntro =>
      'Build a six-player squad on the standard 2-2-2 pitch and train stats. Once you have a team, challenge friends from this tab or Online.';

  @override
  String get teamNoSquadYet => 'No squad yet';

  @override
  String get teamNoSquadDescription =>
      'Six players only on the same layout as everyone else - tap anyone later for name & photo, then train stats with skill points.';

  @override
  String get teamCreateTeam => 'Create team';

  @override
  String get teamBestLineupInApp => 'Best lineup in the app';

  @override
  String teamBestLineupSubtitle(Object monday) {
    return 'Top Power score this UTC week ($monday). Same rules as Lineup races - train, submit, climb.';
  }

  @override
  String get teamNoSubmissionsYet =>
      'No submissions yet - be first on the board.';

  @override
  String teamRankPowerRace(Object name) {
    return '$name - rank #1 - Power race';
  }

  @override
  String get teamPlayTogether => 'Play together';

  @override
  String get teamSameFriendsListHint =>
      'Same friends list as Home - challenge someone and they will see it on Online.';

  @override
  String get teamRefreshFriends => 'Refresh friends';

  @override
  String get teamNoFriendsHint =>
      'No friends yet - send requests from Home. When someone accepts, tap refresh here or open Online.';

  @override
  String get challenge => 'Challenge';

  @override
  String get teamSquadPulse => 'Squad pulse';

  @override
  String get teamSquadPulseSubtitle =>
      'Live preview of the three weekly race modes - train, then climb the shared leaderboard.';

  @override
  String get teamPowerRace => 'Power race';

  @override
  String get teamSpeedDash => 'Speed dash';

  @override
  String get teamBalance => 'Balance';

  @override
  String get teamRaceSubtitlePower => 'Sum of ATK+DEF+SPD+STM for all six.';

  @override
  String get teamRaceSubtitleSpeed => 'Each player: 2×SPD + STM.';

  @override
  String get teamRaceSubtitleBalance =>
      'Rewards high minimum stat per player (×15).';

  @override
  String lineupScored(Object score) {
    return 'Lineup scored: $score pts';
  }

  @override
  String get lineupRaces => 'Lineup races';

  @override
  String get refreshBoard => 'Refresh board';

  @override
  String teamRaceWeekUtc(Object mondayId) {
    return 'Week (UTC): $mondayId · everyone uses the same saved six from the cloud.';
  }

  @override
  String get submitLineupToRace => 'Submit lineup to this race';

  @override
  String get createTeamToEnter => 'Create a team to enter';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get teamNoEntriesYetBeFirstThisWeek =>
      'No entries yet - be first this week.';

  @override
  String get yourSquad => 'YOUR SQUAD';

  @override
  String teamSkillPointsLabel(Object points) {
    return '$points pts';
  }

  @override
  String get teamRenameTeam => 'Rename team';

  @override
  String get teamName => 'Team name';

  @override
  String teamStatPlusOne(Object label) {
    return '$label +1';
  }

  @override
  String teamSkillTrainingTitle(Object cost) {
    return 'Skill training ($cost pts → +1)';
  }

  @override
  String teamPlayerTrainingBalance(Object slot, Object name, Object points) {
    return 'Player $slot: $name · your balance: $points pts';
  }

  @override
  String get teamEarnMoreFromDailyChallenges =>
      'Earn more from daily challenges above.';

  @override
  String teamPlayerIndexOf(Object index, Object total) {
    return 'Player $index of $total';
  }

  @override
  String get teamEditPlayer => 'Edit player';

  @override
  String get teamPhoto => 'Photo';

  @override
  String get choose => 'Choose';

  @override
  String get teamDisplayName => 'Display name';

  @override
  String get teamStatsSkillTrainingOnly => 'Stats (skill training only)';

  @override
  String get teamRaiseStatsHint =>
      'Raise ATK, DEF, SPD, and STM from the training section above.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get tapToEdit => 'Tap to edit';

  @override
  String get teamDefenseShort => 'DEF';

  @override
  String get teamAttackShort => 'ATK';

  @override
  String get teamChallengePitchReportTitle => 'Daily pitch report';

  @override
  String get teamChallengePitchReportSubtitle =>
      'Same for every player - claim once per UTC day.';

  @override
  String get teamChallengeCrowdEnergyTitle => 'Crowd energy';

  @override
  String get teamChallengeCrowdEnergySubtitle =>
      'Publish any post on Home today (UTC).';

  @override
  String get teamChallengeMatchRhythmTitle => 'Match-day rhythm';

  @override
  String get teamChallengeMatchRhythmSubtitle =>
      'Play online today (UTC). Penalty: we log you when the match closes in the cloud; rim / fantasy / 1v1 count from live session rows.';

  @override
  String get teamDailyChallengesEveryone => 'Daily challenges (everyone)';

  @override
  String get teamDailyChallengesHint =>
      'Earn skill points, then train players (+1 stat for 15 pts). Squad must be saved to the cloud.';

  @override
  String get claimed => 'Claimed';

  @override
  String get claim => 'Claim';

  @override
  String teamBattleStatDelta(
    Object slot,
    Object stat,
    Object arrow,
    Object before,
    Object after,
  ) {
    return 'Player $slot: $stat $arrow $before -> $after';
  }

  @override
  String get teamBattleAcademyDialogBody =>
      'A quick solo match vs a rotating reserve side. Same Power total as lineup races.\n\n- Win: +18 skill pts - Tie: +12 - Loss: still +8\n- No stat changes - just a fun daily warm-up\n- Once per UTC day\n\nKick off?';

  @override
  String get teamBattleNotNow => 'Not now';

  @override
  String get teamBattleKickOff => 'Kick off';

  @override
  String get teamBattleAcademyFriendly => 'Academy friendly';

  @override
  String get teamBattleThisFriend => 'this friend';

  @override
  String get teamBattleSquadSpar => 'Squad spar';

  @override
  String teamBattleSquadSparDialogBody(Object name) {
    return 'Both squads are scored with the same Power formula as lineup races (sum of every player\'s ATK+DEF+SPD+STM).\n\n- Win: +20 skill pts and +1 random stat (max 99)\n- Tie: +8 skill pts each - stats unchanged\n- Loss: -1 random stat (min 40)\n\nOne spar per friend pair per UTC day. Higher risk, bigger rush.\n\nChallenge $name?';
  }

  @override
  String get battle => 'Battle';

  @override
  String teamBattleVictory(Object myScore, Object oppScore, Object points) {
    return 'Victory $myScore-$oppScore! +$points skill pts';
  }

  @override
  String teamBattleDefeat(Object myScore, Object oppScore) {
    return 'Defeat $myScore-$oppScore. Come back stronger tomorrow.';
  }

  @override
  String teamBattleDraw(Object myScore, Object oppScore, Object points) {
    return 'Draw $myScore-$oppScore - +$points skill pts each';
  }

  @override
  String teamBattleSparSettled(Object balance) {
    return 'Spar settled - balance $balance';
  }

  @override
  String get teamBattleBattlesForSkillPoints => 'Battles for skill points';

  @override
  String get teamBattleHeaderSubtitle =>
      'Academy friendly for a relaxed daily match, friend spars for high stakes, and Online duels for the full rush.';

  @override
  String get teamBattleChipWin => 'Win: pts + buff';

  @override
  String get teamBattleChipTie => 'Tie: safe pts';

  @override
  String get teamBattleChipLoss => 'Loss: stat hit';

  @override
  String get teamBattleAcademySubtitle =>
      'Solo scrim vs a named reserve side. Scores tick up live - no roster risk, and you always earn skill points.';

  @override
  String get teamBattleChipNoStatRisk => 'No stat risk';

  @override
  String get teamBattleChipDailyOnce => 'Daily once';

  @override
  String get teamBattleChipAlwaysPts => 'Always +pts';

  @override
  String get teamBattleKickOffAcademy => 'Kick off vs Academy XI';

  @override
  String get teamBattleTapAnimatedScoreboard =>
      'Tap for the animated scoreboard';

  @override
  String get teamBattleSquadSparFriends => 'Squad spar (friends)';

  @override
  String get teamBattleAddFriendsHint =>
      'Add friends from Home, then refresh. You need a saved squad and an accepted friend with a squad.';

  @override
  String get teamBattleLiveDuels => 'Live duels (Online tab)';

  @override
  String get teamBattleLiveDuelsSubtitle =>
      'Penalty, rock-paper-scissors, fantasy cards - head-to-head matches. Random roster stat swings apply in friend spar above; live games fuel your daily \"Match-day rhythm\" claim.';

  @override
  String get teamBattleOutcomeWin => 'Win - your Power edged them out!';

  @override
  String get teamBattleOutcomeLose =>
      'Narrow loss - reserve side had the edge today.';

  @override
  String get teamBattleOutcomeTie => 'Dead heat - split the difference.';

  @override
  String get teamBattleOutcomeComplete => 'Match complete';

  @override
  String teamBattleYouVs(Object opponent) {
    return 'You vs $opponent';
  }

  @override
  String get teamBattleYourSquad => 'Your squad';

  @override
  String get teamBattleTheirPower => 'Their Power';

  @override
  String teamBattlePointsBalance(Object points, Object balance) {
    return '+$points skill pts - balance $balance';
  }

  @override
  String get nice => 'Nice';
}
