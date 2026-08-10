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
