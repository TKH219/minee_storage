import 'package:equatable/equatable.dart';

/// How an error reaches the user.
///
/// [inline] still parks the message on the state — the screen renders it
/// itself — it only suppresses the snack.
enum ErrorPresentation { snack, inline, silent }

/// What the app does about one error. Produced by `ErrorPolicy`, executed by
/// `AppErrorHandler`; keeping the decision separate from the side effects is
/// what makes the policy table testable without a widget tree.
class ErrorAction extends Equatable {
  const ErrorAction({
    required this.presentation,
    this.purgesUserState = false,
    this.redirectRouteName,
  });

  const ErrorAction.snack() : this(presentation: ErrorPresentation.snack);

  const ErrorAction.inline() : this(presentation: ErrorPresentation.inline);

  const ErrorAction.silent() : this(presentation: ErrorPresentation.silent);

  final ErrorPresentation presentation;

  final bool purgesUserState;

  /// Route *name*, matching how the app navigates everywhere else.
  final String? redirectRouteName;

  @override
  List<Object?> get props => [presentation, purgesUserState, redirectRouteName];
}
