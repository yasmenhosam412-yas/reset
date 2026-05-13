import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:new_project/features/authentication/data/models/user_model.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_bloc.dart';
import 'package:new_project/features/main_screen/tabs/home_tab/presentation/controller/bloc/home_event.dart';
import 'package:new_project/l10n/app_localizations.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_bloc.dart';
import 'package:new_project/features/main_screen/tabs/online_tab/presentation/pages/bloc/online_event.dart';

/// Stable keys stored in [user_reports.reason] for staff review.
const List<String> kReportUserReasonKeys = [
  'harassment',
  'spam',
  'hate',
  'sexual',
  'violence',
  'impersonation',
  'scam',
  'other',
];

String reportUserReasonLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'harassment':
      return l10n.reportReasonHarassment;
    case 'spam':
      return l10n.reportReasonSpam;
    case 'hate':
      return l10n.reportReasonHate;
    case 'sexual':
      return l10n.reportReasonSexual;
    case 'violence':
      return l10n.reportReasonViolence;
    case 'impersonation':
      return l10n.reportReasonImpersonation;
    case 'scam':
      return l10n.reportReasonScam;
    case 'other':
      return l10n.reportReasonOther;
    default:
      return key;
  }
}

void showHomeBlockUserDialog(BuildContext context, UserModel user) {
  final id = user.id.trim();
  if (id.isEmpty) return;
  final scheme = Theme.of(context).colorScheme;
  final name = user.username.trim().isEmpty ? context.l10n.player : user.username.trim();
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(context.l10n.blockUserTitle(name)),
        content: Text(context.l10n.blockUserMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<HomeBloc>().add(HomeUserBlockRequested(blockedUserId: id));
              context.read<OnlineBloc>().add(OnlineLoadRequested());
            },
            child: Text(context.l10n.blockUser),
          ),
        ],
      );
    },
  );
}

void showHomeReportUserDialog(
  BuildContext context,
  UserModel user, {
  Map<String, dynamic>? contextPayload,
}) {
  final id = user.id.trim();
  if (id.isEmpty) return;
  final name = user.username.trim().isEmpty ? context.l10n.player : user.username.trim();
  final detailsCtrl = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      String? selectedReason;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final l10n = context.l10n;
          final scheme = Theme.of(context).colorScheme;
          final isOther = selectedReason == 'other';
          return AlertDialog(
            title: Text(l10n.reportUserTitle(name)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.reportUserDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.reportUserReasonPrompt,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  for (final key in kReportUserReasonKeys)
                    ListTile(
                      selected: selectedReason == key,
                      selectedTileColor:
                          scheme.primaryContainer.withValues(alpha: 0.35),
                      leading: Icon(
                        selectedReason == key
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selectedReason == key
                            ? scheme.primary
                            : scheme.outline,
                      ),
                      title: Text(
                        reportUserReasonLabel(l10n, key),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onTap: () => setDialogState(() => selectedReason = key),
                    ),
                  if (isOther) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: detailsCtrl,
                      maxLines: 4,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.reportUserOtherDetailsHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: selectedReason == null
                    ? null
                    : () {
                        final reason = selectedReason!;
                        final extra =
                            reason == 'other' ? detailsCtrl.text.trim() : '';
                        Navigator.of(dialogContext).pop();
                        final mergedContext = <String, dynamic>{
                          if (contextPayload != null) ...contextPayload,
                          'reason_key': reason,
                        };
                        context.read<HomeBloc>().add(
                              HomeUserReportRequested(
                                reportedUserId: id,
                                reason: reason,
                                details: extra.isEmpty ? null : extra,
                                context: mergedContext,
                              ),
                            );
                      },
                child: Text(l10n.send),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(detailsCtrl.dispose);
}
