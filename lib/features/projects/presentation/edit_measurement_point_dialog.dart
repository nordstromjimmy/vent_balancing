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

  late final TextEditingController _pressure;
  late final TextEditingController _kFactor;
  late final TextEditingController _setting;

  late final TextEditingController _projectedBase;
  late final TextEditingController _measuredBase;

  late final TextEditingController _projectedBoost;
  late final TextEditingController _measuredBoost;

  bool _hasBoost = false;

  @override
  void initState() {
    super.initState();
    final p = widget.point;
    _label = TextEditingController(text: p.label);
    _projected = TextEditingController(
      text: p.projectedBaseLs.toStringAsFixed(1),
    );
    _measured = TextEditingController(
      text: p.measuredBaseLs?.toStringAsFixed(1) ?? '',
    );
    _airType = p.airType;
    _pressure = TextEditingController(
      text: widget.point.pressurePa?.toStringAsFixed(0) ?? '',
    );
    _kFactor = TextEditingController(
      text: widget.point.kFactor?.toStringAsFixed(2) ?? '',
    );
    _setting = TextEditingController(text: widget.point.setting ?? '');

    _projectedBase = TextEditingController(
      text: p.projectedBaseLs.toStringAsFixed(1),
    );
    _measuredBase = TextEditingController(
      text: p.measuredBaseLs?.toStringAsFixed(1) ?? '',
    );

    _hasBoost = p.projectedBoostLs != null;

    _projectedBoost = TextEditingController(
      text: p.projectedBoostLs?.toStringAsFixed(1) ?? '',
    );
    _measuredBoost = TextEditingController(
      text: p.measuredBoostLs?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _label.dispose();
    _projected.dispose();
    _measured.dispose();
    _pressure.dispose();
    _kFactor.dispose();
    _setting.dispose();
    _projectedBase.dispose();
    _measuredBase.dispose();
    _projectedBoost.dispose();
    _measuredBoost.dispose();
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

    final pressure = _parseDouble(_pressure.text);
    final kFactor = _parseDouble(_kFactor.text);
    final setting = _setting.text.trim();

    final projectedBase = _parseDouble(_projectedBase.text);
    final measuredBase = _parseDouble(_measuredBase.text);

    if (projectedBase == null || projectedBase <= 0) return;

    final projectedBoost = _hasBoost
        ? _parseDouble(_projectedBoost.text)
        : null;
    final measuredBoost = _hasBoost ? _parseDouble(_measuredBoost.text) : null;

    if (_hasBoost && (projectedBoost == null || projectedBoost <= 0)) return;

    if (label.isEmpty) return;
    if (projected == null || projected <= 0) return;

    Navigator.pop(
      context,
      widget.point.copyWith(
        label: label,
        projectedBaseLs: projectedBase,
        measuredBaseLs: measuredBase,
        projectedBoostLs: projectedBoost,
        measuredBoostLs: measuredBoost,
        pressurePa: pressure,
        kFactor: kFactor,
        setting: setting.isEmpty ? null : setting,
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
              autofocus: false,
            ),
            TextField(
              controller: _projectedBase,
              decoration: const InputDecoration(
                labelText: 'Grund – Projekterat (l/s)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _measuredBase,
              decoration: const InputDecoration(
                labelText: 'Grund – Uppmätt (l/s)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Har forcerat flöde'),
              value: _hasBoost,
              onChanged: (v) => setState(() => _hasBoost = v),
            ),

            if (_hasBoost) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _projectedBoost,
                decoration: const InputDecoration(
                  labelText: 'Forcerat – Projekterat (l/s)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _measuredBoost,
                decoration: const InputDecoration(
                  labelText: 'Forcerat – Uppmätt (l/s)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<AirType>(
              segments: const [
                ButtonSegment(value: AirType.supply, label: Text('Tilluft')),
                ButtonSegment(value: AirType.exhaust, label: Text('Frånluft')),
              ],
              selected: {_airType},
              onSelectionChanged: (s) => setState(() => _airType = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pressure,
              decoration: const InputDecoration(
                labelText: 'Tryck (Pa)',
                hintText: 't.ex. 45',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kFactor,
              decoration: const InputDecoration(
                labelText: 'K-faktor',
                hintText: 't.ex. 1.25',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _setting,
              decoration: const InputDecoration(
                labelText: 'Inställning',
                hintText: 't.ex. +6, 0, 4',
              ),
              textInputAction: TextInputAction.done,
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
