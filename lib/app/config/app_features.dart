/// Compile-time switches for work that is built but not yet released.
class AppFeatures {
  const AppFeatures._();

  /// Social sign-in UI is complete but has no OAuth behind it yet, so the
  /// buttons stay hidden rather than shipping as inert controls.
  static const bool socialSignInEnabled = false;

  /// The products tables and both Edge Functions are live, so the app talks to
  /// them. Flip this back to serve the in-memory stand-in when working offline.
  static const bool fakeProductsEnabled = false;

  /// The ledger tables, RPCs and Edge Function are live, so the sale flow
  /// records through them. Flip this back to serve the in-memory stand-in when
  /// working offline.
  static const bool fakeLedgerEnabled = false;
}
