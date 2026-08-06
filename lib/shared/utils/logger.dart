import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Verbose in debug, warnings and above in release.
final Logger logger = Logger(
  level: kDebugMode ? Level.debug : Level.warning,
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 100,
    printEmojis: true,
  ),
);
