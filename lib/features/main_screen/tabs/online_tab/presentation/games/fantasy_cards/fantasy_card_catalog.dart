import 'dart:math' as math;

/// Card-game suit: each **pitch zone** “calls” one suit this matchday — matching
/// gives [kZoneSuitBonus] on top of shirt number (same rule for both players).
enum FantasyCardSuit {
  /// Wide channels, runners (orange / Blitz).
  blitz,
  /// Playmakers, finishers (violet / Maestro).
  maestro,
  /// Stoppers, fullbacks, keepers (slate / Iron).
  iron,
}

extension FantasyCardSuitX on FantasyCardSuit {
  /// Short label on cards / pitch.
  String get symbol => switch (this) {
        FantasyCardSuit.blitz => 'B',
        FantasyCardSuit.maestro => 'M',
        FantasyCardSuit.iron => 'I',
      };

  String get fullName => switch (this) {
        FantasyCardSuit.blitz => 'Blitz',
        FantasyCardSuit.maestro => 'Maestro',
        FantasyCardSuit.iron => 'Iron',
      };
}

/// Fantasy **sports league** pick — shirt number = matchup power on the pitch.
class FantasyCardDef {
  const FantasyCardDef({
    required this.id,
    required this.name,
    required this.role,
    required this.power,
    required this.emoji,
  });

  final int id;
  final String name;
  /// Short kit role (sport / tactics flavour).
  final String role;
  final int power;
  final String emoji;

  /// Bonus when this card’s suit matches what the **lane** asks for (see [zoneCallsForLanes]).
  static const int kZoneSuitBonus = 2;

  /// Suit is printed on the card — lane “pitch calls” reward playing into them.
  FantasyCardSuit get suit => suitForRole(role);

  static FantasyCardSuit suitForRole(String role) {
    switch (role) {
      case 'LW':
      case 'RW':
      case 'LM':
        return FantasyCardSuit.blitz;
      case 'ST':
      case 'CM':
        return FantasyCardSuit.maestro;
      case 'CB':
      case 'RB':
      case 'CDM':
      case 'GK':
        return FantasyCardSuit.iron;
      default:
        return FantasyCardSuit.maestro;
    }
  }

  /// One suit demand per lane, **same for both players** — derived only from [deckSeed].
  static List<FantasyCardSuit> zoneCallsForLanes(int deckSeed) {
    final r = math.Random(deckSeed ^ 0x51ed7eed);
    final lanes = FantasyCardSuit.values.toList()..shuffle(r);
    return lanes;
  }

  /// Tighter power band (4–8) so lanes stay contested — harder to steamroll.
  static const List<FantasyCardDef> catalog = [
    FantasyCardDef(id: 1, name: 'Alvarez', role: 'ST', power: 8, emoji: '⚽'),
    FantasyCardDef(id: 2, name: 'Okonkwo', role: 'LW', power: 6, emoji: '👟'),
    FantasyCardDef(id: 3, name: 'Silva', role: 'CM', power: 7, emoji: '🎯'),
    FantasyCardDef(id: 4, name: 'Berg', role: 'CB', power: 8, emoji: '🛡️'),
    FantasyCardDef(id: 5, name: 'Mendes', role: 'RB', power: 5, emoji: '▶️'),
    FantasyCardDef(id: 6, name: 'Kovač', role: 'CM', power: 7, emoji: '🧠'),
    FantasyCardDef(id: 7, name: 'Park', role: 'RW', power: 5, emoji: '💨'),
    FantasyCardDef(id: 8, name: 'Diallo', role: 'CDM', power: 6, emoji: '🔷'),
    FantasyCardDef(id: 9, name: 'Ruiz', role: 'GK', power: 4, emoji: '🧤'),
    FantasyCardDef(id: 10, name: 'Hansen', role: 'ST', power: 7, emoji: '⚽'),
    FantasyCardDef(id: 11, name: 'Yamamoto', role: 'LM', power: 4, emoji: '🏃'),
    FantasyCardDef(id: 12, name: 'Costa', role: 'CB', power: 6, emoji: '🛡️'),
  ];

  static FantasyCardDef? byId(int id) {
    for (final c in catalog) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Six players on the sheet; you only **start three** on the pitch (harder cut).
  static List<FantasyCardDef> dealHand(int deckSeed, int salt) {
    final r = math.Random(deckSeed ^ (salt * 0x85ebca6b));
    final idx = List<int>.generate(catalog.length, (i) => i)..shuffle(r);
    return idx.take(6).map((i) => catalog[i]).toList(growable: false);
  }
}
