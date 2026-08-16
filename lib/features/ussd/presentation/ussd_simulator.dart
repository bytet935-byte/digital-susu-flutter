import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// USSD Simulator (spec "USSD Simulator"): a numeric, text-based dialog that
/// shows how members without smartphones interact via `*713#` codes.
Future<void> showUssdSimulator(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _UssdDialog(),
  );
}

const Map<String, String> _ussdResponses = <String, String>{
  '*713*1#': 'Your wallet balance is GHS 1,250.00.',
  '*713*2#': 'Your next contribution is GHS 100.00 (Weekend Susu).',
  '*713*3#': 'You have 4 active susu groups.',
};

class _UssdDialog extends StatefulWidget {
  const _UssdDialog();

  @override
  State<_UssdDialog> createState() => _UssdDialogState();
}

class _UssdDialogState extends State<_UssdDialog> {
  final TextEditingController _codeController = TextEditingController();
  String? _response;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _send() {
    final code = _codeController.text.trim().toUpperCase();
    setState(() {
      _response = _ussdResponses[code] ??
          'Invalid code. Try *713*1#, *713*2# or *713*3#.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('USSD Simulator'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Members without smartphones can use *713# codes. '
            'Try one below.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _codeController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: '*713*1#',
              prefixIcon: Icon(Icons.phone_android),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 14),
          if (_response != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _response!,
                style: theme.textTheme.emphasis.copyWith(
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _send, child: const Text('Send')),
      ],
    );
  }
}
