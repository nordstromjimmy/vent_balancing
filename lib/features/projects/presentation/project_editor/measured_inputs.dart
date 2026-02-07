import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MeasuredInputs extends StatefulWidget {
  const MeasuredInputs({
    super.key,
    required this.hasBase,
    required this.hasBoost,
    required this.baseInitialValue,
    required this.boostInitialValue,
    required this.onBaseChanged,
    required this.onBoostChanged,
  });

  final bool hasBase;
  final bool hasBoost;

  final double? baseInitialValue;
  final double? boostInitialValue;

  final ValueChanged<double?> onBaseChanged;
  final ValueChanged<double?> onBoostChanged;

  @override
  State<MeasuredInputs> createState() => _MeasuredInputsState();
}

class _MeasuredInputsState extends State<MeasuredInputs> {
  late final TextEditingController _baseController;
  late final TextEditingController _boostController;

  @override
  void initState() {
    super.initState();
    _baseController = TextEditingController(
      text: widget.baseInitialValue?.toStringAsFixed(0) ?? '',
    );
    _boostController = TextEditingController(
      text: widget.boostInitialValue?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant MeasuredInputs oldWidget) {
    super.didUpdateWidget(oldWidget);

    final baseText = widget.baseInitialValue?.toStringAsFixed(0) ?? '';
    if (_baseController.text != baseText) _baseController.text = baseText;

    final boostText = widget.boostInitialValue?.toStringAsFixed(0) ?? '';
    if (_boostController.text != boostText) _boostController.text = boostText;
  }

  @override
  void dispose() {
    _baseController.dispose();
    _boostController.dispose();
    super.dispose();
  }

  double? _parse(String s) {
    final raw = s.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  void _commitBase() => widget.onBaseChanged(_parse(_baseController.text));
  void _commitBoost() => widget.onBoostChanged(_parse(_boostController.text));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.hasBase)
          TextField(
            controller: _baseController,
            decoration: InputDecoration(
              labelText: 'Uppmätt grund (l/s)',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                tooltip: 'Rensa',
                icon: const Icon(Icons.backspace),
                onPressed: () {
                  _baseController.clear();
                  widget.onBaseChanged(null);
                },
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onSubmitted: (_) => _commitBase(),
            onEditingComplete: _commitBase,
          ),
        if (widget.hasBase && widget.hasBoost) const SizedBox(height: 8),
        if (widget.hasBoost)
          TextField(
            controller: _boostController,
            decoration: InputDecoration(
              labelText: 'Uppmätt forcerat (l/s)',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                tooltip: 'Rensa',
                icon: const Icon(Icons.backspace),
                onPressed: () {
                  _boostController.clear();
                  widget.onBoostChanged(null);
                },
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onSubmitted: (_) => _commitBoost(),
            onEditingComplete: _commitBoost,
          ),
      ],
    );
  }
}
