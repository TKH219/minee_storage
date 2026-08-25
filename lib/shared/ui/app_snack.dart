import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

/// Lets anything outside the widget tree — notifiers, the error handler —
/// reach the messenger without a `BuildContext`.
final snackbarKey = GlobalKey<ScaffoldMessengerState>();

void showErrorSnack(String message) {
  final context = snackbarKey.currentContext;
  final snackBar = SnackBar(
    content: Text(
      message,
      style: context?.textStyles.sansBody.copyWith(color: context.colors.white),
    ),
    showCloseIcon: true,
    backgroundColor: context?.colors.red5 ?? Colors.red,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
  );
  snackbarKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(snackBar);
}

void showSuccessSnack(String message) {
  final context = snackbarKey.currentContext;
  _show(
    SnackBar(
      content: Text(
        message,
        style: context?.textStyles.sansBody.copyWith(color: context.colors.white),
      ),
      backgroundColor: context?.colors.green5 ?? Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// A destructive action the user can take back.
///
/// The margin lifts it clear of the shell's nav bar, which floating snack bars
/// would otherwise sit on top of.
void showUndoSnack(
  String message, {
  required String actionLabel,
  required VoidCallback onAction,
}) {
  final context = snackbarKey.currentContext;
  _show(
    SnackBar(
      content: Text(
        message,
        style: context?.textStyles.sansBody.copyWith(color: context.colors.white),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: actionLabel, onPressed: onAction),
    ),
  );
}

void _show(SnackBar snackBar) {
  snackbarKey.currentState
    ?..clearSnackBars()
    ..showSnackBar(snackBar);
}
