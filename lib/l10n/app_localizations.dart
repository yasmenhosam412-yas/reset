import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get appTitle;

  /// No description provided for @loggedInSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged in successfully'**
  String get loggedInSuccessfully;

  /// No description provided for @loginHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you back in.'**
  String get loginHeroTitle;

  /// No description provided for @loginHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your feed, connect with people, and keep your activity in sync.'**
  String get loginHeroSubtitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validEmailRequired;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordAtLeast6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordAtLeast6;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @newHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get newHere;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreatedSuccessfully;

  /// No description provided for @signupFriendlyUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken. Please choose another one.'**
  String get signupFriendlyUsernameTaken;

  /// No description provided for @signupHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signupHeroTitle;

  /// No description provided for @signupHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join now and start building your profile and activity.'**
  String get signupHeroSubtitle;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'yourname'**
  String get usernameHint;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// No description provided for @usernameAtLeast3.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameAtLeast3;

  /// No description provided for @alreadyMember.
  ///
  /// In en, this message translates to:
  /// **'Already a member?'**
  String get alreadyMember;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @forgotOtpInstructionSnack.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email, then choose a new password.'**
  String get forgotOtpInstructionSnack;

  /// No description provided for @passwordUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Sign in with your new password.'**
  String get passwordUpdatedSnack;

  /// No description provided for @forgotHeroTitleStep1.
  ///
  /// In en, this message translates to:
  /// **'Recover your account'**
  String get forgotHeroTitleStep1;

  /// No description provided for @forgotHeroTitleStep2.
  ///
  /// In en, this message translates to:
  /// **'Verify and reset password'**
  String get forgotHeroTitleStep2;

  /// No description provided for @forgotHeroSubtitleStep1.
  ///
  /// In en, this message translates to:
  /// **'We will send a one-time recovery code to your email.'**
  String get forgotHeroSubtitleStep1;

  /// No description provided for @forgotHeroSubtitleStep2.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email and set a new password.'**
  String get forgotHeroSubtitleStep2;

  /// No description provided for @forgotStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Request code'**
  String get forgotStep1Title;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @rememberedIt.
  ///
  /// In en, this message translates to:
  /// **'Remembered it?'**
  String get rememberedIt;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @forgotStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Verify and update'**
  String get forgotStep2Title;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}'**
  String codeSentTo(Object email);

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @verificationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-8 digit code'**
  String get verificationCodeHint;

  /// No description provided for @codeRequired.
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get codeRequired;

  /// No description provided for @codeTooShort.
  ///
  /// In en, this message translates to:
  /// **'Code looks too short'**
  String get codeTooShort;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @atLeast6Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Chars;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @verifyAndUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Verify code & update password'**
  String get verifyAndUpdatePassword;

  /// No description provided for @wrongEmail.
  ///
  /// In en, this message translates to:
  /// **'Wrong email?'**
  String get wrongEmail;

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different one'**
  String get useDifferentEmail;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get newPost;

  /// No description provided for @postTypeDescriptionPost.
  ///
  /// In en, this message translates to:
  /// **'Post: regular community updates.'**
  String get postTypeDescriptionPost;

  /// No description provided for @postTypeDescriptionAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Announcement: for important updates.'**
  String get postTypeDescriptionAnnouncement;

  /// No description provided for @postTypeDescriptionCelebration.
  ///
  /// In en, this message translates to:
  /// **'Celebration: share wins and happy moments.'**
  String get postTypeDescriptionCelebration;

  /// No description provided for @postTypeDescriptionAds.
  ///
  /// In en, this message translates to:
  /// **'Ads: promote products, events, or offers.'**
  String get postTypeDescriptionAds;

  /// No description provided for @postTypePost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postTypePost;

  /// No description provided for @postTypeAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get postTypeAnnouncement;

  /// No description provided for @postTypeCelebration.
  ///
  /// In en, this message translates to:
  /// **'Celebration'**
  String get postTypeCelebration;

  /// No description provided for @postTypeAds.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get postTypeAds;

  /// No description provided for @adLink.
  ///
  /// In en, this message translates to:
  /// **'Ad link'**
  String get adLink;

  /// No description provided for @adLinkHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com'**
  String get adLinkHint;

  /// No description provided for @friendsVisibilityHint.
  ///
  /// In en, this message translates to:
  /// **'Friends only: only you and accepted friends can see this post.'**
  String get friendsVisibilityHint;

  /// No description provided for @generalVisibilityHint.
  ///
  /// In en, this message translates to:
  /// **'General post: visible to all users in the app.'**
  String get generalVisibilityHint;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @friendsOnly.
  ///
  /// In en, this message translates to:
  /// **'Friends only'**
  String get friendsOnly;

  /// No description provided for @postContentHint.
  ///
  /// In en, this message translates to:
  /// **'What is on your mind?'**
  String get postContentHint;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @allowReposts.
  ///
  /// In en, this message translates to:
  /// **'Allow reposts'**
  String get allowReposts;

  /// No description provided for @adsCannotRepost.
  ///
  /// In en, this message translates to:
  /// **'Ads cannot be reposted.'**
  String get adsCannotRepost;

  /// No description provided for @othersCanShare.
  ///
  /// In en, this message translates to:
  /// **'Others can share this to the home feed.'**
  String get othersCanShare;

  /// No description provided for @repostHidden.
  ///
  /// In en, this message translates to:
  /// **'Repost is hidden for this post.'**
  String get repostHidden;

  /// No description provided for @posting.
  ///
  /// In en, this message translates to:
  /// **'Posting...'**
  String get posting;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @postTextEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Post text cannot be empty.'**
  String get postTextEmptyError;

  /// No description provided for @adLinkInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Ad link is required and must be a valid http/https URL.'**
  String get adLinkInvalidError;

  /// No description provided for @react.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get react;

  /// No description provided for @tapAgainToRemoveReaction.
  ///
  /// In en, this message translates to:
  /// **'Tap again to remove your reaction.'**
  String get tapAgainToRemoveReaction;

  /// No description provided for @visitAd.
  ///
  /// In en, this message translates to:
  /// **'Visit ad'**
  String get visitAd;

  /// No description provided for @repostToHomeFeed.
  ///
  /// In en, this message translates to:
  /// **'Repost to home feed'**
  String get repostToHomeFeed;

  /// No description provided for @invalidAdLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid ad link.'**
  String get invalidAdLink;

  /// No description provided for @couldNotOpenAdLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open ad link.'**
  String get couldNotOpenAdLink;

  /// No description provided for @shared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shared;

  /// No description provided for @homeReactionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reaction} other{{count} reactions}}'**
  String homeReactionsCount(int count);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get editPost;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noCommentsYetBeFirst.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.\nBe the first to reply.'**
  String get noCommentsYetBeFirst;

  /// No description provided for @writeAComment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment...'**
  String get writeAComment;

  /// No description provided for @thisIsYourPost.
  ///
  /// In en, this message translates to:
  /// **'This is your post.'**
  String get thisIsYourPost;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get deletePost;

  /// No description provided for @alreadyConnectedNoRequestNeeded.
  ///
  /// In en, this message translates to:
  /// **'You are already connected - no new request needed.'**
  String get alreadyConnectedNoRequestNeeded;

  /// No description provided for @sendFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send friend request'**
  String get sendFriendRequest;

  /// No description provided for @sendChallenge.
  ///
  /// In en, this message translates to:
  /// **'Send challenge'**
  String get sendChallenge;

  /// No description provided for @deletePostQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get deletePostQuestion;

  /// No description provided for @deletePostMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes your post and its comments for everyone.'**
  String get deletePostMessage;

  /// No description provided for @challengeTarget.
  ///
  /// In en, this message translates to:
  /// **'Challenge {name}'**
  String challengeTarget(Object name);

  /// No description provided for @challengeInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Win the match for +10 team skill points (Team tab). Your friend loses nothing if they do not win.'**
  String get challengeInfoBody;

  /// No description provided for @chooseAGame.
  ///
  /// In en, this message translates to:
  /// **'Choose a game'**
  String get chooseAGame;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @explorePeople.
  ///
  /// In en, this message translates to:
  /// **'Explore people'**
  String get explorePeople;

  /// No description provided for @searchByUsername.
  ///
  /// In en, this message translates to:
  /// **'Search by username...'**
  String get searchByUsername;

  /// No description provided for @explorePeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 characters. Find someone new or add them as a friend.'**
  String get explorePeopleHint;

  /// No description provided for @jumpInMeetPlayers.
  ///
  /// In en, this message translates to:
  /// **'Jump in and meet players'**
  String get jumpInMeetPlayers;

  /// No description provided for @noUsernamesMatch.
  ///
  /// In en, this message translates to:
  /// **'No usernames match \"{query}\".'**
  String noUsernamesMatch(Object query);

  /// No description provided for @exploreLinkFriend.
  ///
  /// In en, this message translates to:
  /// **'Friends - open posts from the feed context'**
  String get exploreLinkFriend;

  /// No description provided for @exploreLinkPendingOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Request sent - waiting for them'**
  String get exploreLinkPendingOutgoing;

  /// No description provided for @exploreLinkPendingIncoming.
  ///
  /// In en, this message translates to:
  /// **'Wants to connect - accept on Profile'**
  String get exploreLinkPendingIncoming;

  /// No description provided for @exploreLinkNone.
  ///
  /// In en, this message translates to:
  /// **'Not connected yet'**
  String get exploreLinkNone;

  /// No description provided for @noPostsFromProfileYet.
  ///
  /// In en, this message translates to:
  /// **'No posts from this profile in your feed yet. Pull to refresh on Home.'**
  String get noPostsFromProfileYet;

  /// No description provided for @noPostsYetTapNewPost.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.\nTap New post to share something.'**
  String get noPostsYetTapNewPost;

  /// No description provided for @cantRepostOwnPost.
  ///
  /// In en, this message translates to:
  /// **'You can\'t repost your own post.'**
  String get cantRepostOwnPost;

  /// No description provided for @thisPostCannotBeReposted.
  ///
  /// In en, this message translates to:
  /// **'This post cannot be reposted.'**
  String get thisPostCannotBeReposted;

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @fromAuthor.
  ///
  /// In en, this message translates to:
  /// **'From {author}'**
  String fromAuthor(Object author);

  /// No description provided for @imageAttachedToRepost.
  ///
  /// In en, this message translates to:
  /// **'Image is attached to this repost.'**
  String get imageAttachedToRepost;

  /// No description provided for @addCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)...'**
  String get addCommentOptional;

  /// No description provided for @publishRepost.
  ///
  /// In en, this message translates to:
  /// **'Publish repost'**
  String get publishRepost;

  /// No description provided for @repostPublished.
  ///
  /// In en, this message translates to:
  /// **'Repost published'**
  String get repostPublished;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & security'**
  String get privacySecurity;

  /// No description provided for @rateTheApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get rateTheApp;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupport;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off to stop server pushes and in-app notification mirrors. Your device token is removed so nothing is sent until you turn this back on.'**
  String get pushNotificationsSubtitle;

  /// No description provided for @matchInvites.
  ///
  /// In en, this message translates to:
  /// **'Match invites'**
  String get matchInvites;

  /// No description provided for @matchInvitesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off: you won\'t see incoming invites and friends won\'t see you for online challenges'**
  String get matchInvitesSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutQuestion;

  /// No description provided for @signOutMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to use your account.'**
  String get signOutMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get signedOut;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon.'**
  String get comingSoon;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @friendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get friendRequests;

  /// No description provided for @noPendingFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending friend requests.'**
  String get noPendingFriendRequests;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get couldNotLoadProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @usernameAllowedHint.
  ///
  /// In en, this message translates to:
  /// **'letters, numbers, spaces, underscore'**
  String get usernameAllowedHint;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter a username'**
  String get enterUsername;

  /// No description provided for @usernameAllowedChars.
  ///
  /// In en, this message translates to:
  /// **'Use only letters, numbers, spaces, and underscore'**
  String get usernameAllowedChars;

  /// No description provided for @newPhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'New photo selected'**
  String get newPhotoSelected;

  /// No description provided for @chooseProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose profile photo'**
  String get chooseProfilePhoto;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @noNewPhoto.
  ///
  /// In en, this message translates to:
  /// **'No new photo'**
  String get noNewPhoto;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up'**
  String get allCaughtUp;

  /// No description provided for @notificationsCaughtUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You will only see clear alerts for likes, comments, invites, and room invites here. Pull down to refresh for the latest updates.'**
  String get notificationsCaughtUpSubtitle;

  /// No description provided for @notifSomeoneReacted.
  ///
  /// In en, this message translates to:
  /// **'Someone reacted to your post.'**
  String get notifSomeoneReacted;

  /// No description provided for @notifSomeoneCommented.
  ///
  /// In en, this message translates to:
  /// **'Someone commented on your post.'**
  String get notifSomeoneCommented;

  /// No description provided for @notifFriendInvite.
  ///
  /// In en, this message translates to:
  /// **'You received a new friend invite.'**
  String get notifFriendInvite;

  /// No description provided for @notifRoomInviteWaiting.
  ///
  /// In en, this message translates to:
  /// **'You have a room invite waiting.'**
  String get notifRoomInviteWaiting;

  /// No description provided for @notifNewNotification.
  ///
  /// In en, this message translates to:
  /// **'You have a new notification.'**
  String get notifNewNotification;

  /// No description provided for @notifReviewInvite.
  ///
  /// In en, this message translates to:
  /// **'Review this invite and decide whether to accept or decline.'**
  String get notifReviewInvite;

  /// No description provided for @notifReviewInviteShort.
  ///
  /// In en, this message translates to:
  /// **'Review this invite and choose Accept or Decline.'**
  String get notifReviewInviteShort;

  /// No description provided for @notifPostLikeOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Open the post to see who reacted and join the conversation.'**
  String get notifPostLikeOpenHint;

  /// No description provided for @notifPostCommentOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Open comments to read and reply from your feed.'**
  String get notifPostCommentOpenHint;

  /// No description provided for @notifFriendRequestAcceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'This friend request was accepted.'**
  String get notifFriendRequestAcceptedStatus;

  /// No description provided for @notifFriendRequestNoLongerPending.
  ///
  /// In en, this message translates to:
  /// **'This friend request is no longer pending.'**
  String get notifFriendRequestNoLongerPending;

  /// No description provided for @notifPartyRoomInviteOpenHint.
  ///
  /// In en, this message translates to:
  /// **'Join your room invite from the Online tab when you are ready.'**
  String get notifPartyRoomInviteOpenHint;

  /// No description provided for @friendRequestNoLongerValid.
  ///
  /// In en, this message translates to:
  /// **'This friend request is no longer valid (account/request removed).'**
  String get friendRequestNoLongerValid;

  /// No description provided for @friendRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Friend request accepted.'**
  String get friendRequestAccepted;

  /// No description provided for @friendRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Friend request declined.'**
  String get friendRequestDeclined;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileUpdated;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined.'**
  String get declined;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @matchAccepted.
  ///
  /// In en, this message translates to:
  /// **'Match accepted'**
  String get matchAccepted;

  /// No description provided for @opponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get opponent;

  /// No description provided for @game.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @couldNotLoadOnline.
  ///
  /// In en, this message translates to:
  /// **'Could not load Online'**
  String get couldNotLoadOnline;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @onlineHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match with friends, party rooms, and quick games'**
  String get onlineHeaderSubtitle;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @tapFriendToChallenge.
  ///
  /// In en, this message translates to:
  /// **'Tap someone to send an online challenge'**
  String get tapFriendToChallenge;

  /// No description provided for @partyRooms.
  ///
  /// In en, this message translates to:
  /// **'Party rooms'**
  String get partyRooms;

  /// No description provided for @partyRoomsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invites and rooms you have joined'**
  String get partyRoomsSubtitle;

  /// No description provided for @playInvites.
  ///
  /// In en, this message translates to:
  /// **'Play invites'**
  String get playInvites;

  /// No description provided for @playInvitesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Friends invited you to a match'**
  String get playInvitesSubtitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noPendingInvites.
  ///
  /// In en, this message translates to:
  /// **'No pending invites.'**
  String get noPendingInvites;

  /// No description provided for @activeMatches.
  ///
  /// In en, this message translates to:
  /// **'Active matches'**
  String get activeMatches;

  /// No description provided for @tapReadyWhenSet.
  ///
  /// In en, this message translates to:
  /// **'Tap Ready when you are set to play'**
  String get tapReadyWhenSet;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @gamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice vs AI or open a party room'**
  String get gamesSubtitle;

  /// No description provided for @rateAppFromPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Rate us from your phone\'s app store once the app is published.'**
  String get rateAppFromPhoneHint;

  /// No description provided for @couldNotOpenStoreLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the store link.'**
  String get couldNotOpenStoreLink;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountQuestion;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and data.'**
  String get deleteAccountMessage;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get failedToDeleteAccount;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @thisPlayer.
  ///
  /// In en, this message translates to:
  /// **'this player'**
  String get thisPlayer;

  /// No description provided for @removeFriendQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove friend?'**
  String get removeFriendQuestion;

  /// No description provided for @removeFriendMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from your friends. You can send a new request later from Home.'**
  String removeFriendMessage(Object name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removedFromFriends.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from friends'**
  String removedFromFriends(Object name);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYet;

  /// No description provided for @friendsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Accept requests below or send one from someone\'s post on Home.'**
  String get friendsEmptyHint;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @removeFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get removeFriend;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @youWon.
  ///
  /// In en, this message translates to:
  /// **'You won'**
  String get youWon;

  /// No description provided for @youLost.
  ///
  /// In en, this message translates to:
  /// **'You lost'**
  String get youLost;

  /// No description provided for @historyAndLiveInvites.
  ///
  /// In en, this message translates to:
  /// **'History & live invites'**
  String get historyAndLiveInvites;

  /// No description provided for @loadingYourMatches.
  ///
  /// In en, this message translates to:
  /// **'Loading your matches...'**
  String get loadingYourMatches;

  /// No description provided for @couldNotLoadChallenges.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load challenges'**
  String get couldNotLoadChallenges;

  /// No description provided for @noChallengesYet.
  ///
  /// In en, this message translates to:
  /// **'No challenges yet'**
  String get noChallengesYet;

  /// No description provided for @challengesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend from Home or the Online tab - finished games show up here with results.'**
  String get challengesEmptyHint;

  /// No description provided for @vsPrefix.
  ///
  /// In en, this message translates to:
  /// **'vs '**
  String get vsPrefix;

  /// No description provided for @helpGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get helpGetStarted;

  /// No description provided for @helpQMainTabs.
  ///
  /// In en, this message translates to:
  /// **'What are the main tabs?'**
  String get helpQMainTabs;

  /// No description provided for @helpAMainTabs.
  ///
  /// In en, this message translates to:
  /// **'Home is your social feed and friends. Online is live challenges and games with people you know. Team is your six-player squad, training, and squad battles. Profile is your account, requests, and settings.'**
  String get helpAMainTabs;

  /// No description provided for @helpQAddFriends.
  ///
  /// In en, this message translates to:
  /// **'How do I add friends?'**
  String get helpQAddFriends;

  /// No description provided for @helpAAddFriends.
  ///
  /// In en, this message translates to:
  /// **'Send a request from Home. The other person accepts under Profile -> Friend requests. You both need an account.'**
  String get helpAAddFriends;

  /// No description provided for @helpQTeamTab.
  ///
  /// In en, this message translates to:
  /// **'How does the Team tab work?'**
  String get helpQTeamTab;

  /// No description provided for @helpATeamTab.
  ///
  /// In en, this message translates to:
  /// **'Create a team, name your players, then train stats with skill points. You can run daily challenges, lineup races, friend spars, and a solo Academy friendly for extra points-check each card for rules and limits.'**
  String get helpATeamTab;

  /// No description provided for @helpQSaveSquad.
  ///
  /// In en, this message translates to:
  /// **'Why can\'t I save my squad?'**
  String get helpQSaveSquad;

  /// No description provided for @helpASaveSquad.
  ///
  /// In en, this message translates to:
  /// **'Make sure you are signed in and online. Open Team after login so your squad can sync to your profile.'**
  String get helpASaveSquad;

  /// No description provided for @helpTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get helpTroubleshooting;

  /// No description provided for @helpQStuck.
  ///
  /// In en, this message translates to:
  /// **'Something looks stuck'**
  String get helpQStuck;

  /// No description provided for @helpAStuck.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh on Profile. For Online, use refresh where shown. If a game won\'t load, go back and open the challenge again.'**
  String get helpAStuck;

  /// No description provided for @helpQSignedOut.
  ///
  /// In en, this message translates to:
  /// **'I signed out by accident'**
  String get helpQSignedOut;

  /// No description provided for @helpASignedOut.
  ///
  /// In en, this message translates to:
  /// **'Sign in again from the login screen with the same email. Your cloud data stays tied to your account.'**
  String get helpASignedOut;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @privacyYourAccountData.
  ///
  /// In en, this message translates to:
  /// **'Your account and data'**
  String get privacyYourAccountData;

  /// No description provided for @privacyYourAccountDataBody.
  ///
  /// In en, this message translates to:
  /// **'You sign in with email and password. Your session is managed securely by our backend (Supabase Auth). We store the profile information you choose to save, such as display name and avatar.'**
  String get privacyYourAccountDataBody;

  /// No description provided for @privacyDataUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'What we use your data for'**
  String get privacyDataUsageTitle;

  /// No description provided for @privacyDataUsageHome.
  ///
  /// In en, this message translates to:
  /// **'Home and social features: posts, comments, likes, and friend requests.'**
  String get privacyDataUsageHome;

  /// No description provided for @privacyDataUsageOnline.
  ///
  /// In en, this message translates to:
  /// **'Online play: challenges, match state, and related game records.'**
  String get privacyDataUsageOnline;

  /// No description provided for @privacyDataUsageTeam.
  ///
  /// In en, this message translates to:
  /// **'Team mode: squad lineup, skill points, daily challenges, and leaderboards.'**
  String get privacyDataUsageTeam;

  /// No description provided for @privacyFriendsVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends and visibility'**
  String get privacyFriendsVisibilityTitle;

  /// No description provided for @privacyFriendsVisibilityBody.
  ///
  /// In en, this message translates to:
  /// **'When you accept a friend request, each of you can interact in features that require friends (for example invites and team battles). Declined requests are not shown as active connections.'**
  String get privacyFriendsVisibilityBody;

  /// No description provided for @privacySecurityTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security tips'**
  String get privacySecurityTipsTitle;

  /// No description provided for @privacyTipStrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Use a strong, unique password for this app.'**
  String get privacyTipStrongPassword;

  /// No description provided for @privacyTipSignOutShared.
  ///
  /// In en, this message translates to:
  /// **'Sign out from Profile when using a shared device.'**
  String get privacyTipSignOutShared;

  /// No description provided for @privacyTipUnauthorizedAccess.
  ///
  /// In en, this message translates to:
  /// **'If you suspect unauthorized access, change your password and sign out everywhere from your account provider if available.'**
  String get privacyTipUnauthorizedAccess;

  /// No description provided for @privacyQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get privacyQuestionsTitle;

  /// No description provided for @privacyQuestionsBody.
  ///
  /// In en, this message translates to:
  /// **'This screen is a product summary, not a legal contract. For formal terms or data requests, contact the team that operates this app. Use the full privacy policy link below for the detailed version.'**
  String get privacyQuestionsBody;

  /// No description provided for @privacyFullPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Full privacy policy'**
  String get privacyFullPolicyTitle;

  /// No description provided for @privacyFullPolicyOpen.
  ///
  /// In en, this message translates to:
  /// **'View in browser'**
  String get privacyFullPolicyOpen;

  /// No description provided for @privacySafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety and reporting'**
  String get privacySafetyTitle;

  /// No description provided for @privacySafetyBody.
  ///
  /// In en, this message translates to:
  /// **'Joy lets everyone share posts. If you see abuse, someone at risk, or illegal material—including anything that sexualizes minors—email {email} with what you saw and any details that help us find the post (for example author name and approximate time). We review reports and act per our rules and applicable law.'**
  String privacySafetyBody(Object email);

  /// No description provided for @privacyCouldNotOpenPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open the privacy policy link.'**
  String get privacyCouldNotOpenPolicyLink;

  /// No description provided for @practiceVsAi.
  ///
  /// In en, this message translates to:
  /// **'Practice vs AI'**
  String get practiceVsAi;

  /// No description provided for @singleDeviceNotOnlineMatch.
  ///
  /// In en, this message translates to:
  /// **'Single device - not an online match.'**
  String get singleDeviceNotOnlineMatch;

  /// No description provided for @singleDeviceChallengeFriendHint.
  ///
  /// In en, this message translates to:
  /// **'Single device - challenge a friend online for a real duel.'**
  String get singleDeviceChallengeFriendHint;

  /// No description provided for @singleDeviceSameDuelHint.
  ///
  /// In en, this message translates to:
  /// **'Single device - same duel online vs a friend.'**
  String get singleDeviceSameDuelHint;

  /// No description provided for @vsAiNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'{title} vs AI is not available yet.'**
  String vsAiNotAvailableYet(Object title);

  /// No description provided for @createRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Create {title} room'**
  String createRoomTitle(Object title);

  /// No description provided for @roomSize.
  ///
  /// In en, this message translates to:
  /// **'Room size'**
  String get roomSize;

  /// No description provided for @playersMax.
  ///
  /// In en, this message translates to:
  /// **'{count} players max'**
  String playersMax(Object count);

  /// No description provided for @inviteExactlyFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite exactly {count} friends'**
  String inviteExactlyFriends(Object count);

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create room'**
  String get createRoom;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noFriendsYetAcceptFromHome.
  ///
  /// In en, this message translates to:
  /// **'No friends yet. Accept requests from Home.'**
  String get noFriendsYetAcceptFromHome;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @invitedYouToPlay.
  ///
  /// In en, this message translates to:
  /// **' invited you to play '**
  String get invitedYouToPlay;

  /// No description provided for @activeMatchesMultiHint.
  ///
  /// In en, this message translates to:
  /// **'Each card is a separate game. Mark Ready per match; when both players are ready on a card, you can start that game from there.'**
  String get activeMatchesMultiHint;

  /// No description provided for @bothPlayersReady.
  ///
  /// In en, this message translates to:
  /// **'Both players ready.'**
  String get bothPlayersReady;

  /// No description provided for @readyStatusLine.
  ///
  /// In en, this message translates to:
  /// **'You: {youStatus} - Them: {themStatus}'**
  String readyStatusLine(Object youStatus, Object themStatus);

  /// No description provided for @notReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready'**
  String get notReady;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @waitingForOpponent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent'**
  String get waitingForOpponent;

  /// No description provided for @noPartyRoomInvitesYet.
  ///
  /// In en, this message translates to:
  /// **'No party room invites yet.'**
  String get noPartyRoomInvitesYet;

  /// No description provided for @inHostsPartyRoom.
  ///
  /// In en, this message translates to:
  /// **'In {host}\'s party room'**
  String inHostsPartyRoom(Object host);

  /// No description provided for @hostInvitedYou.
  ///
  /// In en, this message translates to:
  /// **'{host} invited you'**
  String hostInvitedYou(Object host);

  /// No description provided for @gameUpToPlayers.
  ///
  /// In en, this message translates to:
  /// **'{game} - up to {players} players'**
  String gameUpToPlayers(Object game, Object players);

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @openLobby.
  ///
  /// In en, this message translates to:
  /// **'Open lobby'**
  String get openLobby;

  /// No description provided for @joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join room'**
  String get joinRoom;

  /// No description provided for @aPlayer.
  ///
  /// In en, this message translates to:
  /// **'A player'**
  String get aPlayer;

  /// No description provided for @playerLeftGameRoom.
  ///
  /// In en, this message translates to:
  /// **'{name} left the game room.'**
  String playerLeftGameRoom(Object name);

  /// No description provided for @playersLeftGameRoom.
  ///
  /// In en, this message translates to:
  /// **'{count} players left the game room.'**
  String playersLeftGameRoom(int count);

  /// No description provided for @unsupportedRoomGame.
  ///
  /// In en, this message translates to:
  /// **'Unsupported room game.'**
  String get unsupportedRoomGame;

  /// No description provided for @openSlot.
  ///
  /// In en, this message translates to:
  /// **'Open slot'**
  String get openSlot;

  /// No description provided for @slotNumber.
  ///
  /// In en, this message translates to:
  /// **'SLOT {index}'**
  String slotNumber(int index);

  /// No description provided for @waitingForInvite.
  ///
  /// In en, this message translates to:
  /// **'Waiting for invite...'**
  String get waitingForInvite;

  /// No description provided for @readyRoom.
  ///
  /// In en, this message translates to:
  /// **'READY ROOM'**
  String get readyRoom;

  /// No description provided for @readyRoomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Friends accept the invite under Online -> Party room invites. No code to copy - the run starts when every slot is filled.'**
  String get readyRoomSubtitle;

  /// No description provided for @joinedOutOf.
  ///
  /// In en, this message translates to:
  /// **'{joined} / {max}'**
  String joinedOutOf(int joined, int max);

  /// No description provided for @fullSquad.
  ///
  /// In en, this message translates to:
  /// **'FULL SQUAD'**
  String get fullSquad;

  /// No description provided for @recruiting.
  ///
  /// In en, this message translates to:
  /// **'RECRUITING'**
  String get recruiting;

  /// No description provided for @roster.
  ///
  /// In en, this message translates to:
  /// **'ROSTER'**
  String get roster;

  /// No description provided for @launchGame.
  ///
  /// In en, this message translates to:
  /// **'LAUNCH GAME'**
  String get launchGame;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'WAITING FOR PLAYERS'**
  String get waitingForPlayers;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @playerNumber.
  ///
  /// In en, this message translates to:
  /// **'Player {number}'**
  String playerNumber(int number);

  /// No description provided for @flashMatchOnlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Each round gets harder with more icons and stronger penalties; gentle reshuffle appears only in late rounds - {rounds} rounds. Lower total time wins.'**
  String flashMatchOnlineDesc(int rounds);

  /// No description provided for @flashMatchOfflineDesc.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone: {rounds} rounds each; harder via grid growth and penalties, with light late-round reshuffle (time window stays fair). Lowest total wins.'**
  String flashMatchOfflineDesc(int rounds);

  /// No description provided for @loadingRoom.
  ///
  /// In en, this message translates to:
  /// **'Loading room...'**
  String get loadingRoom;

  /// No description provided for @waitingJoinedOutOf.
  ///
  /// In en, this message translates to:
  /// **'Waiting: {joined} / {max}'**
  String waitingJoinedOutOf(int joined, int max);

  /// No description provided for @tapStartWhenReady.
  ///
  /// In en, this message translates to:
  /// **'Tap start when ready.'**
  String get tapStartWhenReady;

  /// No description provided for @playerTurnNext.
  ///
  /// In en, this message translates to:
  /// **'{player} - your turn next.'**
  String playerTurnNext(Object player);

  /// No description provided for @runComplete.
  ///
  /// In en, this message translates to:
  /// **'Run complete!'**
  String get runComplete;

  /// No description provided for @matchOver.
  ///
  /// In en, this message translates to:
  /// **'Match over!'**
  String get matchOver;

  /// No description provided for @playerRoundProgress.
  ///
  /// In en, this message translates to:
  /// **'{player} · Round {round} / {total}'**
  String playerRoundProgress(Object player, int round, int total);

  /// No description provided for @memorize.
  ///
  /// In en, this message translates to:
  /// **'MEMORIZE'**
  String get memorize;

  /// No description provided for @flashMatchCueMetaBasic.
  ///
  /// In en, this message translates to:
  /// **'{flashMs} ms · {choices} choices'**
  String flashMatchCueMetaBasic(int flashMs, int choices);

  /// No description provided for @flashMatchCueMetaWithReshuffle.
  ///
  /// In en, this message translates to:
  /// **'{flashMs} ms · {choices} choices · reshuffle {scrambleMs}ms'**
  String flashMatchCueMetaWithReshuffle(
    int flashMs,
    int choices,
    int scrambleMs,
  );

  /// No description provided for @tapTheMatch.
  ///
  /// In en, this message translates to:
  /// **'TAP THE MATCH'**
  String get tapTheMatch;

  /// No description provided for @penaltyMs.
  ///
  /// In en, this message translates to:
  /// **'Penalty +{ms} ms'**
  String penaltyMs(int ms);

  /// No description provided for @startNextPlayer.
  ///
  /// In en, this message translates to:
  /// **'START NEXT PLAYER'**
  String get startNextPlayer;

  /// No description provided for @startMatch.
  ///
  /// In en, this message translates to:
  /// **'START MATCH'**
  String get startMatch;

  /// No description provided for @winnerWithMs.
  ///
  /// In en, this message translates to:
  /// **'Winner: {name} ({ms} ms)'**
  String winnerWithMs(Object name, int ms);

  /// No description provided for @tieAtMsPlayers.
  ///
  /// In en, this message translates to:
  /// **'Tie at {ms} ms: {players}'**
  String tieAtMsPlayers(int ms, Object players);

  /// No description provided for @totalMs.
  ///
  /// In en, this message translates to:
  /// **'Total: {ms} ms'**
  String totalMs(int ms);

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @roomBoard.
  ///
  /// In en, this message translates to:
  /// **'Room board'**
  String get roomBoard;

  /// No description provided for @noScoresYet.
  ///
  /// In en, this message translates to:
  /// **'No scores yet.'**
  String get noScoresYet;

  /// No description provided for @totalMsLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} ms'**
  String totalMsLabel(Object value);

  /// No description provided for @totals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get totals;

  /// No description provided for @rpsInvalidThrow.
  ///
  /// In en, this message translates to:
  /// **'Invalid throw'**
  String get rpsInvalidThrow;

  /// No description provided for @rpsNotInThisMatch.
  ///
  /// In en, this message translates to:
  /// **'You are not in this match'**
  String get rpsNotInThisMatch;

  /// No description provided for @rpsMatchAlreadyFinished.
  ///
  /// In en, this message translates to:
  /// **'Match already finished'**
  String get rpsMatchAlreadyFinished;

  /// No description provided for @rpsAlreadyLockedForRound.
  ///
  /// In en, this message translates to:
  /// **'Already locked for this round'**
  String get rpsAlreadyLockedForRound;

  /// No description provided for @roundComplete.
  ///
  /// In en, this message translates to:
  /// **'Round complete'**
  String get roundComplete;

  /// No description provided for @drawReplayRound.
  ///
  /// In en, this message translates to:
  /// **'Draw - replay the round'**
  String get drawReplayRound;

  /// No description provided for @youTakeRound.
  ///
  /// In en, this message translates to:
  /// **'You take the round'**
  String get youTakeRound;

  /// No description provided for @aiTakesRound.
  ///
  /// In en, this message translates to:
  /// **'AI takes the round'**
  String get aiTakesRound;

  /// No description provided for @challengerWinsRound.
  ///
  /// In en, this message translates to:
  /// **'Challenger wins the round'**
  String get challengerWinsRound;

  /// No description provided for @hostWinsRound.
  ///
  /// In en, this message translates to:
  /// **'Host wins the round'**
  String get hostWinsRound;

  /// No description provided for @opponentTakesRound.
  ///
  /// In en, this message translates to:
  /// **'{name} takes the round'**
  String opponentTakesRound(Object name);

  /// No description provided for @couldNotResetBout.
  ///
  /// In en, this message translates to:
  /// **'Could not reset the bout. Check connection, then try again.'**
  String get couldNotResetBout;

  /// No description provided for @rpsSetNumber.
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String rpsSetNumber(int number);

  /// No description provided for @chooseYourThrow.
  ///
  /// In en, this message translates to:
  /// **'Choose your throw'**
  String get chooseYourThrow;

  /// No description provided for @boutFinished.
  ///
  /// In en, this message translates to:
  /// **'Bout finished'**
  String get boutFinished;

  /// No description provided for @tapCardRevealVs.
  ///
  /// In en, this message translates to:
  /// **'Tap a card - simultaneous reveal vs {name}'**
  String tapCardRevealVs(Object name);

  /// No description provided for @waitingForRound.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the round...'**
  String get waitingForRound;

  /// No description provided for @sendingYourPick.
  ///
  /// In en, this message translates to:
  /// **'Sending your pick...'**
  String get sendingYourPick;

  /// No description provided for @opponentStillChoosing.
  ///
  /// In en, this message translates to:
  /// **'Opponent is still choosing...'**
  String get opponentStillChoosing;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'AI is thinking...'**
  String get aiThinking;

  /// No description provided for @rpsRock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get rpsRock;

  /// No description provided for @rpsPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get rpsPaper;

  /// No description provided for @rpsScissors.
  ///
  /// In en, this message translates to:
  /// **'Scissors'**
  String get rpsScissors;

  /// No description provided for @throwLockedIn.
  ///
  /// In en, this message translates to:
  /// **'Throw locked in'**
  String get throwLockedIn;

  /// No description provided for @hiddenUntilBothThrow.
  ///
  /// In en, this message translates to:
  /// **'Hidden from your opponent until both sides throw.'**
  String get hiddenUntilBothThrow;

  /// No description provided for @aiPickingNext.
  ///
  /// In en, this message translates to:
  /// **'Hang tight - AI is picking next.'**
  String get aiPickingNext;

  /// No description provided for @scoreboard.
  ///
  /// In en, this message translates to:
  /// **'Scoreboard'**
  String get scoreboard;

  /// No description provided for @firstToRoundWinsTakesBout.
  ///
  /// In en, this message translates to:
  /// **'First to {count} round wins takes the bout'**
  String firstToRoundWinsTakesBout(int count);

  /// No description provided for @throwLabelWithHint.
  ///
  /// In en, this message translates to:
  /// **'Throw {label}. {hint}'**
  String throwLabelWithHint(Object label, Object hint);

  /// No description provided for @crushesScissors.
  ///
  /// In en, this message translates to:
  /// **'Crushes scissors'**
  String get crushesScissors;

  /// No description provided for @coversRock.
  ///
  /// In en, this message translates to:
  /// **'Covers rock'**
  String get coversRock;

  /// No description provided for @cutsPaper.
  ///
  /// In en, this message translates to:
  /// **'Cuts paper'**
  String get cutsPaper;

  /// No description provided for @deadHeat.
  ///
  /// In en, this message translates to:
  /// **'Dead heat'**
  String get deadHeat;

  /// No description provided for @honorSharedRematch.
  ///
  /// In en, this message translates to:
  /// **'Honor shared - rematch for the crown?'**
  String get honorSharedRematch;

  /// No description provided for @whatABoutSoakItIn.
  ///
  /// In en, this message translates to:
  /// **'What a bout - soak it in!'**
  String get whatABoutSoakItIn;

  /// No description provided for @closeFightRematch.
  ///
  /// In en, this message translates to:
  /// **'Close fight - one tap away from a rematch.'**
  String get closeFightRematch;

  /// No description provided for @challengerSideWins.
  ///
  /// In en, this message translates to:
  /// **'Challenger side wins'**
  String get challengerSideWins;

  /// No description provided for @hostSideWins.
  ///
  /// In en, this message translates to:
  /// **'Host side wins'**
  String get hostSideWins;

  /// No description provided for @boutOver.
  ///
  /// In en, this message translates to:
  /// **'Bout over'**
  String get boutOver;

  /// No description provided for @rpsShareBody.
  ///
  /// In en, this message translates to:
  /// **'Rock paper scissors vs {opponent}\nFinal: {leftScore} — {rightScore} ({leftLabel} / {rightLabel})\n{headline}'**
  String rpsShareBody(
    Object opponent,
    int leftScore,
    int rightScore,
    Object leftLabel,
    Object rightLabel,
    Object headline,
  );

  /// No description provided for @youWinDuelScore.
  ///
  /// In en, this message translates to:
  /// **'You win the duel {mine}–{opp}'**
  String youWinDuelScore(int mine, int opp);

  /// No description provided for @opponentWinsDuelScore.
  ///
  /// In en, this message translates to:
  /// **'{name} wins the duel {mine}–{opp}'**
  String opponentWinsDuelScore(Object name, int mine, int opp);

  /// No description provided for @pickOnlyFromSquadSheet.
  ///
  /// In en, this message translates to:
  /// **'Pick only players from your squad sheet.'**
  String get pickOnlyFromSquadSheet;

  /// No description provided for @couldNotSubmitPicks.
  ///
  /// In en, this message translates to:
  /// **'Could not submit picks'**
  String get couldNotSubmitPicks;

  /// No description provided for @alreadySubmittedOrSyncIssue.
  ///
  /// In en, this message translates to:
  /// **'Already submitted or sync issue'**
  String get alreadySubmittedOrSyncIssue;

  /// No description provided for @youTakeRoundZones.
  ///
  /// In en, this message translates to:
  /// **'You take this round ({you}–{opp} zones)'**
  String youTakeRoundZones(int you, int opp);

  /// No description provided for @opponentTakesRoundZones.
  ///
  /// In en, this message translates to:
  /// **'{name} takes this round ({you}–{opp} zones)'**
  String opponentTakesRoundZones(Object name, int you, int opp);

  /// No description provided for @zonesDrawnYouEdgeStrength.
  ///
  /// In en, this message translates to:
  /// **'Zones drawn - you edge on strength ({you}–{opp})'**
  String zonesDrawnYouEdgeStrength(int you, int opp);

  /// No description provided for @zonesDrawnOpponentEdges.
  ///
  /// In en, this message translates to:
  /// **'Zones drawn - {name} edges ({you}–{opp})'**
  String zonesDrawnOpponentEdges(Object name, int you, int opp);

  /// No description provided for @honorsEvenDrawnRoundNoPoint.
  ///
  /// In en, this message translates to:
  /// **'Honors even - drawn round (no point)'**
  String get honorsEvenDrawnRoundNoPoint;

  /// No description provided for @couldNotSyncRoundTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Could not sync round - try again'**
  String get couldNotSyncRoundTryAgain;

  /// No description provided for @couldNotStartRematch.
  ///
  /// In en, this message translates to:
  /// **'Could not start a rematch. Check connection, then try again.'**
  String get couldNotStartRematch;

  /// No description provided for @fantasyYourSquadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{cards} cards · start {starters} · read suit vs pitch call per zone'**
  String fantasyYourSquadSubtitle(int cards, int starters);

  /// No description provided for @lastRound.
  ///
  /// In en, this message translates to:
  /// **'Last round'**
  String get lastRound;

  /// No description provided for @cardsLockedSeeResultBelow.
  ///
  /// In en, this message translates to:
  /// **'Cards locked - see result below'**
  String get cardsLockedSeeResultBelow;

  /// No description provided for @startersCount.
  ///
  /// In en, this message translates to:
  /// **'Starters ({picked}/{total})'**
  String startersCount(int picked, int total);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @lockLineup.
  ///
  /// In en, this message translates to:
  /// **'Lock lineup'**
  String get lockLineup;

  /// No description provided for @lineupLocked.
  ///
  /// In en, this message translates to:
  /// **'Lineup locked'**
  String get lineupLocked;

  /// No description provided for @waitingForOpponentToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to submit...'**
  String waitingForOpponentToSubmit(Object name);

  /// No description provided for @nextRoundScoreTarget.
  ///
  /// In en, this message translates to:
  /// **'Next round ({mine}–{opp} · first to {target})'**
  String nextRoundScoreTarget(int mine, int opp, int target);

  /// No description provided for @fantasyDuelShareBody.
  ///
  /// In en, this message translates to:
  /// **'Fantasy card duel vs {opponent}\nRound wins: {mine} — {opp} (first to {target})\n{summary}'**
  String fantasyDuelShareBody(
    Object opponent,
    int mine,
    int opp,
    int target,
    Object summary,
  );

  /// No description provided for @fantasyZoneLeftWing.
  ///
  /// In en, this message translates to:
  /// **'Left wing'**
  String get fantasyZoneLeftWing;

  /// No description provided for @fantasyZoneNo10.
  ///
  /// In en, this message translates to:
  /// **'No. 10'**
  String get fantasyZoneNo10;

  /// No description provided for @fantasyZoneWideBack.
  ///
  /// In en, this message translates to:
  /// **'Wide back'**
  String get fantasyZoneWideBack;

  /// No description provided for @matchday.
  ///
  /// In en, this message translates to:
  /// **'Matchday'**
  String get matchday;

  /// No description provided for @vsUpper.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vsUpper;

  /// No description provided for @squadManager.
  ///
  /// In en, this message translates to:
  /// **'Squad manager'**
  String get squadManager;

  /// No description provided for @roundNumber.
  ///
  /// In en, this message translates to:
  /// **'ROUND {number}'**
  String roundNumber(int number);

  /// No description provided for @firstToRoundWinsVsFriend.
  ///
  /// In en, this message translates to:
  /// **'First to {count} round wins · vs friend'**
  String firstToRoundWinsVsFriend(int count);

  /// No description provided for @firstToRoundWins.
  ///
  /// In en, this message translates to:
  /// **'First to {count} round wins'**
  String firstToRoundWins(int count);

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String secondsShort(int seconds);

  /// No description provided for @howDuelWorks.
  ///
  /// In en, this message translates to:
  /// **'How the duel works'**
  String get howDuelWorks;

  /// No description provided for @tapToExpandRules.
  ///
  /// In en, this message translates to:
  /// **'Tap to expand rules'**
  String get tapToExpandRules;

  /// No description provided for @fantasyRule1.
  ///
  /// In en, this message translates to:
  /// **'You draw {squadSize} cards — shirt # is base value. Each card has a suit (Blitz / Maestro / Iron) from its role.'**
  String fantasyRule1(int squadSize);

  /// No description provided for @fantasyRule2.
  ///
  /// In en, this message translates to:
  /// **'Tap {starters} cards in lock order: {zone1} -> {zone2} -> {zone3}.'**
  String fantasyRule2(int starters, Object zone1, Object zone2, Object zone3);

  /// No description provided for @fantasyRule3.
  ///
  /// In en, this message translates to:
  /// **'The pitch calls one suit per zone (see strip below). If your card’s suit matches that call, add +{bonus} before comparing - raw shirt # alone can lose.'**
  String fantasyRule3(int bonus);

  /// No description provided for @fantasyRule4.
  ///
  /// In en, this message translates to:
  /// **'Win more zones than your opponent; if zones are split, total effective value (base + suit + bonuses) decides.'**
  String get fantasyRule4;

  /// No description provided for @fantasyRuleOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline duel: first to {count} round wins; each round is a fresh hand and pitch.'**
  String fantasyRuleOffline(int count);

  /// No description provided for @fantasyRuleOnline.
  ///
  /// In en, this message translates to:
  /// **'Online: first to {count} round wins - after each reveal both players get a new deck from the server for the next lock-in.'**
  String fantasyRuleOnline(int count);

  /// No description provided for @fantasyPitchMatchBonus.
  ///
  /// In en, this message translates to:
  /// **'+{bonus} pitch match'**
  String fantasyPitchMatchBonus(int bonus);

  /// No description provided for @noSuitMatch.
  ///
  /// In en, this message translates to:
  /// **'No suit match'**
  String get noSuitMatch;

  /// No description provided for @fantasySuitBonusWithName.
  ///
  /// In en, this message translates to:
  /// **'+{bonus} {suitName}'**
  String fantasySuitBonusWithName(int bonus, Object suitName);

  /// No description provided for @everyoneMustFinishRoundsBeforeNewRun.
  ///
  /// In en, this message translates to:
  /// **'Everyone must finish all {rounds} rounds before a new run.'**
  String everyoneMustFinishRoundsBeforeNewRun(int rounds);

  /// No description provided for @timeRanOutBeforeFinishingRoundsLose.
  ///
  /// In en, this message translates to:
  /// **'Time ran out before finishing all {rounds} rounds. You lose - score does not matter.'**
  String timeRanOutBeforeFinishingRoundsLose(int rounds);

  /// No description provided for @tooEarlyTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Too early. Try again ({left}/{max} left).'**
  String tooEarlyTryAgain(int left, int max);

  /// No description provided for @roundFailedAfterEarlyTaps.
  ///
  /// In en, this message translates to:
  /// **'Round failed after 3 early taps.'**
  String get roundFailedAfterEarlyTaps;

  /// No description provided for @roundFailedPenaltyMs.
  ///
  /// In en, this message translates to:
  /// **'Round failed (3 early taps). Penalty: {ms}ms.'**
  String roundFailedPenaltyMs(int ms);

  /// No description provided for @playerUpNextPreviousTurnFailed.
  ///
  /// In en, this message translates to:
  /// **'{player} up next. Previous turn failed (3 early taps).'**
  String playerUpNextPreviousTurnFailed(Object player);

  /// No description provided for @turnFailedAfterEarlyTaps.
  ///
  /// In en, this message translates to:
  /// **'Turn failed after 3 early taps.'**
  String get turnFailedAfterEarlyTaps;

  /// No description provided for @waitingOpponentFinishRounds.
  ///
  /// In en, this message translates to:
  /// **'Waiting for opponent to finish all {rounds} rounds...'**
  String waitingOpponentFinishRounds(int rounds);

  /// No description provided for @youWinOpponentTimedOut.
  ///
  /// In en, this message translates to:
  /// **'You win - {name} ran out of time before finishing all rounds.'**
  String youWinOpponentTimedOut(Object name);

  /// No description provided for @waitingUserFinishRounds.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to finish all {rounds} rounds...'**
  String waitingUserFinishRounds(Object name, int rounds);

  /// No description provided for @youWinTotalVs.
  ///
  /// In en, this message translates to:
  /// **'You win! Total: {myTotal} ms vs {name}: {oppTotal} ms'**
  String youWinTotalVs(int myTotal, Object name, int oppTotal);

  /// No description provided for @opponentWinsTotalVs.
  ///
  /// In en, this message translates to:
  /// **'{name} wins. Total: {oppTotal} ms vs your {myTotal} ms'**
  String opponentWinsTotalVs(Object name, int oppTotal, int myTotal);

  /// No description provided for @finalDrawTotals.
  ///
  /// In en, this message translates to:
  /// **'Final draw: both totals are {total} ms'**
  String finalDrawTotals(int total);

  /// No description provided for @reactionRelayOnlineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Classic taps -> then chase the target. Beat the clock: {seconds} s for all 5.'**
  String reactionRelayOnlineSubtitle(int seconds);

  /// No description provided for @reactionRelayOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pass & play. Rounds 1-2 static GO - 3-5 moving target. {seconds} s total.'**
  String reactionRelayOfflineSubtitle(int seconds);

  /// No description provided for @playersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String playersCount(int count);

  /// No description provided for @chaseUpper.
  ///
  /// In en, this message translates to:
  /// **'CHASE'**
  String get chaseUpper;

  /// No description provided for @classicUpper.
  ///
  /// In en, this message translates to:
  /// **'CLASSIC'**
  String get classicUpper;

  /// No description provided for @roundShortProgress.
  ///
  /// In en, this message translates to:
  /// **'R{round} / {total}'**
  String roundShortProgress(int round, int total);

  /// No description provided for @nextRound.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get nextRound;

  /// No description provided for @waitAllPlayersFinishThenReset.
  ///
  /// In en, this message translates to:
  /// **'Wait until every player finishes all {rounds} rounds. Then you can start a new run and scores reset for everyone.'**
  String waitAllPlayersFinishThenReset(int rounds);

  /// No description provided for @yourRun.
  ///
  /// In en, this message translates to:
  /// **'Your run'**
  String get yourRun;

  /// No description provided for @noSplitsYetStartMatch.
  ///
  /// In en, this message translates to:
  /// **'No splits yet - start the match.'**
  String get noSplitsYetStartMatch;

  /// No description provided for @ms.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get ms;

  /// No description provided for @roundLog.
  ///
  /// In en, this message translates to:
  /// **'Round log'**
  String get roundLog;

  /// No description provided for @winsAppearAfterEachRound.
  ///
  /// In en, this message translates to:
  /// **'Wins appear here after each round.'**
  String get winsAppearAfterEachRound;

  /// No description provided for @roundMsLabel.
  ///
  /// In en, this message translates to:
  /// **'Round {round} · ms'**
  String roundMsLabel(int round);

  /// No description provided for @thisFriend.
  ///
  /// In en, this message translates to:
  /// **'this friend'**
  String get thisFriend;

  /// No description provided for @editYourPostHint.
  ///
  /// In en, this message translates to:
  /// **'Edit your post...'**
  String get editYourPostHint;

  /// No description provided for @postToFeed.
  ///
  /// In en, this message translates to:
  /// **'Post to feed'**
  String get postToFeed;

  /// No description provided for @addSomeTextToPost.
  ///
  /// In en, this message translates to:
  /// **'Add some text to post'**
  String get addSomeTextToPost;

  /// No description provided for @postedToHomeFeed.
  ///
  /// In en, this message translates to:
  /// **'Posted to your home feed'**
  String get postedToHomeFeed;

  /// No description provided for @homePostDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get homePostDeleted;

  /// No description provided for @homePostUpdated.
  ///
  /// In en, this message translates to:
  /// **'Post updated'**
  String get homePostUpdated;

  /// No description provided for @alreadyFriendsWith.
  ///
  /// In en, this message translates to:
  /// **'You are already friends with {name}.'**
  String alreadyFriendsWith(Object name);

  /// No description provided for @friendRequestSentTo.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent to {name}'**
  String friendRequestSentTo(Object name);

  /// No description provided for @challengeSentTo.
  ///
  /// In en, this message translates to:
  /// **'{game} challenge sent to {name}'**
  String challengeSentTo(Object game, Object name);

  /// No description provided for @leftTheMatch.
  ///
  /// In en, this message translates to:
  /// **'{name} left the {game} match.'**
  String leftTheMatch(Object name, Object game);

  /// No description provided for @opponentLeftMatch.
  ///
  /// In en, this message translates to:
  /// **'Opponent left the match.'**
  String get opponentLeftMatch;

  /// No description provided for @matchNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This match is no longer available.'**
  String get matchNoLongerAvailable;

  /// No description provided for @challengeDeclined.
  ///
  /// In en, this message translates to:
  /// **'Challenge declined.'**
  String get challengeDeclined;

  /// No description provided for @challengeAccepted.
  ///
  /// In en, this message translates to:
  /// **'Challenge accepted.'**
  String get challengeAccepted;

  /// No description provided for @challengeAcceptedHasOtherMatches.
  ///
  /// In en, this message translates to:
  /// **'Match accepted. You already have other active matches - use Active matches for each game and Ready.'**
  String get challengeAcceptedHasOtherMatches;

  /// No description provided for @readyWaitingForOpponent.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready - waiting for your opponent.'**
  String get readyWaitingForOpponent;

  /// No description provided for @reactionLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get reactionLike;

  /// No description provided for @reactionLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get reactionLove;

  /// No description provided for @reactionHaha.
  ///
  /// In en, this message translates to:
  /// **'Haha'**
  String get reactionHaha;

  /// No description provided for @reactionWow.
  ///
  /// In en, this message translates to:
  /// **'Wow'**
  String get reactionWow;

  /// No description provided for @reactionSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get reactionSad;

  /// No description provided for @reactionCare.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get reactionCare;

  /// No description provided for @roundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rounds {count}'**
  String roundsLabel(int count);

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @betweenRounds.
  ///
  /// In en, this message translates to:
  /// **'Between rounds'**
  String get betweenRounds;

  /// No description provided for @resetMatch.
  ///
  /// In en, this message translates to:
  /// **'Reset match'**
  String get resetMatch;

  /// No description provided for @restartRound.
  ///
  /// In en, this message translates to:
  /// **'Restart round'**
  String get restartRound;

  /// No description provided for @startRound.
  ///
  /// In en, this message translates to:
  /// **'Start round'**
  String get startRound;

  /// No description provided for @reactionRelayStartRoundHint.
  ///
  /// In en, this message translates to:
  /// **'Start round 1. Each player gets one reaction chance per round.'**
  String get reactionRelayStartRoundHint;

  /// No description provided for @reactionRelayYouPlayThisRound.
  ///
  /// In en, this message translates to:
  /// **'You play this round on your device. Tap arm when ready.'**
  String get reactionRelayYouPlayThisRound;

  /// No description provided for @reactionRelayPassPhoneTo.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone to {player}. Tap arm when ready.'**
  String reactionRelayPassPhoneTo(Object player);

  /// No description provided for @arm.
  ///
  /// In en, this message translates to:
  /// **'Arm'**
  String get arm;

  /// No description provided for @waitForGo.
  ///
  /// In en, this message translates to:
  /// **'Wait for GO...'**
  String get waitForGo;

  /// No description provided for @goTap.
  ///
  /// In en, this message translates to:
  /// **'GO! TAP!'**
  String get goTap;

  /// No description provided for @roundWinnerMs.
  ///
  /// In en, this message translates to:
  /// **'Round {round} winner: {player} ({ms} ms)'**
  String roundWinnerMs(int round, Object player, int ms);

  /// No description provided for @yourRunFinished.
  ///
  /// In en, this message translates to:
  /// **'Your run finished.'**
  String get yourRunFinished;

  /// No description provided for @noChampionYet.
  ///
  /// In en, this message translates to:
  /// **'No champion yet.'**
  String get noChampionYet;

  /// No description provided for @championLabel.
  ///
  /// In en, this message translates to:
  /// **'Champion: {name}'**
  String championLabel(Object name);

  /// No description provided for @bestReactionMs.
  ///
  /// In en, this message translates to:
  /// **'Best reaction: {ms} ms'**
  String bestReactionMs(int ms);

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @submitScore.
  ///
  /// In en, this message translates to:
  /// **'Submit score'**
  String get submitScore;

  /// No description provided for @roomLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Room leaderboard'**
  String get roomLeaderboard;

  /// No description provided for @winnersQueue.
  ///
  /// In en, this message translates to:
  /// **'Winners queue'**
  String get winnersQueue;

  /// No description provided for @noRoundsFinishedYet.
  ///
  /// In en, this message translates to:
  /// **'No rounds finished yet.'**
  String get noRoundsFinishedYet;

  /// No description provided for @finalWinnersRanking.
  ///
  /// In en, this message translates to:
  /// **'Final winners ranking'**
  String get finalWinnersRanking;

  /// No description provided for @currentStandings.
  ///
  /// In en, this message translates to:
  /// **'Current standings'**
  String get currentStandings;

  /// No description provided for @noFinalRankingYet.
  ///
  /// In en, this message translates to:
  /// **'No final ranking yet.'**
  String get noFinalRankingYet;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'wins'**
  String get wins;

  /// No description provided for @wait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get wait;

  /// No description provided for @rpsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Rock · Paper · Scissors'**
  String get rpsHeaderTitle;

  /// No description provided for @rpsHeaderOnlineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'vs {name} · live bout'**
  String rpsHeaderOnlineSubtitle(Object name);

  /// No description provided for @rpsHeaderOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice vs {name}'**
  String rpsHeaderOfflineSubtitle(Object name);

  /// No description provided for @throwLabel.
  ///
  /// In en, this message translates to:
  /// **'Throw'**
  String get throwLabel;

  /// No description provided for @challenger.
  ///
  /// In en, this message translates to:
  /// **'Challenger'**
  String get challenger;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @rpsPaperCoversRockChallengerWins.
  ///
  /// In en, this message translates to:
  /// **'Paper covers rock · challenger wins the throw'**
  String get rpsPaperCoversRockChallengerWins;

  /// No description provided for @rpsPaperCoversRockHostWins.
  ///
  /// In en, this message translates to:
  /// **'Paper covers rock · host wins the throw'**
  String get rpsPaperCoversRockHostWins;

  /// No description provided for @rpsChallengerWinsThrow.
  ///
  /// In en, this message translates to:
  /// **'Challenger wins the throw'**
  String get rpsChallengerWinsThrow;

  /// No description provided for @rpsHostWinsThrow.
  ///
  /// In en, this message translates to:
  /// **'Host wins the throw'**
  String get rpsHostWinsThrow;

  /// No description provided for @couldNotCloseOutMatch.
  ///
  /// In en, this message translates to:
  /// **'Could not close out match: {message}'**
  String couldNotCloseOutMatch(Object message);

  /// No description provided for @couldNotSubmitPick.
  ///
  /// In en, this message translates to:
  /// **'Could not submit pick: {message}'**
  String couldNotSubmitPick(Object message);

  /// No description provided for @whoGoal.
  ///
  /// In en, this message translates to:
  /// **'{name} - GOAL!'**
  String whoGoal(Object name);

  /// No description provided for @whoSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} - saved!'**
  String whoSaved(Object name);

  /// No description provided for @penaltyDirFarLeft.
  ///
  /// In en, this message translates to:
  /// **'Far left'**
  String get penaltyDirFarLeft;

  /// No description provided for @penaltyDirLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get penaltyDirLeft;

  /// No description provided for @penaltyDirCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get penaltyDirCenter;

  /// No description provided for @penaltyDirRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get penaltyDirRight;

  /// No description provided for @penaltyDirFarRight.
  ///
  /// In en, this message translates to:
  /// **'Far right'**
  String get penaltyDirFarRight;

  /// No description provided for @penaltyDragReleaseShoot.
  ///
  /// In en, this message translates to:
  /// **'Drag sideways, release to shoot'**
  String get penaltyDragReleaseShoot;

  /// No description provided for @penaltyDragReleaseDive.
  ///
  /// In en, this message translates to:
  /// **'Drag sideways, release to dive'**
  String get penaltyDragReleaseDive;

  /// No description provided for @penaltyLaneLeft.
  ///
  /// In en, this message translates to:
  /// **'LEFT'**
  String get penaltyLaneLeft;

  /// No description provided for @penaltyLaneCenter.
  ///
  /// In en, this message translates to:
  /// **'CENTER'**
  String get penaltyLaneCenter;

  /// No description provided for @penaltyLaneRight.
  ///
  /// In en, this message translates to:
  /// **'RIGHT'**
  String get penaltyLaneRight;

  /// No description provided for @penaltyLaneFarLeftShort.
  ///
  /// In en, this message translates to:
  /// **'FL'**
  String get penaltyLaneFarLeftShort;

  /// No description provided for @penaltyLaneLeftShort.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get penaltyLaneLeftShort;

  /// No description provided for @penaltyLaneCenterShort.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get penaltyLaneCenterShort;

  /// No description provided for @penaltyLaneRightShort.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get penaltyLaneRightShort;

  /// No description provided for @penaltyLaneFarRightShort.
  ///
  /// In en, this message translates to:
  /// **'FR'**
  String get penaltyLaneFarRightShort;

  /// No description provided for @penaltyRoundProgress.
  ///
  /// In en, this message translates to:
  /// **'Round {round} / {total}'**
  String penaltyRoundProgress(int round, int total);

  /// No description provided for @penaltyRoundPicksInProgress.
  ///
  /// In en, this message translates to:
  /// **'Round picks in progress...'**
  String get penaltyRoundPicksInProgress;

  /// No description provided for @opponentWins.
  ///
  /// In en, this message translates to:
  /// **'{name} wins'**
  String opponentWins(Object name);

  /// No description provided for @shootoutWinSubline.
  ///
  /// In en, this message translates to:
  /// **'Clinical finishing - share the highlight!'**
  String get shootoutWinSubline;

  /// No description provided for @shootoutLossSubline.
  ///
  /// In en, this message translates to:
  /// **'Heartbreaker - one more shootout?'**
  String get shootoutLossSubline;

  /// No description provided for @shootoutDrawSubline.
  ///
  /// In en, this message translates to:
  /// **'Deadlock on the line - honor is even.'**
  String get shootoutDrawSubline;

  /// No description provided for @shootoutOver.
  ///
  /// In en, this message translates to:
  /// **'Shootout over'**
  String get shootoutOver;

  /// No description provided for @youVsOpponentScore.
  ///
  /// In en, this message translates to:
  /// **'You {myGoals}  —  {opponent} {oppGoals}'**
  String youVsOpponentScore(int myGoals, Object opponent, int oppGoals);

  /// No description provided for @shareToHomeFeed.
  ///
  /// In en, this message translates to:
  /// **'Share to home feed'**
  String get shareToHomeFeed;

  /// No description provided for @penaltyShootoutShareBody.
  ///
  /// In en, this message translates to:
  /// **'Penalty shootout vs {opponent}\nFinal: {myGoals} — {oppGoals}\n{winnerLine}'**
  String penaltyShootoutShareBody(
    Object opponent,
    int myGoals,
    int oppGoals,
    Object winnerLine,
  );

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share result'**
  String get shareResult;

  /// No description provided for @goalLanes.
  ///
  /// In en, this message translates to:
  /// **'Goal lanes'**
  String get goalLanes;

  /// No description provided for @goalLanesClassicTooltip.
  ///
  /// In en, this message translates to:
  /// **'Left · center · right'**
  String get goalLanesClassicTooltip;

  /// No description provided for @goalLanesWideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Far left through far right'**
  String get goalLanesWideTooltip;

  /// No description provided for @savingPickToServer.
  ///
  /// In en, this message translates to:
  /// **'Saving your pick to the server...'**
  String get savingPickToServer;

  /// No description provided for @pickSavedWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Pick saved - waiting for {name}...'**
  String pickSavedWaitingFor(Object name);

  /// No description provided for @shotDiveSummary.
  ///
  /// In en, this message translates to:
  /// **'Shot {shot} · Dive {dive}'**
  String shotDiveSummary(Object shot, Object dive);

  /// No description provided for @onlineGamePenaltyShootout.
  ///
  /// In en, this message translates to:
  /// **'Penalty shootout'**
  String get onlineGamePenaltyShootout;

  /// No description provided for @onlineGameRockPaperScissors.
  ///
  /// In en, this message translates to:
  /// **'Rock paper scissors'**
  String get onlineGameRockPaperScissors;

  /// No description provided for @onlineGameFantasyCards.
  ///
  /// In en, this message translates to:
  /// **'Fantasy cards'**
  String get onlineGameFantasyCards;

  /// No description provided for @onlineGameReactionRelay.
  ///
  /// In en, this message translates to:
  /// **'Reaction relay'**
  String get onlineGameReactionRelay;

  /// No description provided for @onlineGameFlashMatch.
  ///
  /// In en, this message translates to:
  /// **'Flash match'**
  String get onlineGameFlashMatch;

  /// No description provided for @onlineGameFallback.
  ///
  /// In en, this message translates to:
  /// **'Game #{gameId}'**
  String onlineGameFallback(Object gameId);

  /// No description provided for @onlinePartyGameTwoToFive.
  ///
  /// In en, this message translates to:
  /// **'Party game - 2-5 players on one device'**
  String get onlinePartyGameTwoToFive;

  /// No description provided for @onlinePartyGameRoundsGetHarder.
  ///
  /// In en, this message translates to:
  /// **'Party game - rounds get harder (flash, grid, penalties)'**
  String get onlinePartyGameRoundsGetHarder;

  /// No description provided for @aiLabel.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiLabel;

  /// No description provided for @matchVsOpponent.
  ///
  /// In en, this message translates to:
  /// **'Match vs {name}'**
  String matchVsOpponent(Object name);

  /// No description provided for @noScreenForGameIdYet.
  ///
  /// In en, this message translates to:
  /// **'No screen for game ID {gameId} yet.'**
  String noScreenForGameIdYet(Object gameId);

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @couldNotFindPostInFeed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find that post on the feed.'**
  String get couldNotFindPostInFeed;

  /// No description provided for @feedTipPullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull down on the list to refresh posts.'**
  String get feedTipPullToRefresh;

  /// No description provided for @feedTipTapName.
  ///
  /// In en, this message translates to:
  /// **'Tap someone\'s name to add them or send a game challenge.'**
  String get feedTipTapName;

  /// No description provided for @feedTipExplorePeople.
  ///
  /// In en, this message translates to:
  /// **'Use Explore people under Jump in to search players by username.'**
  String get feedTipExplorePeople;

  /// No description provided for @feedTipTopLiked.
  ///
  /// In en, this message translates to:
  /// **'Switch to Top liked to see what\'s trending.'**
  String get feedTipTopLiked;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @tapForFeedTip.
  ///
  /// In en, this message translates to:
  /// **'Tap for a feed tip - your community hub'**
  String get tapForFeedTip;

  /// No description provided for @backToTop.
  ///
  /// In en, this message translates to:
  /// **'Back to top'**
  String get backToTop;

  /// No description provided for @jumpIn.
  ///
  /// In en, this message translates to:
  /// **'Jump in'**
  String get jumpIn;

  /// No description provided for @quickNewPostTooltip.
  ///
  /// In en, this message translates to:
  /// **'New post - share an update'**
  String get quickNewPostTooltip;

  /// No description provided for @quickOnlineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play online - challenges & duels'**
  String get quickOnlineTooltip;

  /// No description provided for @quickAlertsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Alerts - replies & invites'**
  String get quickAlertsTooltip;

  /// No description provided for @quickBattlesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Battles - team events'**
  String get quickBattlesTooltip;

  /// No description provided for @quickProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile - you & friends'**
  String get quickProfileTooltip;

  /// No description provided for @quickPeopleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Explore people - search & friend requests'**
  String get quickPeopleTooltip;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @battles.
  ///
  /// In en, this message translates to:
  /// **'Battles'**
  String get battles;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @topLiked.
  ///
  /// In en, this message translates to:
  /// **'Top liked'**
  String get topLiked;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @announce.
  ///
  /// In en, this message translates to:
  /// **'Announce'**
  String get announce;

  /// No description provided for @celebrate.
  ///
  /// In en, this message translates to:
  /// **'Celebrate'**
  String get celebrate;

  /// No description provided for @teamBattleCosmicDiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Cosmic dice'**
  String get teamBattleCosmicDiceTitle;

  /// No description provided for @teamBattleCosmicDiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One roll (1-999) per UTC day - highest wins.'**
  String get teamBattleCosmicDiceSubtitle;

  /// No description provided for @teamBattleReflexTitle.
  ///
  /// In en, this message translates to:
  /// **'Green-light reflex'**
  String get teamBattleReflexTitle;

  /// No description provided for @teamBattleReflexSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wait for green, then tap - fastest reaction ranks higher.'**
  String get teamBattleReflexSubtitle;

  /// No description provided for @teamBattleOracleTitle.
  ///
  /// In en, this message translates to:
  /// **'Oracle digit'**
  String get teamBattleOracleTitle;

  /// No description provided for @teamBattleOracleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a digit 0-9. A daily hash picks the winning number.'**
  String get teamBattleOracleSubtitle;

  /// No description provided for @teamBattleBlitzTitle.
  ///
  /// In en, this message translates to:
  /// **'Five-second blitz'**
  String get teamBattleBlitzTitle;

  /// No description provided for @teamBattleBlitzSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How many taps in 5 seconds? Best score today stays on the board.'**
  String get teamBattleBlitzSubtitle;

  /// No description provided for @teamBattleHighLowTitle.
  ///
  /// In en, this message translates to:
  /// **'High-low prophet'**
  String get teamBattleHighLowTitle;

  /// No description provided for @teamBattleHighLowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The app rolls 0-99 once per day (UTC). Pick low (0-49) or high (50-99).'**
  String get teamBattleHighLowSubtitle;

  /// No description provided for @teamPicked.
  ///
  /// In en, this message translates to:
  /// **'picked {value}'**
  String teamPicked(Object value);

  /// No description provided for @teamEntered.
  ///
  /// In en, this message translates to:
  /// **'Entered'**
  String get teamEntered;

  /// No description provided for @teamYourRoll.
  ///
  /// In en, this message translates to:
  /// **'Your roll: {value}'**
  String teamYourRoll(Object value);

  /// No description provided for @teamYourBestMs.
  ///
  /// In en, this message translates to:
  /// **'Your best: {value} ms'**
  String teamYourBestMs(Object value);

  /// No description provided for @teamSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get teamSubmitted;

  /// No description provided for @teamSubmittedToday.
  ///
  /// In en, this message translates to:
  /// **'Submitted for today.'**
  String get teamSubmittedToday;

  /// No description provided for @teamYouPickedFair.
  ///
  /// In en, this message translates to:
  /// **'You picked {value}. The winning digit is not shown here (fair play).'**
  String teamYouPickedFair(Object value);

  /// No description provided for @teamYourBestTaps.
  ///
  /// In en, this message translates to:
  /// **'Your best: {value} taps'**
  String teamYourBestTaps(Object value);

  /// No description provided for @teamYouChoseFair.
  ///
  /// In en, this message translates to:
  /// **'You chose {value}. The hidden number is not shown here (fair play).'**
  String teamYouChoseFair(Object value);

  /// No description provided for @teamRolledSubmit.
  ///
  /// In en, this message translates to:
  /// **'You rolled {value}. Submit for today?'**
  String teamRolledSubmit(Object value);

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @teamLockedIn.
  ///
  /// In en, this message translates to:
  /// **'Locked in: {roll} for {period} (UTC).'**
  String teamLockedIn(Object roll, Object period);

  /// No description provided for @teamSavedMs.
  ///
  /// In en, this message translates to:
  /// **'Saved: {value} ms'**
  String teamSavedMs(Object value);

  /// No description provided for @teamScoreMs.
  ///
  /// In en, this message translates to:
  /// **'{value} ms'**
  String teamScoreMs(Object value);

  /// No description provided for @teamLockPick.
  ///
  /// In en, this message translates to:
  /// **'Lock pick'**
  String get teamLockPick;

  /// No description provided for @teamOracleSavedFair.
  ///
  /// In en, this message translates to:
  /// **'Pick saved. The oracle digit stays hidden here so everyone plays fair.'**
  String get teamOracleSavedFair;

  /// No description provided for @teamTapsSaved.
  ///
  /// In en, this message translates to:
  /// **'{value} taps saved.'**
  String teamTapsSaved(Object value);

  /// No description provided for @teamScoreTaps.
  ///
  /// In en, this message translates to:
  /// **'{value} taps'**
  String teamScoreTaps(Object value);

  /// No description provided for @teamHighLowQuestion.
  ///
  /// In en, this message translates to:
  /// **'Will today\'s hidden number be low (0-49) or high (50-99)?'**
  String get teamHighLowQuestion;

  /// No description provided for @teamLowRange.
  ///
  /// In en, this message translates to:
  /// **'Low (0-49)'**
  String get teamLowRange;

  /// No description provided for @teamHighRange.
  ///
  /// In en, this message translates to:
  /// **'High (50-99)'**
  String get teamHighRange;

  /// No description provided for @teamHighLowSavedFair.
  ///
  /// In en, this message translates to:
  /// **'Choice saved. The daily number stays hidden here so everyone plays fair.'**
  String get teamHighLowSavedFair;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @teamBeatRecord.
  ///
  /// In en, this message translates to:
  /// **'Beat record'**
  String get teamBeatRecord;

  /// No description provided for @teamDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get teamDoneToday;

  /// No description provided for @teamBattles.
  ///
  /// In en, this message translates to:
  /// **'Team battles'**
  String get teamBattles;

  /// No description provided for @teamSignInHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join today\'s global battles.'**
  String get teamSignInHint;

  /// No description provided for @globalBattles.
  ///
  /// In en, this message translates to:
  /// **'Global battles'**
  String get globalBattles;

  /// No description provided for @teamUtcDayBoards.
  ///
  /// In en, this message translates to:
  /// **'UTC day {period} - everyone in the app shares these boards.'**
  String teamUtcDayBoards(Object period);

  /// No description provided for @teamYesterdaysChampions.
  ///
  /// In en, this message translates to:
  /// **'Yesterday\'s champions'**
  String get teamYesterdaysChampions;

  /// No description provided for @teamChampionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'UTC day {period} - top score per battle. A notification goes out every day at 12:00 PM on this device.'**
  String teamChampionsSubtitle(Object period);

  /// No description provided for @teamNoChampion.
  ///
  /// In en, this message translates to:
  /// **'-'**
  String get teamNoChampion;

  /// No description provided for @teamTopPlayers.
  ///
  /// In en, this message translates to:
  /// **'Top players'**
  String get teamTopPlayers;

  /// No description provided for @teamNoScoresYet.
  ///
  /// In en, this message translates to:
  /// **'No scores yet - be the first.'**
  String get teamNoScoresYet;

  /// No description provided for @teamWaitForGreenHint.
  ///
  /// In en, this message translates to:
  /// **'Wait for GREEN. Early tap resets the round.'**
  String get teamWaitForGreenHint;

  /// No description provided for @teamGreenTapNow.
  ///
  /// In en, this message translates to:
  /// **'GREEN! Tap now.'**
  String get teamGreenTapNow;

  /// No description provided for @teamTooEarlyWaitGreen.
  ///
  /// In en, this message translates to:
  /// **'Too early! Wait for GREEN.'**
  String get teamTooEarlyWaitGreen;

  /// No description provided for @teamTapNow.
  ///
  /// In en, this message translates to:
  /// **'TAP!'**
  String get teamTapNow;

  /// No description provided for @teamWaitEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Wait...'**
  String get teamWaitEllipsis;

  /// No description provided for @abort.
  ///
  /// In en, this message translates to:
  /// **'Abort'**
  String get abort;

  /// No description provided for @teamSecondsLeftTapAnywhere.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s left - tap anywhere'**
  String teamSecondsLeftTapAnywhere(Object seconds);

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @teamEmptyIntro.
  ///
  /// In en, this message translates to:
  /// **'Build a six-player squad on the standard 2-2-2 pitch and train stats. Once you have a team, challenge friends from this tab or Online.'**
  String get teamEmptyIntro;

  /// No description provided for @teamNoSquadYet.
  ///
  /// In en, this message translates to:
  /// **'No squad yet'**
  String get teamNoSquadYet;

  /// No description provided for @teamNoSquadDescription.
  ///
  /// In en, this message translates to:
  /// **'Six players only on the same layout as everyone else - tap anyone later for name & photo, then train stats with skill points.'**
  String get teamNoSquadDescription;

  /// No description provided for @teamCreateTeam.
  ///
  /// In en, this message translates to:
  /// **'Create team'**
  String get teamCreateTeam;

  /// No description provided for @teamBestLineupInApp.
  ///
  /// In en, this message translates to:
  /// **'Best lineup in the app'**
  String get teamBestLineupInApp;

  /// No description provided for @teamBestLineupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Top Power score this UTC week ({monday}). Same rules as Lineup races - train, submit, climb.'**
  String teamBestLineupSubtitle(Object monday);

  /// No description provided for @teamNoSubmissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No submissions yet - be first on the board.'**
  String get teamNoSubmissionsYet;

  /// No description provided for @teamRankPowerRace.
  ///
  /// In en, this message translates to:
  /// **'{name} - rank #1 - Power race'**
  String teamRankPowerRace(Object name);

  /// No description provided for @teamPlayTogether.
  ///
  /// In en, this message translates to:
  /// **'Play together'**
  String get teamPlayTogether;

  /// No description provided for @teamSameFriendsListHint.
  ///
  /// In en, this message translates to:
  /// **'Same friends list as Home - challenge someone and they will see it on Online.'**
  String get teamSameFriendsListHint;

  /// No description provided for @teamRefreshFriends.
  ///
  /// In en, this message translates to:
  /// **'Refresh friends'**
  String get teamRefreshFriends;

  /// No description provided for @teamNoFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'No friends yet - send requests from Home. When someone accepts, tap refresh here or open Online.'**
  String get teamNoFriendsHint;

  /// No description provided for @challenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challenge;

  /// No description provided for @teamSquadPulse.
  ///
  /// In en, this message translates to:
  /// **'Squad pulse'**
  String get teamSquadPulse;

  /// No description provided for @teamSquadPulseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live preview of the three weekly race modes - train, then climb the shared leaderboard.'**
  String get teamSquadPulseSubtitle;

  /// No description provided for @teamPowerRace.
  ///
  /// In en, this message translates to:
  /// **'Power race'**
  String get teamPowerRace;

  /// No description provided for @teamSpeedDash.
  ///
  /// In en, this message translates to:
  /// **'Speed dash'**
  String get teamSpeedDash;

  /// No description provided for @teamBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get teamBalance;

  /// No description provided for @teamRaceSubtitlePower.
  ///
  /// In en, this message translates to:
  /// **'Sum of ATK+DEF+SPD+STM for all six.'**
  String get teamRaceSubtitlePower;

  /// No description provided for @teamRaceSubtitleSpeed.
  ///
  /// In en, this message translates to:
  /// **'Each player: 2×SPD + STM.'**
  String get teamRaceSubtitleSpeed;

  /// No description provided for @teamRaceSubtitleBalance.
  ///
  /// In en, this message translates to:
  /// **'Rewards high minimum stat per player (×15).'**
  String get teamRaceSubtitleBalance;

  /// No description provided for @lineupScored.
  ///
  /// In en, this message translates to:
  /// **'Lineup scored: {score} pts'**
  String lineupScored(Object score);

  /// No description provided for @lineupRaces.
  ///
  /// In en, this message translates to:
  /// **'Lineup races'**
  String get lineupRaces;

  /// No description provided for @refreshBoard.
  ///
  /// In en, this message translates to:
  /// **'Refresh board'**
  String get refreshBoard;

  /// No description provided for @teamRaceWeekUtc.
  ///
  /// In en, this message translates to:
  /// **'Week (UTC): {mondayId} · everyone uses the same saved six from the cloud.'**
  String teamRaceWeekUtc(Object mondayId);

  /// No description provided for @submitLineupToRace.
  ///
  /// In en, this message translates to:
  /// **'Submit lineup to this race'**
  String get submitLineupToRace;

  /// No description provided for @createTeamToEnter.
  ///
  /// In en, this message translates to:
  /// **'Create a team to enter'**
  String get createTeamToEnter;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @teamNoEntriesYetBeFirstThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No entries yet - be first this week.'**
  String get teamNoEntriesYetBeFirstThisWeek;

  /// No description provided for @yourSquad.
  ///
  /// In en, this message translates to:
  /// **'YOUR SQUAD'**
  String get yourSquad;

  /// No description provided for @teamSkillPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String teamSkillPointsLabel(Object points);

  /// No description provided for @teamRenameTeam.
  ///
  /// In en, this message translates to:
  /// **'Rename team'**
  String get teamRenameTeam;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamName;

  /// No description provided for @teamStatPlusOne.
  ///
  /// In en, this message translates to:
  /// **'{label} +1'**
  String teamStatPlusOne(Object label);

  /// No description provided for @teamSkillTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Skill training ({cost} pts → +1)'**
  String teamSkillTrainingTitle(Object cost);

  /// No description provided for @teamPlayerTrainingBalance.
  ///
  /// In en, this message translates to:
  /// **'Player {slot}: {name} · your balance: {points} pts'**
  String teamPlayerTrainingBalance(Object slot, Object name, Object points);

  /// No description provided for @teamEarnMoreFromDailyChallenges.
  ///
  /// In en, this message translates to:
  /// **'Earn more from daily challenges above.'**
  String get teamEarnMoreFromDailyChallenges;

  /// No description provided for @teamPlayerIndexOf.
  ///
  /// In en, this message translates to:
  /// **'Player {index} of {total}'**
  String teamPlayerIndexOf(Object index, Object total);

  /// No description provided for @teamEditPlayer.
  ///
  /// In en, this message translates to:
  /// **'Edit player'**
  String get teamEditPlayer;

  /// No description provided for @teamPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get teamPhoto;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @teamDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get teamDisplayName;

  /// No description provided for @teamStatsSkillTrainingOnly.
  ///
  /// In en, this message translates to:
  /// **'Stats (skill training only)'**
  String get teamStatsSkillTrainingOnly;

  /// No description provided for @teamRaiseStatsHint.
  ///
  /// In en, this message translates to:
  /// **'Raise ATK, DEF, SPD, and STM from the training section above.'**
  String get teamRaiseStatsHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @tapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit'**
  String get tapToEdit;

  /// No description provided for @teamDefenseShort.
  ///
  /// In en, this message translates to:
  /// **'DEF'**
  String get teamDefenseShort;

  /// No description provided for @teamAttackShort.
  ///
  /// In en, this message translates to:
  /// **'ATK'**
  String get teamAttackShort;

  /// No description provided for @teamChallengePitchReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily pitch report'**
  String get teamChallengePitchReportTitle;

  /// No description provided for @teamChallengePitchReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same for every player - claim once per UTC day.'**
  String get teamChallengePitchReportSubtitle;

  /// No description provided for @teamChallengeCrowdEnergyTitle.
  ///
  /// In en, this message translates to:
  /// **'Crowd energy'**
  String get teamChallengeCrowdEnergyTitle;

  /// No description provided for @teamChallengeCrowdEnergySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Publish any post on Home today (UTC).'**
  String get teamChallengeCrowdEnergySubtitle;

  /// No description provided for @teamChallengeMatchRhythmTitle.
  ///
  /// In en, this message translates to:
  /// **'Match-day rhythm'**
  String get teamChallengeMatchRhythmTitle;

  /// No description provided for @teamChallengeMatchRhythmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play online today (UTC). Penalty: we log you when the match closes in the cloud; rim / fantasy / 1v1 count from live session rows.'**
  String get teamChallengeMatchRhythmSubtitle;

  /// No description provided for @teamDailyChallengesEveryone.
  ///
  /// In en, this message translates to:
  /// **'Daily challenges (everyone)'**
  String get teamDailyChallengesEveryone;

  /// No description provided for @teamDailyChallengesHint.
  ///
  /// In en, this message translates to:
  /// **'Earn skill points, then train players (+1 stat for 15 pts). Squad must be saved to the cloud.'**
  String get teamDailyChallengesHint;

  /// No description provided for @claimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get claimed;

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get claim;

  /// No description provided for @teamBattleStatDelta.
  ///
  /// In en, this message translates to:
  /// **'Player {slot}: {stat} {arrow} {before} -> {after}'**
  String teamBattleStatDelta(
    Object slot,
    Object stat,
    Object arrow,
    Object before,
    Object after,
  );

  /// No description provided for @teamBattleAcademyDialogBody.
  ///
  /// In en, this message translates to:
  /// **'A quick solo match vs a rotating reserve side. Same Power total as lineup races.\n\n- Win: +18 skill pts - Tie: +12 - Loss: still +8\n- No stat changes - just a fun daily warm-up\n- Once per UTC day\n\nKick off?'**
  String get teamBattleAcademyDialogBody;

  /// No description provided for @teamBattleNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get teamBattleNotNow;

  /// No description provided for @teamBattleKickOff.
  ///
  /// In en, this message translates to:
  /// **'Kick off'**
  String get teamBattleKickOff;

  /// No description provided for @teamBattleAcademyFriendly.
  ///
  /// In en, this message translates to:
  /// **'Academy friendly'**
  String get teamBattleAcademyFriendly;

  /// No description provided for @teamBattleThisFriend.
  ///
  /// In en, this message translates to:
  /// **'this friend'**
  String get teamBattleThisFriend;

  /// No description provided for @teamBattleSquadSpar.
  ///
  /// In en, this message translates to:
  /// **'Squad spar'**
  String get teamBattleSquadSpar;

  /// No description provided for @teamBattleSquadSparDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Both squads are scored with the same Power formula as lineup races (sum of every player\'s ATK+DEF+SPD+STM).\n\n- Win: +20 skill pts and +1 random stat (max 99)\n- Tie: +8 skill pts each - stats unchanged\n- Loss: -1 random stat (min 40)\n\nOne spar per friend pair per UTC day. Higher risk, bigger rush.\n\nChallenge {name}?'**
  String teamBattleSquadSparDialogBody(Object name);

  /// No description provided for @battle.
  ///
  /// In en, this message translates to:
  /// **'Battle'**
  String get battle;

  /// No description provided for @teamBattleVictory.
  ///
  /// In en, this message translates to:
  /// **'Victory {myScore}-{oppScore}! +{points} skill pts'**
  String teamBattleVictory(Object myScore, Object oppScore, Object points);

  /// No description provided for @teamBattleDefeat.
  ///
  /// In en, this message translates to:
  /// **'Defeat {myScore}-{oppScore}. Come back stronger tomorrow.'**
  String teamBattleDefeat(Object myScore, Object oppScore);

  /// No description provided for @teamBattleDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw {myScore}-{oppScore} - +{points} skill pts each'**
  String teamBattleDraw(Object myScore, Object oppScore, Object points);

  /// No description provided for @teamBattleSparSettled.
  ///
  /// In en, this message translates to:
  /// **'Spar settled - balance {balance}'**
  String teamBattleSparSettled(Object balance);

  /// No description provided for @teamBattleBattlesForSkillPoints.
  ///
  /// In en, this message translates to:
  /// **'Battles for skill points'**
  String get teamBattleBattlesForSkillPoints;

  /// No description provided for @teamBattleHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Academy friendly for a relaxed daily match, friend spars for high stakes, and Online duels for the full rush.'**
  String get teamBattleHeaderSubtitle;

  /// No description provided for @teamBattleChipWin.
  ///
  /// In en, this message translates to:
  /// **'Win: pts + buff'**
  String get teamBattleChipWin;

  /// No description provided for @teamBattleChipTie.
  ///
  /// In en, this message translates to:
  /// **'Tie: safe pts'**
  String get teamBattleChipTie;

  /// No description provided for @teamBattleChipLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss: stat hit'**
  String get teamBattleChipLoss;

  /// No description provided for @teamBattleAcademySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Solo scrim vs a named reserve side. Scores tick up live - no roster risk, and you always earn skill points.'**
  String get teamBattleAcademySubtitle;

  /// No description provided for @teamBattleChipNoStatRisk.
  ///
  /// In en, this message translates to:
  /// **'No stat risk'**
  String get teamBattleChipNoStatRisk;

  /// No description provided for @teamBattleChipDailyOnce.
  ///
  /// In en, this message translates to:
  /// **'Daily once'**
  String get teamBattleChipDailyOnce;

  /// No description provided for @teamBattleChipAlwaysPts.
  ///
  /// In en, this message translates to:
  /// **'Always +pts'**
  String get teamBattleChipAlwaysPts;

  /// No description provided for @teamBattleKickOffAcademy.
  ///
  /// In en, this message translates to:
  /// **'Kick off vs Academy XI'**
  String get teamBattleKickOffAcademy;

  /// No description provided for @teamBattleTapAnimatedScoreboard.
  ///
  /// In en, this message translates to:
  /// **'Tap for the animated scoreboard'**
  String get teamBattleTapAnimatedScoreboard;

  /// No description provided for @teamBattleSquadSparFriends.
  ///
  /// In en, this message translates to:
  /// **'Squad spar (friends)'**
  String get teamBattleSquadSparFriends;

  /// No description provided for @teamBattleAddFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Add friends from Home, then refresh. You need a saved squad and an accepted friend with a squad.'**
  String get teamBattleAddFriendsHint;

  /// No description provided for @teamBattleLiveDuels.
  ///
  /// In en, this message translates to:
  /// **'Live duels (Online tab)'**
  String get teamBattleLiveDuels;

  /// No description provided for @teamBattleLiveDuelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Penalty, rock-paper-scissors, fantasy cards - head-to-head matches. Random roster stat swings apply in friend spar above; live games fuel your daily \"Match-day rhythm\" claim.'**
  String get teamBattleLiveDuelsSubtitle;

  /// No description provided for @teamBattleOutcomeWin.
  ///
  /// In en, this message translates to:
  /// **'Win - your Power edged them out!'**
  String get teamBattleOutcomeWin;

  /// No description provided for @teamBattleOutcomeLose.
  ///
  /// In en, this message translates to:
  /// **'Narrow loss - reserve side had the edge today.'**
  String get teamBattleOutcomeLose;

  /// No description provided for @teamBattleOutcomeTie.
  ///
  /// In en, this message translates to:
  /// **'Dead heat - split the difference.'**
  String get teamBattleOutcomeTie;

  /// No description provided for @teamBattleOutcomeComplete.
  ///
  /// In en, this message translates to:
  /// **'Match complete'**
  String get teamBattleOutcomeComplete;

  /// No description provided for @teamBattleYouVs.
  ///
  /// In en, this message translates to:
  /// **'You vs {opponent}'**
  String teamBattleYouVs(Object opponent);

  /// No description provided for @teamBattleYourSquad.
  ///
  /// In en, this message translates to:
  /// **'Your squad'**
  String get teamBattleYourSquad;

  /// No description provided for @teamBattleTheirPower.
  ///
  /// In en, this message translates to:
  /// **'Their Power'**
  String get teamBattleTheirPower;

  /// No description provided for @teamBattlePointsBalance.
  ///
  /// In en, this message translates to:
  /// **'+{points} skill pts - balance {balance}'**
  String teamBattlePointsBalance(Object points, Object balance);

  /// No description provided for @nice.
  ///
  /// In en, this message translates to:
  /// **'Nice'**
  String get nice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
