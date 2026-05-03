String onlineGameTitle(int gameId) {
  switch (gameId) {
    case 1:
      return 'Penalty shootout';
    case 2:
      return 'Rim shot';
    case 3:
      return 'Fantasy cards';
    default:
      return 'Game #$gameId';
  }
}
