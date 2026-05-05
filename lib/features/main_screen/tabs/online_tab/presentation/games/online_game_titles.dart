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
