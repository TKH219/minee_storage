import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/states/consume_state.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/shared/ui/quantity_format.dart';

/// Taking stock out. The split is shown before it is committed, so the user can
/// see they are drawing 3 from one lot and 2 from another rather than trusting
/// a number that appeared.
class ConsumeSheet extends ConsumerStatefulWidget {
  const ConsumeSheet({super.key, required this.product});

  final ProductEntity product;

  static Future<bool?> show(BuildContext context, {required ProductEntity product}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.neutral0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ConsumeSheet(product: product),
    );
  }

  @override
  ConsumerState<ConsumeSheet> createState() => _ConsumeSheetState();
}

class _ConsumeSheetState extends ConsumerState<ConsumeSheet> {
  final _quantity = TextEditingController();
  bool _succeeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(consumeStateProvider.notifier).open(widget.product);
    });
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    await ref.read(consumeStateProvider.notifier).commit();
    if (!mounted) return;
    if (!ref.read(consumeStateProvider).didCommit) return;
    setState(() => _succeeded = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consumeStateProvider);
    final notifier = ref.read(consumeStateProvider.notifier);
    final colors = context.colors;

    if (_succeeded) {
      return SafeArea(
        child: SizedBox(
          height: 220,
          child: Center(
            key: const Key('consume-success'),
            // SuccessCheck owns the 900ms hold and fires even under reduced
            // motion, so the sheet cannot strand a landed write behind a
            // frozen animation.
            child: SuccessCheck(
              onComplete: () {
                if (mounted) Navigator.of(context).pop(true);
              },
            ),
          ),
        ),
      );
    }

    final batchesById = {for (final b in widget.product.batches) b.id: b};

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.products_consumeTitle.tr(),
                style: context.textStyles.sansTitleHeading3,
              ),
              const SizedBox(height: 4),
              // Shown up front, so the ceiling is known before typing.
              Text(
                '${LocaleKeys.products_remaining.tr()} · ${formatQuantity(state.totalRemaining)}',
                style: context.textStyles.sansCaption.copyWith(color: colors.neutral6),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: LocaleKeys.products_quantityToUse.tr(),
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: notifier.updateQuantity,
                errorText: switch (state) {
                  final s when s.exceedsStock => LocaleKeys.products_notEnoughStock.tr(
                    namedArgs: {'available': formatQuantity(s.totalRemaining)},
                  ),
                  final s when s.fractionRefused =>
                    LocaleKeys.products_quantityAboveZero.tr(),
                  _ => null,
                },
              ),
              if (state.allocations.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  LocaleKeys.products_allocationPreview.tr(),
                  style: context.textStyles.sansBodyBold,
                ),
                const SizedBox(height: 8),
                for (final allocation in state.allocations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            batchesById[allocation.batchId]?.batchCode ??
                                allocation.batchId,
                            style: context.textStyles.sansBody,
                          ),
                        ),
                        Text(
                          formatQuantity(allocation.quantity),
                          style: context.textStyles.monoBody.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (state.drawsFromExpired) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('consume-expired-warning'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.orange0,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 20, color: colors.orange6),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LocaleKeys.products_expiredWarning.tr(),
                          style: context.textStyles.sansCaption.copyWith(
                            color: colors.orange6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('consume-commit-button'),
                  onPressed: state.canCommit ? _commit : null,
                  child: Text(LocaleKeys.products_useButton.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
