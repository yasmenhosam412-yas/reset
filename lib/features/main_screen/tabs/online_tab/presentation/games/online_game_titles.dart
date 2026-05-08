import 'package:new_project/l10n/app_localizations.dart';

String onlineGameTitle(int gameId) {
  switch (gameId) {
    case 1:
      return 'Penalty shootout';
    case 2:
      return 'Rock paper scissors';
    case 3:
      return 'Fantasy cards';
    case 4:
      return 'Reaction relay';
    case 5:
      return 'Flash match';
    default:
      return 'Game #$gameId';
  }
}

String onlineGameTitleL10n(AppLocalizations l10n, int gameId) {
  switch (gameId) {
    case 1:
      return l10n.onlineGamePenaltyShootout;
    case 2:
      return l10n.onlineGameRockPaperScissors;
    case 3:
      return l10n.onlineGameFantasyCards;
    case 4:
      return l10n.onlineGameReactionRelay;
    case 5:
      return l10n.onlineGameFlashMatch;
    default:
      return l10n.onlineGameFallback(gameId);
  }
}
