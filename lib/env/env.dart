import 'package:envied/envied.dart';

part 'env.g.dart';

/// Values are baked in at build time from the root `.env`, which `build.sh`
/// copies from `lib/env/<environment>/.env`.
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'ENV_NAME')
  static final String envName = _Env.envName;

  @EnviedField(varName: 'API_URL')
  static final String apiUrl = _Env.apiUrl;

  @EnviedField(varName: 'MEDIA_URL')
  static final String mediaUrl = _Env.mediaUrl;

  static bool get isProduction => envName == 'production';
}
