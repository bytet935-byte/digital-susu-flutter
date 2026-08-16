import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Opens the Susu Calculator sheet (spec "Susu Calculator"): contribution
/// per cycle × members = pot per cycle; total pooled across the cycle
/// count, and your own total contribution.
Future<void> showSusuCalculatorSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (context) => const SusuCalculatorSheet(),
  );
}

class SusuCalculatorSheet extends StatefulWidget {
  const SusuCalculatorSheet({super.key});

  @override
  State<SusuCalculatorSheet> createState() => _SusuCalculatorSheetState();
}

class _SusuCalculatorSheetState extends State<SusuCalculatorSheet> {
  final TextEditingController _contributionController =
      TextEditingController(text: '100');
  int _members = 10;
  int _cycles = 26;

  @override
  void dispose() {
    _contributionController.dispose();
    super.dispose();
  }

  String _ghs(int major) => 'GHS ${NumberFormat('#,##0.00').format(major)}';

  double get _contributionMajor =>
      double.tryParse(_contributionController.text.trim()) ?? 0;

  double get _potPerCycle => _contributionMajor * _members;

  double get _totalPooled => _potPerCycle * _cycles;

  double get _yourTotal => _contributionMajor * _cycles;

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
          Text('Susu Calculator', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Estimate pots and cycles before creating a group.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contributionController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Contribution per cycle',
              prefixText: 'GHS ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _StepperRow(
            label: 'Members',
            value: _members,
            min: 2,
            max: 50,
            onChanged: (int v) => setState(() => _members = v),
          ),
          const SizedBox(height: 8),
          _StepperRow(
            label: 'Cycles',
            value: _cycles,
            min: 4,
            max: 52,
            onChanged: (int v) => setState(() => _cycles = v),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: <Widget>[
                _ResultRow(
                  label: 'Pot per cycle',
                  value: _ghs(_potPerCycle.round()),
                  emphasized: true,
                ),
                const SizedBox(height: 8),
                _ResultRow(
                  label: 'Total pooled',
                  value: _ghs(_totalPooled.round()),
                ),
                const SizedBox(height: 8),
                _ResultRow(
                  label: 'Your total contribution',
                  value: _ghs(_yourTotal.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: 'Decrease $label',
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: theme.textTheme.emphasis,
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
          tooltip: 'Increase $label',
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: emphasized
              ? theme.textTheme.emphasis.copyWith(color: AppColors.primary)
              : theme.textTheme.emphasis,
        ),
      ],
    );
  }
}
