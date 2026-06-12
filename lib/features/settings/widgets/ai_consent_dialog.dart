import 'package:flutter/cupertino.dart';

import '../../../core/app_disclaimers.dart';

Future<bool> showAiAnalysisDisclaimerDialog(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('AI Analysis Disclaimer'),
        content: const Text(AppDisclaimers.aiAnalysisDisclaimerNotice),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<bool> showAiConsentDialog(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('AI Data Usage'),
        content: const Text(AppDisclaimers.aiConsentNotice),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Decline'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('I Agree'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<bool> showRevokeAiConsentDialog(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('Revoke AI Consent?'),
        content: const Text(
          'AI analysis will be disabled until you grant consent again.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<bool> showAiConsentBlockedDialog(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('AI Consent Required'),
        content: const Text(
          'AI analysis is disabled because consent was declined. You can grant consent again in Settings.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
