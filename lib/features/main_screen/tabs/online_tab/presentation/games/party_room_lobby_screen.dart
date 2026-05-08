import 'dart:async';

import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/party_icon_snap_game.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/party_reaction_relay_game.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/games/party_room_service.dart';

class PartyRoomLobbyScreen extends StatefulWidget {
  const PartyRoomLobbyScreen({
    super.key,
    required this.roomId,
    required this.gameId,
    required this.gameTitle,
  });

  final String roomId;
  final int gameId;
  final String gameTitle;

  @override
  State<PartyRoomLobbyScreen> createState() => _PartyRoomLobbyScreenState();
}

class _PartyRoomLobbyScreenState extends State<PartyRoomLobbyScreen> {
  PartyRoomPresence? _presence;
  String? _error;
  Timer? _poll;
  bool _loading = true;
  bool _hasPresenceSnapshot = false;
  Map<String, String> _lastMemberNamesById = const {};

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    final rid = widget.roomId.trim();
    if (rid.isNotEmpty) {
      unawaited(PartyRoomService.leavePartyRoomUi(roomId: rid));
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final p = await PartyRoomService.fetchRoomPresence(widget.roomId);
      if (!mounted) return;
      final nextNames = <String, String>{};
      for (final m in p.members) {
        final id = m.id.trim();
        if (id.isEmpty) continue;
        final name = m.username.trim().isEmpty
            ? context.l10n.aPlayer
            : m.username.trim();
        nextNames[id] = name;
      }

      if (_hasPresenceSnapshot) {
        final prevIds = _lastMemberNamesById.keys.toSet();
        final nextIds = nextNames.keys.toSet();
        final leftIds = prevIds.difference(nextIds);
        if (leftIds.isNotEmpty) {
          final leftNames = leftIds
              .map((id) => _lastMemberNamesById[id] ?? context.l10n.aPlayer)
              .toList(growable: false);
          final text = leftNames.length == 1
              ? context.l10n.playerLeftGameRoom(leftNames.first)
              : context.l10n.playersLeftGameRoom(leftNames.length);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
        }
      }

      setState(() {
        _presence = p;
        _error = null;
        _loading = false;
        _hasPresenceSnapshot = true;
        _lastMemberNamesById = Map<String, String>.unmodifiable(nextNames);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  BoxDecoration _playfieldShell(ColorScheme scheme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.surfaceContainerHighest,
          scheme.surfaceContainerHigh.withValues(alpha: 0.92),
        ],
      ),
      border: Border.all(color: scheme.primary.withValues(alpha: 0.45), width: 2),
      boxShadow: [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.1),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  void _startGame(BuildContext context) {
    final l10n = context.l10n;
    Widget game;
    switch (widget.gameId) {
      case 4:
        game = PartyReactionRelayGame(roomId: widget.roomId);
        break;
      case 5:
        game = PartyIconSnapGame(roomId: widget.roomId);
        break;
      default:
        game = Center(child: Text(l10n.unsupportedRoomGame));
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(widget.gameTitle)),
          body: game,
        ),
      ),
    );
  }

  Widget _hudChip(ThemeData theme, ColorScheme scheme, IconData icon, String label, {Color? tint}) {
    final c = tint ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotTile({
    required BuildContext context,
    required ThemeData theme,
    required ColorScheme scheme,
    required int index,
    UserModel? member,
  }) {
    final filled = member != null;
    final l10n = context.l10n;
    final name = member == null
        ? l10n.openSlot
        : (member.username.trim().isEmpty ? l10n.player : member.username.trim());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: filled ? scheme.primaryContainer.withValues(alpha: 0.35) : scheme.surface.withValues(alpha: 0.4),
        border: Border.all(
          color: filled ? scheme.primary.withValues(alpha: 0.5) : scheme.outline.withValues(alpha: 0.35),
          width: filled ? 2 : 1.2,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: filled ? scheme.primary : scheme.surfaceContainerHighest,
            child: filled
                ? Text(
                    name.characters.first.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : Icon(Icons.person_outline_rounded, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.slotNumber(index + 1),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: filled ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
                if (!filled)
                  Text(
                    l10n.waitingForInvite,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          if (filled)
            Icon(Icons.check_circle_rounded, color: scheme.tertiary, size: 26)
          else
            Icon(Icons.hourglass_empty_rounded, color: scheme.outline, size: 22),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = _presence;
    final joined = p?.joinedCount ?? 0;
    final maxPlayers = p?.maxPlayers ?? 0;
    final ready = p != null && maxPlayers > 0 && joined >= maxPlayers;
    final members = p?.members ?? const <UserModel>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.meeting_room_rounded, color: scheme.onPrimary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.readyRoom,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.readyRoomSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: _playfieldShell(scheme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _hudChip(
                      theme,
                      scheme,
                      Icons.groups_rounded,
                      l10n.joinedOutOf(joined, maxPlayers),
                    ),
                    _hudChip(
                      theme,
                      scheme,
                      ready ? Icons.verified_rounded : Icons.radar_rounded,
                      ready ? l10n.fullSquad : l10n.recruiting,
                      tint: ready ? scheme.tertiary : scheme.secondary,
                    ),
                  ],
                ),
                if (_loading) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      color: scheme.primary,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ] else if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline_rounded, color: scheme.error, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onErrorContainer,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.roster,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          if (!_loading && _error == null && maxPlayers > 0)
            for (var i = 0; i < maxPlayers; i++)
              _slotTile(
                context: context,
                theme: theme,
                scheme: scheme,
                index: i,
                member: i < members.length ? members[i] : null,
              ),
          const SizedBox(height: 8),
          Material(
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: ready ? () => _startGame(context) : null,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: ready
                        ? [scheme.primary, scheme.primaryContainer.withValues(alpha: 0.95)]
                        : [scheme.surfaceContainerHighest, scheme.surfaceContainerHigh],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 32,
                        color: ready ? scheme.onPrimary : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ready ? l10n.launchGame : l10n.waitingForPlayers,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                          color: ready ? scheme.onPrimary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
