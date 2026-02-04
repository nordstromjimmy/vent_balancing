import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/measurement_point.dart';

class EditMeasurementPointDialog extends StatefulWidget {
  const EditMeasurementPointDialog({super.key, required this.point});

  final MeasurementPoint point;

  @override
  State<EditMeasurementPointDialog> createState() =>
      _EditMeasurementPointDialogState();
}

class _EditMeasurementPointDialogState
    extends State<EditMeasurementPointDialog> {
  late final TextEditingController _label;
  late final TextEditingController _projected;
  late final TextEditingController _measured;
  late AirType _airType;

  @override
  void initState() {
    super.initState();
    final p = widget.point;
    _label = TextEditingController(text: p.label);
    _projected = TextEditingController(text: p.projectedLs.toStringAsFixed(1));
    _measured = TextEditingController(
      text: p.measuredLs?.toStringAsFixed(1) ?? '',
    );
    _airType = p.airType;
  }

  @override
  void dispose() {
    _label.dispose();
    _projected.dispose();
    _measured.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) {
    final raw = s.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  void _save() {
    final label = _label.text.trim();
    final projected = _parseDouble(_projected.text);
    final measured = _parseDouble(_measured.text);

    if (label.isEmpty) return;
    if (projected == null || projected <= 0) return;

    Navigator.pop(
      context,
      widget.point.copyWith(
        label: label,
        projectedLs: projected,
        measuredLs: measured,
        airType: _airType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Redigera mätning'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: 'Etikett',
                hintText: 'e.x Rum 102 / Tilluft T1',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _projected,
              decoration: const InputDecoration(labelText: 'Projekterat (l/s)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _measured,
              decoration: const InputDecoration(labelText: 'Uppmätt (l/s)'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<AirType>(
              segments: const [
                ButtonSegment(value: AirType.supply, label: Text('Tilluft')),
                ButtonSegment(value: AirType.exhaust, label: Text('Frånluft')),
              ],
              selected: {_airType},
              onSelectionChanged: (s) => setState(() => _airType = s.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ångra'),
        ),
        FilledButton(onPressed: _save, child: const Text('Spara')),
      ],
    );
  }
}
