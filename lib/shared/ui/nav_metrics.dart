/// Layout constants for the floating navigation bar.
///
/// They live in `shared` rather than in the shell feature because scrollable
/// tab content needs [kNavBarReservedSpace] for its bottom padding, and a
/// `shared` file must never import a feature.
const double kNavBarHeight = 64;

/// Height of the tappable pill behind one tab. Also its corner diameter.
const double kNavBarItemHeight = 52;

const double kNavBarHorizontalInset = 16;

const double kNavBarBottomGap = 12;

/// Gap between the bar's right edge and the Add button.
const double kNavBarButtonGap = 12;

/// Bottom padding a scrollable tab must leave so its last item clears the bar.
const double kNavBarReservedSpace = kNavBarHeight + kNavBarBottomGap * 2;
