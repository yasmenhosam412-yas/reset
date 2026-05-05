import 'package:flutter/foundation.dart';

/// Coordinates jumps from secondary tabs (e.g. Alerts) to [MainScreen] tabs and
/// optional home-feed focus (scroll + open comments).
class MainShellController extends ChangeNotifier {
  int? _pendingTabIndex;
  String? _pendingPostId;
  bool _pendingOpenComments = false;

  void openHomePost(String postId, {bool openComments = false}) {
    final id = postId.trim();
    if (id.isEmpty) return;
    _pendingTabIndex = 0;
    _pendingPostId = id;
    _pendingOpenComments = openComments;
    notifyListeners();
  }

  void openOnlineTab() {
    _pendingTabIndex = 1;
    _pendingPostId = null;
    _pendingOpenComments = false;
    notifyListeners();
  }

  void openProfileTab() {
    _pendingTabIndex = 4;
    _pendingPostId = null;
    _pendingOpenComments = false;
    notifyListeners();
  }

  /// Switches the bottom navigation to any main tab (0–4).
  void goToMainTab(int index) {
    if (index < 0 || index > 4) return;
    _pendingTabIndex = index;
    _pendingPostId = null;
    _pendingOpenComments = false;
    notifyListeners();
  }

  /// [MainScreen] consumes the tab switch (Alerts → Home, etc.).
  int? takePendingTabIndex() {
    final t = _pendingTabIndex;
    _pendingTabIndex = null;
    return t;
  }

  /// [HomeTab] reads post focus; clear with [clearHomePost] after handling.
  ({String postId, bool openComments})? peekHomePost() {
    final p = _pendingPostId;
    if (p == null || p.isEmpty) return null;
    return (postId: p, openComments: _pendingOpenComments);
  }

  void clearHomePost() {
    _pendingPostId = null;
    _pendingOpenComments = false;
    notifyListeners();
  }
}
