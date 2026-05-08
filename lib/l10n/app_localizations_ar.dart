// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مشروع جديد';

  @override
  String get loggedInSuccessfully => 'تم تسجيل الدخول بنجاح';

  @override
  String get loginHeroTitle => 'مرحبًا بعودتك.';

  @override
  String get loginHeroSubtitle =>
      'تابع خلاصتك وتواصل مع الأشخاص واحتفظ بنشاطك متزامنًا.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get validEmailRequired => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordAtLeast6 => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get continueText => 'متابعة';

  @override
  String get newHere => 'جديد هنا؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get accountCreatedSuccessfully => 'تم إنشاء الحساب بنجاح';

  @override
  String get signupFriendlyUsernameTaken =>
      'اسم المستخدم مستخدم بالفعل. يرجى اختيار اسم آخر.';

  @override
  String get signupHeroTitle => 'أنشئ حسابك';

  @override
  String get signupHeroSubtitle => 'انضم الآن وابدأ ببناء ملفك الشخصي ونشاطك.';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernameHint => 'yourname';

  @override
  String get usernameRequired => 'اسم المستخدم مطلوب';

  @override
  String get usernameAtLeast3 => 'يجب أن يكون اسم المستخدم 3 أحرف على الأقل';

  @override
  String get alreadyMember => 'لديك حساب بالفعل؟';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get forgotOtpInstructionSnack =>
      'أدخل الرمز المرسل إلى بريدك الإلكتروني، ثم اختر كلمة مرور جديدة.';

  @override
  String get passwordUpdatedSnack =>
      'تم تحديث كلمة المرور. سجّل الدخول بكلمة المرور الجديدة.';

  @override
  String get forgotHeroTitleStep1 => 'استعادة حسابك';

  @override
  String get forgotHeroTitleStep2 => 'تحقق وأعد تعيين كلمة المرور';

  @override
  String get forgotHeroSubtitleStep1 =>
      'سنرسل رمز استعادة لمرة واحدة إلى بريدك الإلكتروني.';

  @override
  String get forgotHeroSubtitleStep2 =>
      'أدخل الرمز من بريدك الإلكتروني وحدد كلمة مرور جديدة.';

  @override
  String get forgotStep1Title => 'الخطوة 1: طلب الرمز';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get rememberedIt => 'تذكّرتها؟';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get forgotStep2Title => 'الخطوة 2: التحقق والتحديث';

  @override
  String codeSentTo(Object email) {
    return 'تم إرسال الرمز إلى $email';
  }

  @override
  String get verificationCode => 'رمز التحقق';

  @override
  String get verificationCodeHint => 'رمز من 6 إلى 8 أرقام';

  @override
  String get codeRequired => 'الرمز مطلوب';

  @override
  String get codeTooShort => 'الرمز قصير جدًا';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get atLeast6Chars => '6 أحرف على الأقل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get verifyAndUpdatePassword => 'تحقق من الرمز وحدّث كلمة المرور';

  @override
  String get wrongEmail => 'البريد الإلكتروني خاطئ؟';

  @override
  String get useDifferentEmail => 'استخدم بريدًا آخر';

  @override
  String get newPost => 'منشور جديد';

  @override
  String get postTypeDescriptionPost => 'منشور: تحديثات المجتمع العامة.';

  @override
  String get postTypeDescriptionAnnouncement => 'إعلان: للتحديثات المهمة.';

  @override
  String get postTypeDescriptionCelebration =>
      'احتفال: شارك النجاحات واللحظات السعيدة.';

  @override
  String get postTypeDescriptionAds =>
      'إعلانات: روّج للمنتجات أو الفعاليات أو العروض.';

  @override
  String get postTypePost => 'منشور';

  @override
  String get postTypeAnnouncement => 'إعلان';

  @override
  String get postTypeCelebration => 'احتفال';

  @override
  String get postTypeAds => 'إعلانات';

  @override
  String get adLink => 'رابط الإعلان';

  @override
  String get adLinkHint => 'https://example.com';

  @override
  String get friendsVisibilityHint =>
      'للأصدقاء فقط: يمكن لك ولأصدقائك المقبولين فقط رؤية هذا المنشور.';

  @override
  String get generalVisibilityHint =>
      'منشور عام: مرئي لجميع المستخدمين داخل التطبيق.';

  @override
  String get general => 'عام';

  @override
  String get friendsOnly => 'للأصدقاء فقط';

  @override
  String get postContentHint => 'بماذا تفكر؟';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get removePhoto => 'إزالة الصورة';

  @override
  String get allowReposts => 'السماح بإعادة النشر';

  @override
  String get adsCannotRepost => 'لا يمكن إعادة نشر الإعلانات.';

  @override
  String get othersCanShare => 'يمكن للآخرين مشاركة هذا في الخلاصة الرئيسية.';

  @override
  String get repostHidden => 'إعادة النشر مخفية لهذا المنشور.';

  @override
  String get posting => 'جارٍ النشر...';

  @override
  String get post => 'نشر';

  @override
  String get postTextEmptyError => 'لا يمكن أن يكون نص المنشور فارغًا.';

  @override
  String get adLinkInvalidError =>
      'رابط الإعلان مطلوب ويجب أن يكون رابط http/https صالحًا.';

  @override
  String get react => 'تفاعل';

  @override
  String get tapAgainToRemoveReaction => 'اضغط مرة أخرى لإزالة تفاعلك.';

  @override
  String get visitAd => 'زيارة الإعلان';

  @override
  String get repostToHomeFeed => 'إعادة النشر إلى الخلاصة';

  @override
  String get invalidAdLink => 'رابط الإعلان غير صالح.';

  @override
  String get couldNotOpenAdLink => 'تعذر فتح رابط الإعلان.';

  @override
  String get shared => 'مُعاد نشره';

  @override
  String homeReactionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تفاعلات',
      one: 'تفاعل واحد',
    );
    return '$_temp0';
  }

  @override
  String get saving => 'جارٍ الحفظ...';

  @override
  String get editPost => 'تعديل المنشور';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get comments => 'التعليقات';

  @override
  String get noCommentsYetBeFirst => 'لا توجد تعليقات بعد.\nكن أول من يرد.';

  @override
  String get writeAComment => 'اكتب تعليقًا...';

  @override
  String get thisIsYourPost => 'هذا منشورك.';

  @override
  String get deletePost => 'حذف المنشور';

  @override
  String get alreadyConnectedNoRequestNeeded =>
      'أنتم متصلون بالفعل - لا حاجة لطلب جديد.';

  @override
  String get sendFriendRequest => 'إرسال طلب صداقة';

  @override
  String get sendChallenge => 'إرسال تحدٍ';

  @override
  String get deletePostQuestion => 'حذف المنشور؟';

  @override
  String get deletePostMessage =>
      'سيؤدي هذا إلى إزالة منشورك وتعليقاته للجميع.';

  @override
  String challengeTarget(Object name) {
    return 'تحدي $name';
  }

  @override
  String get challengeInfoBody =>
      'اربح المباراة لتحصل على +10 نقاط مهارة للفريق (تبويب الفريق). صديقك لا يخسر شيئًا إذا لم يفز.';

  @override
  String get chooseAGame => 'اختر لعبة';

  @override
  String get send => 'إرسال';

  @override
  String get explorePeople => 'استكشاف الأشخاص';

  @override
  String get searchByUsername => 'ابحث باسم المستخدم...';

  @override
  String get explorePeopleHint =>
      'اكتب حرفين على الأقل. اعثر على شخص جديد أو أضفه كصديق.';

  @override
  String get jumpInMeetPlayers => 'ابدأ وتعرّف على لاعبين';

  @override
  String noUsernamesMatch(Object query) {
    return 'لا توجد أسماء مستخدم تطابق \"$query\".';
  }

  @override
  String get exploreLinkFriend => 'أصدقاء - افتح المنشورات من سياق الخلاصة';

  @override
  String get exploreLinkPendingOutgoing => 'تم إرسال الطلب - بانتظارهم';

  @override
  String get exploreLinkPendingIncoming =>
      'يريد الاتصال بك - اقبل من الملف الشخصي';

  @override
  String get exploreLinkNone => 'غير متصلين بعد';

  @override
  String get noPostsFromProfileYet =>
      'لا توجد منشورات من هذا الملف في خلاصتك بعد. اسحب للتحديث في الصفحة الرئيسية.';

  @override
  String get noPostsYetTapNewPost =>
      'لا توجد منشورات بعد.\nاضغط منشور جديد لمشاركة شيء.';

  @override
  String get cantRepostOwnPost => 'لا يمكنك إعادة نشر منشورك الخاص.';

  @override
  String get thisPostCannotBeReposted => 'لا يمكن إعادة نشر هذا المنشور.';

  @override
  String get someone => 'شخص ما';

  @override
  String fromAuthor(Object author) {
    return 'من $author';
  }

  @override
  String get imageAttachedToRepost => 'الصورة مرفقة في إعادة النشر هذه.';

  @override
  String get addCommentOptional => 'أضف تعليقًا (اختياريًا)...';

  @override
  String get publishRepost => 'نشر إعادة المنشور';

  @override
  String get repostPublished => 'تم نشر إعادة المنشور';

  @override
  String get add => 'إضافة';

  @override
  String get privacySecurity => 'الخصوصية والأمان';

  @override
  String get rateTheApp => 'قيّم التطبيق';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get pushNotifications => 'إشعارات الدفع';

  @override
  String get pushNotificationsSubtitle =>
      'أوقفها لإيقاف إشعارات الخادم ونسخ الإشعارات داخل التطبيق. سيتم حذف رمز الجهاز ولن يُرسل شيء حتى تعيد تشغيلها.';

  @override
  String get matchInvites => 'دعوات اللعب';

  @override
  String get matchInvitesSubtitle =>
      'عند الإيقاف: لن ترى الدعوات الواردة ولن يراك الأصدقاء لتحديات اللعب عبر الإنترنت';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutQuestion => 'تسجيل الخروج؟';

  @override
  String get signOutMessage => 'ستحتاج لتسجيل الدخول مرة أخرى لاستخدام حسابك.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get signedOut => 'تم تسجيل الخروج';

  @override
  String get comingSoon => 'قريبًا.';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get friendRequests => 'طلبات الصداقة';

  @override
  String get noPendingFriendRequests => 'لا توجد طلبات صداقة معلقة.';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get account => 'الحساب';

  @override
  String get couldNotLoadProfile => 'تعذر تحميل الملف الشخصي';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get usernameAllowedHint => 'حروف وأرقام ومسافات وشرطة سفلية';

  @override
  String get enterUsername => 'أدخل اسم مستخدم';

  @override
  String get usernameAllowedChars =>
      'استخدم فقط الحروف والأرقام والمسافات والشرطة السفلية';

  @override
  String get newPhotoSelected => 'تم اختيار صورة جديدة';

  @override
  String get chooseProfilePhoto => 'اختر صورة الملف الشخصي';

  @override
  String get save => 'حفظ';

  @override
  String get noNewPhoto => 'لا توجد صورة جديدة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get allCaughtUp => 'أنت على اطلاع كامل';

  @override
  String get notificationsCaughtUpSubtitle =>
      'سترى هنا فقط التنبيهات الواضحة للإعجابات والتعليقات والدعوات ودعوات الغرف. اسحب للتحديث للحصول على أحدث المستجدات.';

  @override
  String get notifSomeoneReacted => 'تفاعل شخص مع منشورك.';

  @override
  String get notifSomeoneCommented => 'علّق شخص على منشورك.';

  @override
  String get notifFriendInvite => 'لديك دعوة صداقة جديدة.';

  @override
  String get notifRoomInviteWaiting => 'لديك دعوة غرفة بانتظارك.';

  @override
  String get notifNewNotification => 'لديك إشعار جديد.';

  @override
  String get notifReviewInvite => 'راجع هذه الدعوة وحدد قبولها أو رفضها.';

  @override
  String get notifReviewInviteShort => 'راجع الدعوة واختر قبول أو رفض.';

  @override
  String get notifPostLikeOpenHint =>
      'افتح المنشور لمعرفة من تفاعل والانضمام للمحادثة.';

  @override
  String get notifPostCommentOpenHint =>
      'افتح التعليقات للقراءة والرد من خلاصتك.';

  @override
  String get notifFriendRequestAcceptedStatus => 'تم قبول طلب الصداقة هذا.';

  @override
  String get notifFriendRequestNoLongerPending =>
      'طلب الصداقة هذا لم يعد معلقًا.';

  @override
  String get notifPartyRoomInviteOpenHint =>
      'انضم إلى دعوة الغرفة من تبويب أونلاين عندما تكون جاهزًا.';

  @override
  String get friendRequestNoLongerValid =>
      'طلب الصداقة هذا لم يعد صالحًا (تمت إزالة الحساب/الطلب).';

  @override
  String get friendRequestAccepted => 'تم قبول طلب الصداقة.';

  @override
  String get friendRequestDeclined => 'تم رفض طلب الصداقة.';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي.';

  @override
  String get declined => 'تم الرفض.';

  @override
  String get decline => 'رفض';

  @override
  String get accept => 'قبول';

  @override
  String get matchAccepted => 'تم قبول التحدي';

  @override
  String get opponent => 'الخصم';

  @override
  String get game => 'اللعبة';

  @override
  String get ready => 'جاهز';

  @override
  String get couldNotLoadOnline => 'تعذر تحميل قسم أونلاين';

  @override
  String get tryAgain => 'حاول مجددًا';

  @override
  String get online => 'أونلاين';

  @override
  String get onlineHeaderSubtitle =>
      'تحدَّ الأصدقاء وغرف اللعب والألعاب السريعة';

  @override
  String get friends => 'الأصدقاء';

  @override
  String get tapFriendToChallenge => 'اضغط على صديق لإرسال تحدٍ عبر الإنترنت';

  @override
  String get partyRooms => 'غرف اللعب الجماعية';

  @override
  String get partyRoomsSubtitle => 'الدعوات والغرف التي انضممت إليها';

  @override
  String get playInvites => 'دعوات اللعب';

  @override
  String get playInvitesSubtitle => 'أصدقاؤك دعوك لمباراة';

  @override
  String get refresh => 'تحديث';

  @override
  String get noPendingInvites => 'لا توجد دعوات معلقة.';

  @override
  String get activeMatches => 'المباريات النشطة';

  @override
  String get tapReadyWhenSet => 'اضغط جاهز عندما تكون مستعدًا للعب';

  @override
  String get games => 'الألعاب';

  @override
  String get gamesSubtitle =>
      'تدرب ضد الذكاء الاصطناعي أو افتح غرفة لعب جماعية';

  @override
  String get rateAppFromPhoneHint =>
      'قيّمنا من متجر التطبيقات على هاتفك بعد نشر التطبيق.';

  @override
  String get couldNotOpenStoreLink => 'تعذر فتح رابط المتجر.';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountQuestion => 'حذف الحساب؟';

  @override
  String get deleteAccountMessage =>
      'سيؤدي ذلك إلى حذف حسابك وبياناتك نهائيًا.';

  @override
  String get accountDeleted => 'تم حذف الحساب';

  @override
  String get failedToDeleteAccount => 'فشل حذف الحساب';

  @override
  String get delete => 'حذف';

  @override
  String get thisPlayer => 'هذا اللاعب';

  @override
  String get removeFriendQuestion => 'إزالة الصديق؟';

  @override
  String removeFriendMessage(Object name) {
    return 'سيتم إزالة $name من قائمة أصدقائك. يمكنك إرسال طلب جديد لاحقًا من الصفحة الرئيسية.';
  }

  @override
  String get remove => 'إزالة';

  @override
  String removedFromFriends(Object name) {
    return 'تمت إزالة $name من الأصدقاء';
  }

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noFriendsYet => 'لا يوجد أصدقاء بعد';

  @override
  String get friendsEmptyHint =>
      'اقبل الطلبات أو أرسل طلبًا من منشور أحد الأشخاص في الصفحة الرئيسية.';

  @override
  String get player => 'لاعب';

  @override
  String get removeFriend => 'إزالة الصديق';

  @override
  String get draw => 'تعادل';

  @override
  String get youWon => 'لقد فزت';

  @override
  String get youLost => 'لقد خسرت';

  @override
  String get historyAndLiveInvites => 'السجل والدعوات المباشرة';

  @override
  String get loadingYourMatches => 'جارٍ تحميل مبارياتك...';

  @override
  String get couldNotLoadChallenges => 'تعذر تحميل التحديات';

  @override
  String get noChallengesYet => 'لا توجد تحديات بعد';

  @override
  String get challengesEmptyHint =>
      'ادعُ صديقًا من الصفحة الرئيسية أو تبويب أونلاين - ستظهر هنا نتائج المباريات المنتهية.';

  @override
  String get vsPrefix => 'ضد ';

  @override
  String get helpGetStarted => 'البدء';

  @override
  String get helpQMainTabs => 'ما هي التبويبات الرئيسية؟';

  @override
  String get helpAMainTabs =>
      'الصفحة الرئيسية هي خلاصتك الاجتماعية وأصدقاؤك. أونلاين للتحديات المباشرة والألعاب مع من تعرفهم. الفريق مخصص لفريقك المكوّن من ستة لاعبين والتدريب والمعارك. الملف الشخصي لحسابك والطلبات والإعدادات.';

  @override
  String get helpQAddFriends => 'كيف أضيف أصدقاء؟';

  @override
  String get helpAAddFriends =>
      'أرسل طلبًا من الصفحة الرئيسية. يقبل الطرف الآخر الطلب من الملف الشخصي -> طلبات الصداقة. يجب أن يملك الطرفان حسابًا.';

  @override
  String get helpQTeamTab => 'كيف يعمل تبويب الفريق؟';

  @override
  String get helpATeamTab =>
      'أنشئ فريقًا وسمّ لاعبيك ثم درّب الإحصاءات بنقاط المهارة. يمكنك تشغيل التحديات اليومية وسباقات التشكيلة والتحديات الودية ومباراة الأكاديمية الفردية لنقاط إضافية - راجع كل بطاقة للقواعد والحدود.';

  @override
  String get helpQSaveSquad => 'لماذا لا يمكنني حفظ فريقي؟';

  @override
  String get helpASaveSquad =>
      'تأكد أنك مسجل الدخول ومتصل بالإنترنت. افتح تبويب الفريق بعد تسجيل الدخول حتى تتم مزامنة فريقك مع ملفك.';

  @override
  String get helpTroubleshooting => 'استكشاف الأخطاء';

  @override
  String get helpQStuck => 'يبدو أن هناك شيئًا عالقًا';

  @override
  String get helpAStuck =>
      'اسحب للتحديث في الملف الشخصي. في أونلاين استخدم التحديث حيث يظهر. إذا لم تُحمّل لعبة، ارجع وافتح التحدي مرة أخرى.';

  @override
  String get helpQSignedOut => 'سجلت الخروج بالخطأ';

  @override
  String get helpASignedOut =>
      'سجّل الدخول مرة أخرى من شاشة تسجيل الدخول بنفس البريد الإلكتروني. تبقى بياناتك السحابية مرتبطة بحسابك.';

  @override
  String get contact => 'التواصل';

  @override
  String get privacyYourAccountData => 'حسابك وبياناتك';

  @override
  String get privacyYourAccountDataBody =>
      'تسجل الدخول بالبريد الإلكتروني وكلمة المرور. تتم إدارة جلستك بأمان عبر نظامنا الخلفي (Supabase Auth). نخزن بيانات الملف الشخصي التي تختار حفظها مثل الاسم والصورة.';

  @override
  String get privacyDataUsageTitle => 'كيف نستخدم بياناتك';

  @override
  String get privacyDataUsageHome =>
      'ميزات الصفحة الرئيسية والاجتماعية: المنشورات والتعليقات والإعجابات وطلبات الصداقة.';

  @override
  String get privacyDataUsageOnline =>
      'اللعب عبر الإنترنت: التحديات وحالة المباراة وسجلات الألعاب ذات الصلة.';

  @override
  String get privacyDataUsageTeam =>
      'وضع الفريق: التشكيلة ونقاط المهارة والتحديات اليومية ولوحات الصدارة.';

  @override
  String get privacyFriendsVisibilityTitle => 'الأصدقاء والظهور';

  @override
  String get privacyFriendsVisibilityBody =>
      'عند قبول طلب صداقة، يمكن لكل منكما التفاعل في الميزات التي تتطلب أصدقاء (مثل الدعوات ومعارك الفريق). الطلبات المرفوضة لا تظهر كاتصالات نشطة.';

  @override
  String get privacySecurityTipsTitle => 'نصائح الأمان';

  @override
  String get privacyTipStrongPassword =>
      'استخدم كلمة مرور قوية وفريدة لهذا التطبيق.';

  @override
  String get privacyTipSignOutShared =>
      'سجل الخروج من الملف الشخصي عند استخدام جهاز مشترك.';

  @override
  String get privacyTipUnauthorizedAccess =>
      'إذا شككت بوصول غير مصرح به، غيّر كلمة المرور وسجل الخروج من جميع الجلسات من مزود الحساب إذا كان متاحًا.';

  @override
  String get privacyQuestionsTitle => 'أسئلة';

  @override
  String get privacyQuestionsBody =>
      'هذه الشاشة ملخص للمنتج وليست عقدًا قانونيًا. للشروط الرسمية أو طلبات البيانات، تواصل مع الجهة المشغلة للتطبيق وانشر سياسة خصوصية كاملة في المكان المتوقع من المستخدمين.';

  @override
  String get practiceVsAi => 'تدريب ضد الذكاء الاصطناعي';

  @override
  String get singleDeviceNotOnlineMatch =>
      'على جهاز واحد - ليست مباراة عبر الإنترنت.';

  @override
  String get singleDeviceChallengeFriendHint =>
      'على جهاز واحد - تحدَّ صديقًا عبر الإنترنت لمواجهة حقيقية.';

  @override
  String get singleDeviceSameDuelHint =>
      'على جهاز واحد - نفس المواجهة عبر الإنترنت مع صديق.';

  @override
  String vsAiNotAvailableYet(Object title) {
    return 'اللعب ضد الذكاء الاصطناعي في $title غير متاح بعد.';
  }

  @override
  String createRoomTitle(Object title) {
    return 'إنشاء غرفة $title';
  }

  @override
  String get roomSize => 'حجم الغرفة';

  @override
  String playersMax(Object count) {
    return 'حد أقصى $count لاعبين';
  }

  @override
  String inviteExactlyFriends(Object count) {
    return 'ادعُ $count أصدقاء بالضبط';
  }

  @override
  String get creating => 'جارٍ الإنشاء...';

  @override
  String get createRoom => 'إنشاء الغرفة';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get noFriendsYetAcceptFromHome =>
      'لا يوجد أصدقاء بعد. اقبل الطلبات من الصفحة الرئيسية.';

  @override
  String get friend => 'صديق';

  @override
  String get invitedYouToPlay => ' دعاك للعب ';

  @override
  String get activeMatchesMultiHint =>
      'كل بطاقة تمثل مباراة مستقلة. اضغط جاهز لكل مباراة؛ وعندما يصبح الطرفان جاهزين في نفس البطاقة يمكنك بدء اللعبة منها.';

  @override
  String get bothPlayersReady => 'اللاعبان جاهزان.';

  @override
  String readyStatusLine(Object youStatus, Object themStatus) {
    return 'أنت: $youStatus - الطرف الآخر: $themStatus';
  }

  @override
  String get notReady => 'غير جاهز';

  @override
  String get waiting => 'بانتظار';

  @override
  String get waitingForOpponent => 'بانتظار الخصم';

  @override
  String get noPartyRoomInvitesYet => 'لا توجد دعوات لغرف اللعب الجماعية بعد.';

  @override
  String inHostsPartyRoom(Object host) {
    return 'في غرفة $host';
  }

  @override
  String hostInvitedYou(Object host) {
    return '$host دعاك';
  }

  @override
  String gameUpToPlayers(Object game, Object players) {
    return '$game - حتى $players لاعبين';
  }

  @override
  String get leave => 'مغادرة';

  @override
  String get openLobby => 'فتح اللوبي';

  @override
  String get joinRoom => 'انضمام للغرفة';

  @override
  String get aPlayer => 'لاعب';

  @override
  String playerLeftGameRoom(Object name) {
    return 'غادر $name غرفة اللعب.';
  }

  @override
  String playersLeftGameRoom(int count) {
    return 'غادر $count لاعبين غرفة اللعب.';
  }

  @override
  String get unsupportedRoomGame => 'لعبة غرفة غير مدعومة.';

  @override
  String get openSlot => 'مقعد فارغ';

  @override
  String slotNumber(int index) {
    return 'المقعد $index';
  }

  @override
  String get waitingForInvite => 'بانتظار الدعوة...';

  @override
  String get readyRoom => 'غرفة الجاهزية';

  @override
  String get readyRoomSubtitle =>
      'يقبل الأصدقاء الدعوة من أونلاين -> دعوات غرف اللعب الجماعية. لا يوجد رمز للنسخ - تبدأ الجولة عند امتلاء كل المقاعد.';

  @override
  String joinedOutOf(int joined, int max) {
    return '$joined / $max';
  }

  @override
  String get fullSquad => 'الفريق مكتمل';

  @override
  String get recruiting => 'جارٍ التجنيد';

  @override
  String get roster => 'التشكيلة';

  @override
  String get launchGame => 'ابدأ اللعبة';

  @override
  String get waitingForPlayers => 'بانتظار اللاعبين';

  @override
  String get you => 'أنت';

  @override
  String playerNumber(int number) {
    return 'اللاعب $number';
  }

  @override
  String flashMatchOnlineDesc(int rounds) {
    return 'كل جولة تصبح أصعب مع أيقونات أكثر وعقوبات أقوى؛ وإعادة ترتيب خفيفة تظهر فقط في الجولات المتأخرة - $rounds جولات. أقل وقت إجمالي يفوز.';
  }

  @override
  String flashMatchOfflineDesc(int rounds) {
    return 'مرر الهاتف: $rounds جولات لكل لاعب؛ الصعوبة تزيد عبر نمو الشبكة والعقوبات، مع إعادة ترتيب خفيفة في الجولات المتأخرة (نافذة الوقت تبقى عادلة). أقل مجموع يفوز.';
  }

  @override
  String get loadingRoom => 'جارٍ تحميل الغرفة...';

  @override
  String waitingJoinedOutOf(int joined, int max) {
    return 'بانتظار: $joined / $max';
  }

  @override
  String get tapStartWhenReady => 'اضغط بدء عندما تكون جاهزًا.';

  @override
  String playerTurnNext(Object player) {
    return '$player - دوره التالي.';
  }

  @override
  String get runComplete => 'اكتمل التشغيل!';

  @override
  String get matchOver => 'انتهت المباراة!';

  @override
  String playerRoundProgress(Object player, int round, int total) {
    return '$player · الجولة $round / $total';
  }

  @override
  String get memorize => 'احفظ';

  @override
  String flashMatchCueMetaBasic(int flashMs, int choices) {
    return '$flashMs مللي ثانية · $choices خيارات';
  }

  @override
  String flashMatchCueMetaWithReshuffle(
    int flashMs,
    int choices,
    int scrambleMs,
  ) {
    return '$flashMs مللي ثانية · $choices خيارات · إعادة ترتيب كل $scrambleMs مللي ثانية';
  }

  @override
  String get tapTheMatch => 'اضغط المطابق';

  @override
  String penaltyMs(int ms) {
    return 'عقوبة +$ms مللي ثانية';
  }

  @override
  String get startNextPlayer => 'ابدأ اللاعب التالي';

  @override
  String get startMatch => 'ابدأ المباراة';

  @override
  String winnerWithMs(Object name, int ms) {
    return 'الفائز: $name ($ms مللي ثانية)';
  }

  @override
  String tieAtMsPlayers(int ms, Object players) {
    return 'تعادل عند $ms مللي ثانية: $players';
  }

  @override
  String totalMs(int ms) {
    return 'الإجمالي: $ms مللي ثانية';
  }

  @override
  String get playAgain => 'العب مرة أخرى';

  @override
  String get roomBoard => 'لوحة الغرفة';

  @override
  String get noScoresYet => 'لا توجد نتائج بعد.';

  @override
  String totalMsLabel(Object value) {
    return '$value مللي ثانية';
  }

  @override
  String get totals => 'الإجماليات';

  @override
  String get rpsInvalidThrow => 'رمية غير صالحة';

  @override
  String get rpsNotInThisMatch => 'أنت لست ضمن هذه المباراة';

  @override
  String get rpsMatchAlreadyFinished => 'انتهت المباراة بالفعل';

  @override
  String get rpsAlreadyLockedForRound => 'تم قفل اختيارك لهذه الجولة بالفعل';

  @override
  String get roundComplete => 'اكتملت الجولة';

  @override
  String get drawReplayRound => 'تعادل - أعد الجولة';

  @override
  String get youTakeRound => 'تحسم هذه الجولة';

  @override
  String get aiTakesRound => 'الذكاء الاصطناعي يحسم الجولة';

  @override
  String get challengerWinsRound => 'المتحدي يفوز بالجولة';

  @override
  String get hostWinsRound => 'المضيف يفوز بالجولة';

  @override
  String opponentTakesRound(Object name) {
    return '$name يحسم الجولة';
  }

  @override
  String get couldNotResetBout =>
      'تعذر إعادة ضبط المواجهة. تحقق من الاتصال ثم حاول مرة أخرى.';

  @override
  String rpsSetNumber(int number) {
    return 'المجموعة $number';
  }

  @override
  String get chooseYourThrow => 'اختر رميتك';

  @override
  String get boutFinished => 'انتهت المواجهة';

  @override
  String tapCardRevealVs(Object name) {
    return 'اضغط بطاقة - كشف متزامن ضد $name';
  }

  @override
  String get waitingForRound => 'بانتظار الجولة...';

  @override
  String get sendingYourPick => 'جارٍ إرسال اختيارك...';

  @override
  String get opponentStillChoosing => 'الخصم ما زال يختار...';

  @override
  String get aiThinking => 'الذكاء الاصطناعي يفكر...';

  @override
  String get rpsRock => 'حجر';

  @override
  String get rpsPaper => 'ورقة';

  @override
  String get rpsScissors => 'مقص';

  @override
  String get throwLockedIn => 'تم قفل الرمية';

  @override
  String get hiddenUntilBothThrow => 'مخفي عن خصمك حتى يرمي الطرفان.';

  @override
  String get aiPickingNext => 'تمهّل - الذكاء الاصطناعي يختار الآن.';

  @override
  String get scoreboard => 'لوحة النتائج';

  @override
  String firstToRoundWinsTakesBout(int count) {
    return 'أول من يصل إلى $count انتصارات جولات يحسم المواجهة';
  }

  @override
  String throwLabelWithHint(Object label, Object hint) {
    return 'رمية $label. $hint';
  }

  @override
  String get crushesScissors => 'يسحق المقص';

  @override
  String get coversRock => 'يغطي الحجر';

  @override
  String get cutsPaper => 'يقطع الورق';

  @override
  String get deadHeat => 'تعادل تام';

  @override
  String get honorSharedRematch => 'الشرف متقاسم - إعادة مواجهة على اللقب؟';

  @override
  String get whatABoutSoakItIn => 'يا لها من مواجهة - استمتع باللحظة!';

  @override
  String get closeFightRematch =>
      'مواجهة متقاربة - ضغطة واحدة عن إعادة المباراة.';

  @override
  String get challengerSideWins => 'جهة المتحدي تفوز';

  @override
  String get hostSideWins => 'جهة المضيف تفوز';

  @override
  String get boutOver => 'انتهت المواجهة';

  @override
  String rpsShareBody(
    Object opponent,
    int leftScore,
    int rightScore,
    Object leftLabel,
    Object rightLabel,
    Object headline,
  ) {
    return 'حجر ورقة مقص ضد $opponent\nالنتيجة النهائية: $leftScore — $rightScore ($leftLabel / $rightLabel)\n$headline';
  }

  @override
  String youWinDuelScore(int mine, int opp) {
    return 'فزت بالمواجهة $mine–$opp';
  }

  @override
  String opponentWinsDuelScore(Object name, int mine, int opp) {
    return 'فاز $name بالمواجهة $mine–$opp';
  }

  @override
  String get pickOnlyFromSquadSheet => 'اختر لاعبين من ورقة فريقك فقط.';

  @override
  String get couldNotSubmitPicks => 'تعذر إرسال الاختيارات';

  @override
  String get alreadySubmittedOrSyncIssue =>
      'تم الإرسال بالفعل أو توجد مشكلة مزامنة';

  @override
  String youTakeRoundZones(int you, int opp) {
    return 'تحسم هذه الجولة ($you–$opp مناطق)';
  }

  @override
  String opponentTakesRoundZones(Object name, int you, int opp) {
    return '$name يحسم هذه الجولة ($you–$opp مناطق)';
  }

  @override
  String zonesDrawnYouEdgeStrength(int you, int opp) {
    return 'تعادل في المناطق - تتفوق بالقوة ($you–$opp)';
  }

  @override
  String zonesDrawnOpponentEdges(Object name, int you, int opp) {
    return 'تعادل في المناطق - $name يتفوق ($you–$opp)';
  }

  @override
  String get honorsEvenDrawnRoundNoPoint =>
      'تكافؤ تام - جولة متعادلة (بدون نقطة)';

  @override
  String get couldNotSyncRoundTryAgain => 'تعذر مزامنة الجولة - حاول مرة أخرى';

  @override
  String get couldNotStartRematch =>
      'تعذر بدء إعادة المباراة. تحقق من الاتصال ثم حاول مرة أخرى.';

  @override
  String fantasyYourSquadSubtitle(int cards, int starters) {
    return '$cards بطاقات · ابدأ بـ $starters · طابق السمة مع نداء الملعب لكل منطقة';
  }

  @override
  String get lastRound => 'الجولة الأخيرة';

  @override
  String get cardsLockedSeeResultBelow =>
      'تم قفل البطاقات - شاهد النتيجة بالأسفل';

  @override
  String startersCount(int picked, int total) {
    return 'الأساسيون ($picked/$total)';
  }

  @override
  String get clear => 'مسح';

  @override
  String get lockLineup => 'قفل التشكيلة';

  @override
  String get lineupLocked => 'تم قفل التشكيلة';

  @override
  String waitingForOpponentToSubmit(Object name) {
    return 'بانتظار $name لإرسال اختياره...';
  }

  @override
  String nextRoundScoreTarget(int mine, int opp, int target) {
    return 'الجولة التالية ($mine–$opp · أول من يصل إلى $target)';
  }

  @override
  String fantasyDuelShareBody(
    Object opponent,
    int mine,
    int opp,
    int target,
    Object summary,
  ) {
    return 'مواجهة بطاقات خيال ضد $opponent\nانتصارات الجولات: $mine — $opp (الأول إلى $target)\n$summary';
  }

  @override
  String get fantasyZoneLeftWing => 'الجناح الأيسر';

  @override
  String get fantasyZoneNo10 => 'رقم 10';

  @override
  String get fantasyZoneWideBack => 'الظهير الواسع';

  @override
  String get matchday => 'يوم المباراة';

  @override
  String get vsUpper => 'ضد';

  @override
  String get squadManager => 'مدير الفريق';

  @override
  String roundNumber(int number) {
    return 'الجولة $number';
  }

  @override
  String firstToRoundWinsVsFriend(int count) {
    return 'الأول إلى $count انتصارات جولات · ضد صديق';
  }

  @override
  String firstToRoundWins(int count) {
    return 'الأول إلى $count انتصارات جولات';
  }

  @override
  String secondsShort(int seconds) {
    return '$secondsث';
  }

  @override
  String get howDuelWorks => 'كيف تعمل المواجهة';

  @override
  String get tapToExpandRules => 'اضغط لتوسيع القواعد';

  @override
  String fantasyRule1(int squadSize) {
    return 'تسحب $squadSize بطاقات — رقم القميص هو القيمة الأساسية. كل بطاقة لها سمة (Blitz / Maestro / Iron) حسب الدور.';
  }

  @override
  String fantasyRule2(int starters, Object zone1, Object zone2, Object zone3) {
    return 'اضغط $starters بطاقات بترتيب القفل: $zone1 -> $zone2 -> $zone3.';
  }

  @override
  String fantasyRule3(int bonus) {
    return 'الملعب يطلب سمة واحدة لكل منطقة (انظر الشريط أدناه). إذا طابقت سمة بطاقتك ذلك النداء، أضف +$bonus قبل المقارنة - رقم القميص وحده قد لا يكفي.';
  }

  @override
  String get fantasyRule4 =>
      'افز بمناطق أكثر من خصمك؛ وإذا انقسمت المناطق، تحسم القيمة الفعالة الإجمالية (الأساس + السمة + المكافآت).';

  @override
  String fantasyRuleOffline(int count) {
    return 'مواجهة بدون إنترنت: الأول إلى $count انتصارات جولات؛ كل جولة بيد وملعب جديدين.';
  }

  @override
  String fantasyRuleOnline(int count) {
    return 'أونلاين: الأول إلى $count انتصارات جولات - بعد كل كشف يحصل اللاعبان على مجموعة جديدة من الخادم للجولة التالية.';
  }

  @override
  String fantasyPitchMatchBonus(int bonus) {
    return '+$bonus مطابقة ملعب';
  }

  @override
  String get noSuitMatch => 'لا توجد مطابقة سمة';

  @override
  String fantasySuitBonusWithName(int bonus, Object suitName) {
    return '+$bonus $suitName';
  }

  @override
  String everyoneMustFinishRoundsBeforeNewRun(int rounds) {
    return 'يجب أن يُكمل الجميع كل $rounds جولات قبل تشغيل محاولة جديدة.';
  }

  @override
  String timeRanOutBeforeFinishingRoundsLose(int rounds) {
    return 'انتهى الوقت قبل إكمال كل $rounds جولات. خسرت - النتيجة لا تُحتسب.';
  }

  @override
  String tooEarlyTryAgain(int left, int max) {
    return 'مبكر جدًا. حاول مجددًا ($left/$max متبقية).';
  }

  @override
  String get roundFailedAfterEarlyTaps => 'فشلت الجولة بعد 3 ضغطات مبكرة.';

  @override
  String roundFailedPenaltyMs(int ms) {
    return 'فشلت الجولة (3 ضغطات مبكرة). العقوبة: ${ms}ms.';
  }

  @override
  String playerUpNextPreviousTurnFailed(Object player) {
    return '$player التالي. الدور السابق فشل (3 ضغطات مبكرة).';
  }

  @override
  String get turnFailedAfterEarlyTaps => 'فشل الدور بعد 3 ضغطات مبكرة.';

  @override
  String waitingOpponentFinishRounds(int rounds) {
    return 'بانتظار الخصم ليكمل كل $rounds جولات...';
  }

  @override
  String youWinOpponentTimedOut(Object name) {
    return 'فزت - نفد وقت $name قبل إكمال كل الجولات.';
  }

  @override
  String waitingUserFinishRounds(Object name, int rounds) {
    return 'بانتظار $name ليكمل كل $rounds جولات...';
  }

  @override
  String youWinTotalVs(int myTotal, Object name, int oppTotal) {
    return 'فزت! الإجمالي: $myTotal ms مقابل $name: $oppTotal ms';
  }

  @override
  String opponentWinsTotalVs(Object name, int oppTotal, int myTotal) {
    return 'فاز $name. الإجمالي: $oppTotal ms مقابل $myTotal ms لديك';
  }

  @override
  String finalDrawTotals(int total) {
    return 'تعادل نهائي: كلا الإجماليين $total ms';
  }

  @override
  String reactionRelayOnlineSubtitle(int seconds) {
    return 'ضغطات كلاسيكية -> ثم مطاردة الهدف. تغلّب على الساعة: $seconds ث لكل 5 جولات.';
  }

  @override
  String reactionRelayOfflineSubtitle(int seconds) {
    return 'تمرير ولعب. الجولات 1-2 GO ثابتة - 3-5 هدف متحرك. إجمالي $seconds ث.';
  }

  @override
  String playersCount(int count) {
    return '$count لاعبين';
  }

  @override
  String get chaseUpper => 'مطاردة';

  @override
  String get classicUpper => 'كلاسيكي';

  @override
  String roundShortProgress(int round, int total) {
    return 'ج$round / $total';
  }

  @override
  String get nextRound => 'الجولة التالية';

  @override
  String waitAllPlayersFinishThenReset(int rounds) {
    return 'انتظر حتى يُكمل كل لاعب $rounds جولات. بعدها يمكنك بدء محاولة جديدة وتتم إعادة تعيين النتائج للجميع.';
  }

  @override
  String get yourRun => 'محاولتك';

  @override
  String get noSplitsYetStartMatch =>
      'لا توجد نتائج جزئية بعد - ابدأ المباراة.';

  @override
  String get ms => 'ms';

  @override
  String get roundLog => 'سجل الجولات';

  @override
  String get winsAppearAfterEachRound => 'تظهر الانتصارات هنا بعد كل جولة.';

  @override
  String roundMsLabel(int round) {
    return 'الجولة $round · ms';
  }

  @override
  String get thisFriend => 'هذا الصديق';

  @override
  String get editYourPostHint => 'عدّل منشورك...';

  @override
  String get postToFeed => 'انشر في الخلاصة';

  @override
  String get addSomeTextToPost => 'أضف بعض النص للنشر';

  @override
  String get postedToHomeFeed => 'تم النشر في خلاصة الصفحة الرئيسية';

  @override
  String get homePostDeleted => 'تم حذف المنشور';

  @override
  String get homePostUpdated => 'تم تحديث المنشور';

  @override
  String alreadyFriendsWith(Object name) {
    return 'أنت بالفعل صديق لـ $name.';
  }

  @override
  String friendRequestSentTo(Object name) {
    return 'تم إرسال طلب صداقة إلى $name';
  }

  @override
  String challengeSentTo(Object game, Object name) {
    return 'تم إرسال تحدي $game إلى $name';
  }

  @override
  String leftTheMatch(Object name, Object game) {
    return 'غادر $name مباراة $game.';
  }

  @override
  String roundsLabel(int count) {
    return 'الجولات $count';
  }

  @override
  String get finished => 'انتهت';

  @override
  String get inProgress => 'جارية';

  @override
  String get betweenRounds => 'بين الجولات';

  @override
  String get resetMatch => 'إعادة تعيين المباراة';

  @override
  String get restartRound => 'إعادة الجولة';

  @override
  String get startRound => 'بدء الجولة';

  @override
  String get reactionRelayStartRoundHint =>
      'ابدأ الجولة 1. كل لاعب لديه فرصة تفاعل واحدة في كل جولة.';

  @override
  String get reactionRelayYouPlayThisRound =>
      'ستلعب هذه الجولة على جهازك. اضغط تسليح عندما تكون جاهزا.';

  @override
  String reactionRelayPassPhoneTo(Object player) {
    return 'مرر الهاتف إلى $player. اضغط تسليح عندما تكون جاهزا.';
  }

  @override
  String get arm => 'تسليح';

  @override
  String get waitForGo => 'انتظر GO...';

  @override
  String get goTap => 'GO! TAP!';

  @override
  String roundWinnerMs(int round, Object player, int ms) {
    return 'الفائز بالجولة $round: $player ($ms ms)';
  }

  @override
  String get yourRunFinished => 'انتهت محاولتك.';

  @override
  String get noChampionYet => 'لا يوجد بطل بعد.';

  @override
  String championLabel(Object name) {
    return 'البطل: $name';
  }

  @override
  String bestReactionMs(int ms) {
    return 'أفضل تفاعل: $ms ms';
  }

  @override
  String get submitting => 'جارٍ الإرسال...';

  @override
  String get submitScore => 'إرسال النتيجة';

  @override
  String get roomLeaderboard => 'لوحة ترتيب الغرفة';

  @override
  String get winnersQueue => 'قائمة الفائزين';

  @override
  String get noRoundsFinishedYet => 'لم تنته أي جولات بعد.';

  @override
  String get finalWinnersRanking => 'الترتيب النهائي للفائزين';

  @override
  String get currentStandings => 'الترتيب الحالي';

  @override
  String get noFinalRankingYet => 'لا يوجد ترتيب نهائي بعد.';

  @override
  String get wins => 'انتصارات';

  @override
  String get wait => 'انتظر';

  @override
  String get rpsHeaderTitle => 'حجر · ورقة · مقص';

  @override
  String rpsHeaderOnlineSubtitle(Object name) {
    return 'ضد $name · نزال مباشر';
  }

  @override
  String rpsHeaderOfflineSubtitle(Object name) {
    return 'تدريب ضد $name';
  }

  @override
  String get throwLabel => 'الرمية';

  @override
  String get challenger => 'المتحدي';

  @override
  String get host => 'المضيف';

  @override
  String get rpsPaperCoversRockChallengerWins =>
      'الورقة تغطي الحجر · المتحدي يفوز بالرمية';

  @override
  String get rpsPaperCoversRockHostWins =>
      'الورقة تغطي الحجر · المضيف يفوز بالرمية';

  @override
  String get rpsChallengerWinsThrow => 'المتحدي يفوز بالرمية';

  @override
  String get rpsHostWinsThrow => 'المضيف يفوز بالرمية';

  @override
  String couldNotCloseOutMatch(Object message) {
    return 'تعذر إنهاء المباراة: $message';
  }

  @override
  String couldNotSubmitPick(Object message) {
    return 'تعذر إرسال الاختيار: $message';
  }

  @override
  String whoGoal(Object name) {
    return '$name - هدف!';
  }

  @override
  String whoSaved(Object name) {
    return '$name - تصدٍ!';
  }

  @override
  String get penaltyDirFarLeft => 'أقصى اليسار';

  @override
  String get penaltyDirLeft => 'يسار';

  @override
  String get penaltyDirCenter => 'الوسط';

  @override
  String get penaltyDirRight => 'يمين';

  @override
  String get penaltyDirFarRight => 'أقصى اليمين';

  @override
  String get penaltyDragReleaseShoot => 'اسحب أفقيا ثم اترك للتسديد';

  @override
  String get penaltyDragReleaseDive => 'اسحب أفقيا ثم اترك للارتماء';

  @override
  String get penaltyLaneLeft => 'يسار';

  @override
  String get penaltyLaneCenter => 'وسط';

  @override
  String get penaltyLaneRight => 'يمين';

  @override
  String get penaltyLaneFarLeftShort => 'يس';

  @override
  String get penaltyLaneLeftShort => 'ي';

  @override
  String get penaltyLaneCenterShort => 'و';

  @override
  String get penaltyLaneRightShort => 'م';

  @override
  String get penaltyLaneFarRightShort => 'يم';

  @override
  String penaltyRoundProgress(int round, int total) {
    return 'الجولة $round / $total';
  }

  @override
  String get penaltyRoundPicksInProgress => 'جاري تجهيز اختيارات الجولة...';

  @override
  String opponentWins(Object name) {
    return 'فاز $name';
  }

  @override
  String get shootoutWinSubline => 'إنهاء حاسم - شارك اللقطة!';

  @override
  String get shootoutLossSubline => 'خسارة مؤلمة - جولة جزاء أخرى؟';

  @override
  String get shootoutDrawSubline => 'جمود على الخط - الشرف متعادل.';

  @override
  String get shootoutOver => 'انتهت ركلات الجزاء';

  @override
  String youVsOpponentScore(int myGoals, Object opponent, int oppGoals) {
    return 'أنت $myGoals  —  $opponent $oppGoals';
  }

  @override
  String get shareToHomeFeed => 'شارك إلى الخلاصة الرئيسية';

  @override
  String penaltyShootoutShareBody(
    Object opponent,
    int myGoals,
    int oppGoals,
    Object winnerLine,
  ) {
    return 'ركلات جزاء ضد $opponent\nالنتيجة النهائية: $myGoals — $oppGoals\n$winnerLine';
  }

  @override
  String get shareResult => 'مشاركة النتيجة';

  @override
  String get goalLanes => 'ممرات المرمى';

  @override
  String get goalLanesClassicTooltip => 'يسار · وسط · يمين';

  @override
  String get goalLanesWideTooltip => 'من أقصى اليسار إلى أقصى اليمين';

  @override
  String get savingPickToServer => 'جارٍ حفظ اختيارك على الخادم...';

  @override
  String pickSavedWaitingFor(Object name) {
    return 'تم حفظ الاختيار - بانتظار $name...';
  }

  @override
  String shotDiveSummary(Object shot, Object dive) {
    return 'التسديدة $shot · الارتماء $dive';
  }

  @override
  String get onlineGamePenaltyShootout => 'ركلات الجزاء';

  @override
  String get onlineGameRockPaperScissors => 'حجر ورقة مقص';

  @override
  String get onlineGameFantasyCards => 'بطاقات الخيال';

  @override
  String get onlineGameReactionRelay => 'سباق رد الفعل';

  @override
  String get onlineGameFlashMatch => 'مباراة الوميض';

  @override
  String onlineGameFallback(Object gameId) {
    return 'اللعبة #$gameId';
  }

  @override
  String get onlinePartyGameTwoToFive =>
      'لعبة جماعية - من 2 إلى 5 لاعبين على جهاز واحد';

  @override
  String get onlinePartyGameRoundsGetHarder =>
      'لعبة جماعية - الجولات تصبح أصعب (وميض، شبكة، جزاءات)';

  @override
  String get aiLabel => 'الذكاء الاصطناعي';

  @override
  String matchVsOpponent(Object name) {
    return 'مباراة ضد $name';
  }

  @override
  String noScreenForGameIdYet(Object gameId) {
    return 'لا توجد شاشة للعبة ذات المعرّف $gameId بعد.';
  }

  @override
  String get posts => 'المنشورات';

  @override
  String get challenges => 'التحديات';

  @override
  String get couldNotFindPostInFeed =>
      'تعذر العثور على هذا المنشور في الخلاصة.';

  @override
  String get feedTipPullToRefresh => 'اسحب لأسفل في القائمة لتحديث المنشورات.';

  @override
  String get feedTipTapName =>
      'اضغط على اسم أي شخص لإضافته أو لإرسال تحدي لعبة.';

  @override
  String get feedTipExplorePeople =>
      'استخدم استكشاف الأشخاص ضمن ابدأ الآن للبحث عن اللاعبين باسم المستخدم.';

  @override
  String get feedTipTopLiked => 'بدّل إلى الأعلى إعجابًا لرؤية ما هو رائج.';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String get tapForFeedTip => 'اضغط للحصول على نصيحة للخلاصة - مركز مجتمعك';

  @override
  String get backToTop => 'العودة للأعلى';

  @override
  String get jumpIn => 'ابدأ الآن';

  @override
  String get quickNewPostTooltip => 'منشور جديد - شارك تحديثًا';

  @override
  String get quickOnlineTooltip => 'اللعب أونلاين - تحديات ومواجهات';

  @override
  String get quickAlertsTooltip => 'التنبيهات - ردود ودعوات';

  @override
  String get quickBattlesTooltip => 'المعارك - فعاليات الفريق';

  @override
  String get quickProfileTooltip => 'الملف الشخصي - أنت وأصدقاؤك';

  @override
  String get quickPeopleTooltip => 'استكشاف الأشخاص - بحث وطلبات صداقة';

  @override
  String get alerts => 'التنبيهات';

  @override
  String get battles => 'المعارك';

  @override
  String get people => 'الأشخاص';

  @override
  String get latest => 'الأحدث';

  @override
  String get topLiked => 'الأعلى إعجابًا';

  @override
  String get all => 'الكل';

  @override
  String get announce => 'إعلان';

  @override
  String get celebrate => 'احتفال';

  @override
  String get teamBattleCosmicDiceTitle => 'نرد كوني';

  @override
  String get teamBattleCosmicDiceSubtitle =>
      'رمية واحدة (1-999) لكل يوم UTC - الأعلى يفوز.';

  @override
  String get teamBattleReflexTitle => 'ردة فعل الضوء الأخضر';

  @override
  String get teamBattleReflexSubtitle =>
      'انتظر الضوء الأخضر ثم اضغط - الأسرع رد فعلًا يتصدر.';

  @override
  String get teamBattleOracleTitle => 'رقم العرّاف';

  @override
  String get teamBattleOracleSubtitle =>
      'اختر رقمًا من 0 إلى 9. هاش يومي يحدد الرقم الفائز.';

  @override
  String get teamBattleBlitzTitle => 'اندفاع 5 ثوانٍ';

  @override
  String get teamBattleBlitzSubtitle =>
      'كم ضغطة خلال 5 ثوانٍ؟ أفضل نتيجة اليوم تبقى في اللوحة.';

  @override
  String get teamBattleHighLowTitle => 'نبوءة عالي-منخفض';

  @override
  String get teamBattleHighLowSubtitle =>
      'التطبيق يولد رقمًا من 0 إلى 99 مرة يوميًا (UTC). اختر منخفض (0-49) أو مرتفع (50-99).';

  @override
  String teamPicked(Object value) {
    return 'اختار $value';
  }

  @override
  String get teamEntered => 'تم الإدخال';

  @override
  String teamYourRoll(Object value) {
    return 'رميتك: $value';
  }

  @override
  String teamYourBestMs(Object value) {
    return 'أفضل نتيجة لك: $value مللي ثانية';
  }

  @override
  String get teamSubmitted => 'تم الإرسال';

  @override
  String get teamSubmittedToday => 'تم الإرسال لليوم.';

  @override
  String teamYouPickedFair(Object value) {
    return 'اخترت $value. الرقم الفائز لا يظهر هنا (لضمان العدالة).';
  }

  @override
  String teamYourBestTaps(Object value) {
    return 'أفضل نتيجة لك: $value ضغطة';
  }

  @override
  String teamYouChoseFair(Object value) {
    return 'اخترت $value. الرقم المخفي لا يظهر هنا (لضمان العدالة).';
  }

  @override
  String teamRolledSubmit(Object value) {
    return 'حصلت على $value. إرسال لليوم؟';
  }

  @override
  String get submit => 'إرسال';

  @override
  String teamLockedIn(Object roll, Object period) {
    return 'تم التثبيت: $roll لليوم $period (UTC).';
  }

  @override
  String teamSavedMs(Object value) {
    return 'تم الحفظ: $value مللي ثانية';
  }

  @override
  String teamScoreMs(Object value) {
    return '$value مللي ثانية';
  }

  @override
  String get teamLockPick => 'تثبيت الاختيار';

  @override
  String get teamOracleSavedFair =>
      'تم حفظ الاختيار. رقم العرّاف يبقى مخفيًا هنا لضمان العدالة.';

  @override
  String teamTapsSaved(Object value) {
    return 'تم حفظ $value ضغطة.';
  }

  @override
  String teamScoreTaps(Object value) {
    return '$value ضغطة';
  }

  @override
  String get teamHighLowQuestion =>
      'هل سيكون رقم اليوم المخفي منخفضًا (0-49) أم مرتفعًا (50-99)؟';

  @override
  String get teamLowRange => 'منخفض (0-49)';

  @override
  String get teamHighRange => 'مرتفع (50-99)';

  @override
  String get teamHighLowSavedFair =>
      'تم حفظ الاختيار. الرقم اليومي يبقى مخفيًا هنا لضمان العدالة.';

  @override
  String get play => 'لعب';

  @override
  String get teamBeatRecord => 'اكسر الرقم';

  @override
  String get teamDoneToday => 'تم اليوم';

  @override
  String get teamBattles => 'معارك الفريق';

  @override
  String get teamSignInHint => 'سجّل الدخول للانضمام إلى معارك اليوم العالمية.';

  @override
  String get globalBattles => 'المعارك العالمية';

  @override
  String teamUtcDayBoards(Object period) {
    return 'يوم UTC $period - جميع المستخدمين يشاركون نفس اللوحات.';
  }

  @override
  String get teamYesterdaysChampions => 'أبطال الأمس';

  @override
  String teamChampionsSubtitle(Object period) {
    return 'يوم UTC $period - أعلى نتيجة لكل معركة. يصل إشعار يوميًا الساعة 12:00 ظهرًا على هذا الجهاز.';
  }

  @override
  String get teamNoChampion => '-';

  @override
  String get teamTopPlayers => 'أفضل اللاعبين';

  @override
  String get teamNoScoresYet => 'لا توجد نتائج بعد - كن الأول.';

  @override
  String get teamWaitForGreenHint =>
      'انتظر اللون الأخضر. الضغط المبكر يعيد الجولة.';

  @override
  String get teamGreenTapNow => 'أخضر! اضغط الآن.';

  @override
  String get teamTooEarlyWaitGreen => 'مبكر جدًا! انتظر اللون الأخضر.';

  @override
  String get teamTapNow => 'اضغط!';

  @override
  String get teamWaitEllipsis => 'انتظر...';

  @override
  String get abort => 'إيقاف';

  @override
  String teamSecondsLeftTapAnywhere(Object seconds) {
    return 'متبقي $seconds ث - اضغط في أي مكان';
  }

  @override
  String get team => 'الفريق';

  @override
  String get teamEmptyIntro =>
      'كوّن فريقًا من ستة لاعبين بتشكيل 2-2-2 القياسي ودرّب الإحصاءات. بعد إنشاء الفريق، تحدَّ أصدقاءك من هذا التبويب أو من أونلاين.';

  @override
  String get teamNoSquadYet => 'لا يوجد فريق بعد';

  @override
  String get teamNoSquadDescription =>
      'ستة لاعبين فقط بنفس التخطيط للجميع - اضغط على أي لاعب لاحقًا لتعديل الاسم والصورة، ثم درّب الإحصاءات بنقاط المهارة.';

  @override
  String get teamCreateTeam => 'إنشاء فريق';

  @override
  String get teamBestLineupInApp => 'أفضل تشكيلة في التطبيق';

  @override
  String teamBestLineupSubtitle(Object monday) {
    return 'أعلى نتيجة قوة هذا الأسبوع بنظام UTC ($monday). نفس قواعد سباقات التشكيلة - درّب، أرسل، وتقدّم.';
  }

  @override
  String get teamNoSubmissionsYet =>
      'لا توجد مشاركات بعد - كن الأول في اللوحة.';

  @override
  String teamRankPowerRace(Object name) {
    return '$name - المركز #1 - سباق القوة';
  }

  @override
  String get teamPlayTogether => 'العبوا معًا';

  @override
  String get teamSameFriendsListHint =>
      'نفس قائمة الأصدقاء في الصفحة الرئيسية - تحدَّ أحدهم وسيصله التحدي في أونلاين.';

  @override
  String get teamRefreshFriends => 'تحديث الأصدقاء';

  @override
  String get teamNoFriendsHint =>
      'لا يوجد أصدقاء بعد - أرسل طلبات من الصفحة الرئيسية. عند قبول أحدهم، اضغط تحديث هنا أو افتح أونلاين.';

  @override
  String get challenge => 'تحدي';

  @override
  String get teamSquadPulse => 'نبض الفريق';

  @override
  String get teamSquadPulseSubtitle =>
      'معاينة مباشرة لثلاثة أوضاع السباق الأسبوعية - درّب ثم ارتقِ في لوحة الصدارة المشتركة.';

  @override
  String get teamPowerRace => 'سباق القوة';

  @override
  String get teamSpeedDash => 'اندفاع السرعة';

  @override
  String get teamBalance => 'التوازن';

  @override
  String get teamRaceSubtitlePower =>
      'مجموع ATK+DEF+SPD+STM لجميع اللاعبين الستة.';

  @override
  String get teamRaceSubtitleSpeed => 'لكل لاعب: 2×SPD + STM.';

  @override
  String get teamRaceSubtitleBalance =>
      'يكافئ أعلى حد أدنى للإحصاءات لكل لاعب (×15).';

  @override
  String lineupScored(Object score) {
    return 'تم احتساب التشكيلة: $score نقطة';
  }

  @override
  String get lineupRaces => 'سباقات التشكيلة';

  @override
  String get refreshBoard => 'تحديث اللوحة';

  @override
  String teamRaceWeekUtc(Object mondayId) {
    return 'الأسبوع (UTC): $mondayId · الجميع يستخدم نفس التشكيلة الستية المحفوظة من السحابة.';
  }

  @override
  String get submitLineupToRace => 'إرسال التشكيلة لهذا السباق';

  @override
  String get createTeamToEnter => 'أنشئ فريقًا للمشاركة';

  @override
  String get leaderboard => 'لوحة الصدارة';

  @override
  String get teamNoEntriesYetBeFirstThisWeek =>
      'لا توجد مشاركات بعد - كن الأول هذا الأسبوع.';

  @override
  String get yourSquad => 'فريقك';

  @override
  String teamSkillPointsLabel(Object points) {
    return '$points نقطة';
  }

  @override
  String get teamRenameTeam => 'إعادة تسمية الفريق';

  @override
  String get teamName => 'اسم الفريق';

  @override
  String teamStatPlusOne(Object label) {
    return '$label +1';
  }

  @override
  String teamSkillTrainingTitle(Object cost) {
    return 'تدريب المهارة ($cost نقطة → +1)';
  }

  @override
  String teamPlayerTrainingBalance(Object slot, Object name, Object points) {
    return 'اللاعب $slot: $name · رصيدك: $points نقطة';
  }

  @override
  String get teamEarnMoreFromDailyChallenges =>
      'اكسب المزيد من التحديات اليومية أعلاه.';

  @override
  String teamPlayerIndexOf(Object index, Object total) {
    return 'اللاعب $index من $total';
  }

  @override
  String get teamEditPlayer => 'تعديل اللاعب';

  @override
  String get teamPhoto => 'الصورة';

  @override
  String get choose => 'اختيار';

  @override
  String get teamDisplayName => 'اسم العرض';

  @override
  String get teamStatsSkillTrainingOnly => 'الإحصاءات (تدريب المهارة فقط)';

  @override
  String get teamRaiseStatsHint =>
      'ارفع ATK و DEF و SPD و STM من قسم التدريب أعلاه.';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get tapToEdit => 'اضغط للتعديل';

  @override
  String get teamDefenseShort => 'DEF';

  @override
  String get teamAttackShort => 'ATK';

  @override
  String get teamChallengePitchReportTitle => 'تقرير الملعب اليومي';

  @override
  String get teamChallengePitchReportSubtitle =>
      'نفس التحدي لكل اللاعبين - يُطالب به مرة يوميًا بنظام UTC.';

  @override
  String get teamChallengeCrowdEnergyTitle => 'طاقة الجمهور';

  @override
  String get teamChallengeCrowdEnergySubtitle =>
      'انشر أي منشور في الصفحة الرئيسية اليوم (UTC).';

  @override
  String get teamChallengeMatchRhythmTitle => 'إيقاع يوم المباراة';

  @override
  String get teamChallengeMatchRhythmSubtitle =>
      'العب أونلاين اليوم (UTC). ملاحظة: نسجل المشاركة عند إغلاق المباراة في السحابة؛ وتُحتسب مباريات rim / fantasy / 1v1 من سجلات الجلسات المباشرة.';

  @override
  String get teamDailyChallengesEveryone => 'التحديات اليومية (للجميع)';

  @override
  String get teamDailyChallengesHint =>
      'اكسب نقاط المهارة ثم درّب اللاعبين (+1 لكل إحصاء مقابل 15 نقطة). يجب حفظ الفريق في السحابة.';

  @override
  String get claimed => 'تم المطالبة';

  @override
  String get claim => 'مطالبة';

  @override
  String teamBattleStatDelta(
    Object slot,
    Object stat,
    Object arrow,
    Object before,
    Object after,
  ) {
    return 'اللاعب $slot: $stat $arrow $before -> $after';
  }

  @override
  String get teamBattleAcademyDialogBody =>
      'مباراة فردية سريعة ضد فريق احتياطي متغير. نفس مجموع القوة مثل سباقات التشكيلة.\n\n- فوز: +18 نقطة مهارة - تعادل: +12 - خسارة: ما زالت +8\n- بدون تغييرات إحصائية - مجرد إحماء يومي ممتع\n- مرة واحدة يوميًا بنظام UTC\n\nبدء المباراة؟';

  @override
  String get teamBattleNotNow => 'ليس الآن';

  @override
  String get teamBattleKickOff => 'ابدأ';

  @override
  String get teamBattleAcademyFriendly => 'مباراة الأكاديمية';

  @override
  String get teamBattleThisFriend => 'هذا الصديق';

  @override
  String get teamBattleSquadSpar => 'نزال الفريق';

  @override
  String teamBattleSquadSparDialogBody(Object name) {
    return 'يتم احتساب الفريقين بنفس معادلة القوة في سباقات التشكيلة (مجموع ATK+DEF+SPD+STM لكل لاعب).\n\n- فوز: +20 نقطة مهارة و +1 إحصاء عشوائي (حد أقصى 99)\n- تعادل: +8 نقاط مهارة لكل طرف - بدون تغيير إحصائي\n- خسارة: -1 إحصاء عشوائي (حد أدنى 40)\n\nنزال واحد لكل زوج أصدقاء في اليوم بنظام UTC. مخاطرة أعلى وحماس أكبر.\n\nتحدي $name؟';
  }

  @override
  String get battle => 'قتال';

  @override
  String teamBattleVictory(Object myScore, Object oppScore, Object points) {
    return 'فوز $myScore-$oppScore! +$points نقاط مهارة';
  }

  @override
  String teamBattleDefeat(Object myScore, Object oppScore) {
    return 'خسارة $myScore-$oppScore. عد أقوى غدًا.';
  }

  @override
  String teamBattleDraw(Object myScore, Object oppScore, Object points) {
    return 'تعادل $myScore-$oppScore - +$points نقاط مهارة لكل طرف';
  }

  @override
  String teamBattleSparSettled(Object balance) {
    return 'تم حسم النزال - الرصيد $balance';
  }

  @override
  String get teamBattleBattlesForSkillPoints => 'معارك لنقاط المهارة';

  @override
  String get teamBattleHeaderSubtitle =>
      'مباراة الأكاديمية لمواجهة يومية هادئة، ونزال الأصدقاء للمخاطرة العالية، ومواجهات أونلاين للحماس الكامل.';

  @override
  String get teamBattleChipWin => 'فوز: نقاط + تعزيز';

  @override
  String get teamBattleChipTie => 'تعادل: نقاط آمنة';

  @override
  String get teamBattleChipLoss => 'خسارة: ضربة إحصائية';

  @override
  String get teamBattleAcademySubtitle =>
      'مباراة فردية ضد فريق احتياطي باسم محدد. النتائج ترتفع مباشرًا - بدون خطر على التشكيلة، وتكسب دائمًا نقاط مهارة.';

  @override
  String get teamBattleChipNoStatRisk => 'بدون خطر إحصائي';

  @override
  String get teamBattleChipDailyOnce => 'مرة يوميًا';

  @override
  String get teamBattleChipAlwaysPts => 'دائمًا +نقاط';

  @override
  String get teamBattleKickOffAcademy => 'ابدأ ضد أكاديمية XI';

  @override
  String get teamBattleTapAnimatedScoreboard =>
      'اضغط لعرض لوحة النتائج المتحركة';

  @override
  String get teamBattleSquadSparFriends => 'نزال الفريق (الأصدقاء)';

  @override
  String get teamBattleAddFriendsHint =>
      'أضف أصدقاء من الصفحة الرئيسية ثم حدّث. تحتاج فريقًا محفوظًا وصديقًا مقبولًا لديه فريق محفوظ.';

  @override
  String get teamBattleLiveDuels => 'مواجهات مباشرة (تبويب أونلاين)';

  @override
  String get teamBattleLiveDuelsSubtitle =>
      'ركلات الجزاء وحجر-ورقة-مقص وبطاقات الخيال - مباريات مباشرة بين طرفين. تغيرات إحصاءات التشكيلة العشوائية تطبق في نزال الأصدقاء أعلاه؛ والألعاب المباشرة تغذي مطالبة \"إيقاع يوم المباراة\" اليومية.';

  @override
  String get teamBattleOutcomeWin => 'فوز - قوتك تفوقت عليهم!';

  @override
  String get teamBattleOutcomeLose =>
      'خسارة ضيقة - الفريق الاحتياطي كان أفضل اليوم.';

  @override
  String get teamBattleOutcomeTie => 'تعادل تام - تقاسم النتيجة.';

  @override
  String get teamBattleOutcomeComplete => 'اكتملت المباراة';

  @override
  String teamBattleYouVs(Object opponent) {
    return 'أنت ضد $opponent';
  }

  @override
  String get teamBattleYourSquad => 'فريقك';

  @override
  String get teamBattleTheirPower => 'قوتهم';

  @override
  String teamBattlePointsBalance(Object points, Object balance) {
    return '+$points نقاط مهارة - الرصيد $balance';
  }

  @override
  String get nice => 'رائع';
}
