# Mine Storage

Flutter app built on Riverpod + clean architecture, carried over from the
`popular_sg_mobile` core/base conventions with three deliberate upgrades:
**Retrofit** for API calls, **go_router** for navigation, and **light + dark**
theming.

## Requirements

- FVM with Flutter **3.44.7** (`fvm use 3.44.7`)
- Run every tool through `fvm`: `fvm flutter …`, `fvm dart …`

## Getting started

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run
```

`./clean.sh` does a full clean + regenerate. `./build.sh -e staging -p ios`
switches environment and builds a release.

## Architecture

```
lib/
  app/          theme (light/dark), router, extensions
  core/         base classes, network, exceptions
  data/         models, data sources (Retrofit + secure storage), repositories
  domain/       entities, repository interfaces
  features/     splash, login, home  — one folder per feature
  shared/       reusable widgets and utils
  env/          envied-generated config
  providers.dart  DI graph
```

Dependency direction is one-way: `features → domain ← data`. A feature never
imports a model or an API class; it talks to a repository interface and receives
entities.

### Adding a feature

Copy the `home` slice — it is the reference implementation and exercises every
layer:

1. `data/data_sources/remote/<x>_api.dart` — Retrofit `@RestApi`
2. `data/models/response/<x>/<x>_model.dart` — wire format + `toEntity()`
3. `domain/entities/<x>_entity.dart` — what the UI consumes
4. `domain/repositories/<x>_repository.dart` — the interface
5. `data/repositories/<x>_repository_impl.dart` — the implementation
6. `features/<x>/states/<x>_state.dart` — `BaseState` + `BaseStateNotifier`
7. `features/<x>/pages/<x>_page.dart` — `BasePage` + `BasePageState`
8. Register the providers in `providers.dart` and the route in
   `app/router/app_router.dart`

Then `fvm dart run build_runner build --delete-conflicting-outputs`.

### Networking

Two Dio instances, built in `providers.dart`:

- `publicDioProvider` — anonymous endpoints (login, token refresh)
- `authorizedDioProvider` — adds `AuthInterceptor` and `RefreshTokenInterceptor`

Error handling is centralised in `ErrorInterceptor`, which turns any
`DioException` into a typed `AppException` (`NetworkException`,
`UnauthorizedException`, `BadRequestException`, …). Data sources contain **no**
try/catch; `BaseStateNotifier.onError` unwraps and renders the message.

Real endpoints should return `BaseResponse<T>` (the `{code, message, data}`
envelope). The demo `PostApi` returns a bare list because jsonplaceholder has no
envelope.

### Theming

Semantic tokens are read through extensions:

```dart
context.colors.neutral9
context.textStyles.sansBody
```

`ColorThemeExt` and `TextThemeExt` each have a `.light()` and `.dark()` factory.
To rebrand, edit the ramps in `app/theme/app_colors.dart` — nothing else changes.

Theme mode is tri-state (system/light/dark), persisted in `SharedPreferences` via
`themeModeProvider`, and toggled by `ThemeModeButton`.

## Environments

`lib/env/<staging|production>/.env` hold the per-environment values. `build.sh`
copies the chosen one to the root `.env`, which `envied` compiles into
`lib/env/env.g.dart`. The root `.env` is gitignored.

> Do not put real secrets in the committed env files — inject them in CI instead.

## Testing

```bash
fvm flutter test
fvm flutter analyze
```

## Notes on dependency choices

- **Riverpod is pinned to 2.x.** `BaseStateNotifier extends AutoDisposeNotifier`
  is a v2 API. Providers are declared by hand, so `riverpod_generator` is not a
  dependency — it pins `build`/`source_gen` 2 and would hold back every other
  generator.
- **`riverpod_lint` / `custom_lint` are absent.** The only riverpod_lint line
  compatible with Riverpod 2 pins `analyzer` 7, while the code generators require
  `analyzer` 8+. Re-add both when migrating to Riverpod 3.

## Demo code to delete

The reference slice is scoped to these files — removing them leaves a clean
skeleton:

```
lib/domain/entities/post_entity.dart
lib/domain/repositories/post_repository.dart
lib/data/models/response/post/post_model.dart
lib/data/data_sources/remote/post_api.dart
lib/data/repositories/post_repository_impl.dart
lib/features/home/
test/data/post_repository_impl_test.dart
test/features/home_page_test.dart
```
