import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Both projects report `mailer_otp_length = 8`; a shorter field silently
/// truncates and every verification fails.
class OtpField extends StatelessWidget {
  const OtpField({super.key, required this.onChanged, this.onSubmitted});

  static const int codeLength = 8;

  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Verification code',
        hintText: '8-digit code',
        counterText: '',
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      maxLength: codeLength,
      autofocus: true,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
