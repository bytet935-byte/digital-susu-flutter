import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/money.dart';
import '../../../groups/domain/group_models.dart';
import '../providers/contribute_providers.dart';

/// Opens the contribute sheet (design reference §9); resolves `true` when a
/// contribution was recorded.
Future<bool?> showContributeSheet(
  BuildContext context, {
  required SusuGroup group,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (context) => ContributeSheet(group: group),
  );
}

/// Contribute flow (spec §9): amount input with GHS 10/20/50/100 presets,
/// payment method (Mobile Money / Card) and a Continue action that records
/// the contribution and updates the group pot.
class ContributeSheet extends ConsumerStatefulWidget {
  const ContributeSheet({super.key, required this.group});

  final SusuGroup group;

  @override
  ConsumerState<ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends ConsumerState<ContributeSheet> {
  static const List<Money> _presets = <Money>[
    Money(1000),
    Money(2000),
    Money(5000),
    Money(10000),
  ];

  final TextEditingController _amountController = TextEditingController();
  Money? _preset;
  String _method = 'MOBILE_MONEY';
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _ghs(Money money) =>
      'GHS ${NumberFormat('#,##0.00').format(money.amountMajor)}';

  Future<void> _submit() async {
    final text = _amountController.text.trim();
    final Money amount;
    if (text.isEmpty && _preset != null) {
      amount = _preset!;
    } else {
      final parsed = double.tryParse(text);
      if (parsed == null || parsed <= 0) {
        setState(() => _error = 'Enter an amount greater than zero');
        return;
      }
      amount = Money((parsed * 100).round());
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await ref
        .read(contributeProvider(widget.group.id).notifier)
        .contribute(
          groupId: widget.group.id,
          amount: amount,
          paymentMethod: _method,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _error = 'Contribution failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Contribute to ${widget.group.name}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text('Pot: ${_ghs(widget.group.pot)}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _presets
                .map(
                  (Money preset) => ChoiceChip(
                    label: Text('GHS ${preset.amountMajor.toStringAsFixed(0)}'),
                    selected: _preset == preset,
                    onSelected: (bool selected) => setState(() {
                      _preset = selected ? preset : null;
                      _error = null;
                      if (selected) _amountController.clear();
                    }),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (String value) => setState(() {
              _preset = null;
              _error = null;
            }),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: 'GHS ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: 'MOBILE_MONEY',
                label: Text('Mobile Money'),
                icon: Icon(Icons.phone_android),
              ),
              ButtonSegment<String>(
                value: 'CARD',
                label: Text('Card'),
                icon: Icon(Icons.credit_card),
              ),
            ],
            selected: <String>{_method},
            onSelectionChanged: (Set<String> selection) =>
                setState(() => _method = selection.first),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
