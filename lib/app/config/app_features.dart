/// Compile-time switches for work that is built but not yet released.
class AppFeatures {
  const AppFeatures._();

  /// Social sign-in UI is complete but has no OAuth behind it yet, so the
  /// buttons stay hidden rather than shipping as inert controls.
  static const bool socialSignInEnabled = false;

  /// Products have no tables in Supabase yet, so the repository is served from
  /// memory. Flip this once the schema lands and `ProductRepositoryImpl` has
  /// something to talk to.
  static const bool fakeProductsEnabled = true;
}
