import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/base/base_page.dart';
import 'package:mine_storage/features/products/detail/widgets/lot_sheet.dart';
import 'package:mine_storage/features/products/scan/states/scan_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';

/// The scanner, against a placeholder surface.
///
/// No camera and no barcode plugin ship in this version, so the viewfinder is
/// drawn and decoding is triggered by hand. Everything downstream — the hit and
/// miss branches, the manual fallback, the permission surface — is real, so
/// swapping a decoder in later touches only [_Viewfinder].
class ScanPage extends BasePage {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends BasePageState<ScanPage, ScanState, ScanStateNotifier> {
  final _manual = TextEditingController();

  @override
  void initState() {
    allowToShowLoading = false;
    super.initState();
  }

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  @override
  void setCurrentState() => currentState = ref.watch(scanStateProvider);

  @override
  void setNotifier() => notifier = ref.read(scanStateProvider.notifier);

  Future<void> _openProduct() async {
    final product = currentState.product;
    if (product == null) return;
    await LotSheet.show(context, product: product);
    if (mounted) notifier.reset();
  }

  void _createProduct() {
    final barcode = currentState.barcode;
    if (barcode == null) return;
    context.pushReplacementNamed(
      AppRoutes.productNewName,
      queryParameters: {'barcode': barcode},
    );
  }

  @override
  Widget buildPageContent(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.neutral1,
      appBar: AppBar(title: Text(LocaleKeys.products_scanTitle.tr())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (currentState.permissionDenied)
              _Notice(text: LocaleKeys.products_cameraDenied.tr())
            else
              const _Viewfinder(),
            const SizedBox(height: 16),
            if (!currentState.permissionDenied)
              Center(
                child: Text(
                  LocaleKeys.products_scanHint.tr(),
                  style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
                ),
              ),
            const SizedBox(height: 20),
            // Stands in for the decoder until a real one ships.
            OutlinedButton(
              key: const Key('scan-simulate-button'),
              onPressed: () => notifier.decoded('5012345678900'),
              child: Text(LocaleKeys.products_simulateScan.tr()),
            ),
            const SizedBox(height: 24),
            Text(
              LocaleKeys.products_enterManually.tr(),
              style: context.textStyles.sansBodyBold,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('scan-manual-field'),
              controller: _manual,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              onSubmitted: notifier.decoded,
              decoration: InputDecoration(
                hintText: LocaleKeys.products_manualBarcode.tr(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => notifier.decoded(_manual.text),
                ),
              ),
            ),
            if (currentState.outcome != ScanOutcome.none) ...[
              const SizedBox(height: 24),
              _Outcome(
                state: currentState,
                onOpen: _openProduct,
                onCreate: _createProduct,
                onRescan: () {
                  _manual.clear();
                  notifier.reset();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.neutral2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.neutral3),
        ),
        child: const Center(child: ScanSweep(active: true)),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      key: const Key('scan-permission-notice'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.orange0,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.videocam_off_outlined, size: 20, color: colors.orange6),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.sansCaption.copyWith(color: colors.orange6),
            ),
          ),
        ],
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.state,
    required this.onOpen,
    required this.onCreate,
    required this.onRescan,
  });

  final ScanState state;
  final VoidCallback onOpen;
  final VoidCallback onCreate;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hit = state.outcome == ScanOutcome.hit;

    return Container(
      key: Key(hit ? 'scan-hit' : 'scan-miss'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.neutral0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.neutral3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (hit ? LocaleKeys.products_scanHitTitle : LocaleKeys.products_scanMissTitle).tr(),
            style: context.textStyles.sansBodyBold,
          ),
          const SizedBox(height: 6),
          Text(
            hit
                ? LocaleKeys.products_scanHitBody.tr(
                    namedArgs: {'name': state.product?.name ?? ''},
                  )
                : LocaleKeys.products_scanMissBody.tr(),
            style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('scan-primary-action'),
                  onPressed: hit ? onOpen : onCreate,
                  child: Text(
                    (hit ? LocaleKeys.products_addLot : LocaleKeys.products_createProduct).tr(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRescan,
                  child: Text(LocaleKeys.products_scanTitle.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
