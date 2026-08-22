import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/domain/repositories/media_repository.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/providers.dart';

final profileStateProvider = NotifierProvider<ProfileStateNotifier, ProfileState>(
  ProfileStateNotifier.new,
  isAutoDispose: true,
);

class ProfileState extends BaseState with Equatable {
  const ProfileState({
    this.fullName = '',
    this.avatarUrl,
    this.isUploading = false,
    super.status,
    super.errorMessageKey,
    super.errorMessage,
  });

  final String fullName;
  final String? avatarUrl;
  final bool isUploading;

  bool get canSubmit => fullName.isNotBlank && !isLoading && !isUploading;

  /// Two initials from the name, or one from the email until a name is typed.
  String initialsFor(String email) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return email.isEmpty ? '?' : email[0].toUpperCase();
    }
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  ProfileState copyWith({
    StateLifeCycle? status,
    String? errorMessageKey,
    String? errorMessage,
    String? fullName,
    String? avatarUrl,
    bool? isUploading,
  }) {
    return ProfileState(
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isUploading: isUploading ?? this.isUploading,
      status: status ?? this.status,
      errorMessageKey: errorMessageKey ?? this.errorMessageKey,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    fullName,
    avatarUrl,
    isUploading,
    status,
    errorMessageKey,
    errorMessage,
  ];
}

class ProfileStateNotifier extends BaseStateNotifier<ProfileState> {
  late final AuthRepository _authRepository;
  late final MediaRepository _mediaRepository;

  @override
  ProfileState createInitialState() {
    _authRepository = ref.read(authRepositoryProvider);
    _mediaRepository = ref.read(mediaRepositoryProvider);
    return const ProfileState();
  }

  void updateFullName(String value) =>
      updateState(state.copyWith(fullName: value, status: StateLifeCycle.init));

  /// Uploads immediately so the write in [submit] is a single fast call.
  Future<void> pickedAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    try {
      updateState(state.copyWith(isUploading: true, status: StateLifeCycle.init));
      final url = await _mediaRepository.uploadUserAvatar(
        bytes: bytes,
        fileExtension: fileExtension,
      );
      if (!ref.mounted) return;
      updateState(state.copyWith(avatarUrl: url, isUploading: false));
    } on Object catch (e) {
      if (!ref.mounted) return;
      updateState(state.copyWith(isUploading: false));
      onError(e);
    }
  }

  Future<void> submit() async {
    if (!state.canSubmit) {
      showSnackError(msg: LocaleKeys.onboarding_profile_nameRequired);
      return;
    }

    try {
      showLoading();
      await _authRepository.updateProfile(
        fullName: state.fullName,
        avatarUrl: state.avatarUrl,
      );
      if (!ref.mounted) return;
      showLoaded();
      router()?.goNamed(AppRoutes.createStoreName);
    } on Object catch (e) {
      if (!ref.mounted) return;
      onError(e);
    }
  }
}
