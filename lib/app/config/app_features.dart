/// Compile-time switches for work that is built but not yet released.
class AppFeatures {
  const AppFeatures._();

  /// Social sign-in UI is complete but has no OAuth behind it yet, so the
  /// buttons stay hidden rather than shipping as inert controls.
  static const bool socialSignInEnabled = false;
}
