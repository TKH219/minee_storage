import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

class AppOption<T> {
  const AppOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A single-select bottom sheet. Generic so one component serves both the
/// category and currency pickers.
Future<T?> showAppOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<AppOption<T>> options,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: context.colors.neutral0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (sheetContext) => _OptionSheet<T>(
      title: title,
      options: options,
      selected: selected,
    ),
  );
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({required this.title, required this.options, this.selected});

  final String title;
  final List<AppOption<T>> options;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.neutral3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title,
                style: context.textStyles.sansTitleHeading3,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: options.length,
                itemBuilder: (context, index) => _buildRow(context, options[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppOption<T> option) {
    final colors = context.colors;
    final isSelected = option.value == selected;

    return InkWell(
      onTap: () => Navigator.of(context).pop(option.value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (option.icon != null) ...[
              Icon(option.icon, size: 20, color: colors.neutral6),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                option.label,
                style: context.textStyles.sansBody.copyWith(color: colors.neutral9),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 20, color: colors.inkPrimary),
          ],
        ),
      ),
    );
  }
}
