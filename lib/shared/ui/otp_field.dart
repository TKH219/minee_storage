import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mine_storage/app/theme/theme.dart';

/// Both projects report `mailer_otp_length = 8`; a shorter field silently
/// truncates and every verification fails.
///
/// The eight boxes are decoration over a single offstage [TextField], so the
/// platform keyboard, paste and autofill all behave normally.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.hasError = false,
  });

  static const int codeLength = 8;

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool hasError;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() {});
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < OtpField.codeLength; i++) ...[
                if (i > 0) const SizedBox(width: 7),
                Expanded(child: _box(context, i, code)),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: OtpField.codeLength,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _handleChanged,
                onSubmitted: widget.onSubmitted,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(BuildContext context, int index, String code) {
    final colors = context.colors;
    final filled = index < code.length;
    final isCaret = index == code.length && _focusNode.hasFocus;

    final (Color border, Color background) = switch ((widget.hasError, filled, isCaret)) {
      (true, _, _) => (colors.red5, colors.red0),
      (_, true, _) => (colors.primary2, colors.primary0),
      (_, _, true) => (colors.primary4, colors.neutral0),
      _ => (colors.neutral3, colors.neutral0),
    };

    return SizedBox(
      key: Key('otp-box-$index'),
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Center(
          child: Text(
            filled ? code[index] : '',
            style: context.textStyles.monoBody.copyWith(
              fontSize: 20,
              color: colors.neutral9,
            ),
          ),
        ),
      ),
    );
  }
}
