import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Today, as the app sees it.
///
/// Expiry is the whole point of this product, so almost every screen asks what
/// day it is. Reading it from here rather than calling [DateTime.now] directly
/// is what lets a test pin the date — otherwise a golden of an expiry badge
/// changes meaning as the date passes.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);
