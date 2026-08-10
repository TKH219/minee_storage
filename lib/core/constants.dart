class Constants {
  const Constants._();

  static const networkTimeout = Duration(seconds: 30);
  static const defaultPageSize = 20;
}

/// Layout constants for the floating navigation bar.
///
/// Grouped here rather than in the shell feature because scrollable tab content
/// needs [reservedSpace] for its bottom padding, and `shared` must never import
/// a feature.
class NavBarMetrics {
  const NavBarMetrics._();

  static const double height = 64;

  /// Height of the tappable pill behind one tab. Also its corner diameter.
  static const double itemHeight = 52;

  static const double horizontalInset = 16;

  static const double bottomGap = 12;

  /// Gap between the bar's right edge and the Add button.
  static const double buttonGap = 12;

  /// Bottom padding a scrollable tab must leave so its last item clears the bar.
  static const double reservedSpace = height + bottomGap * 2;
}
