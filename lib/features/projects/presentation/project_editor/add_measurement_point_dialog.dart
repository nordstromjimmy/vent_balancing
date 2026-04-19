import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/app_dialog.dart';
import '../../domain/measurement_point.dart';

/// Shows the "add measurement point" dialog.
/// Returns the created [MeasurementPoint]s, or null if cancelled.
Future<List<MeasurementPoint>?> showAddMeasurementPointDialog(
  BuildContext context, {
  double tolerancePct = 10.0,
}) {
  return showDialog<List<MeasurementPoint>>(
    context: context,
    builder: (_) => _AddMeasurementPointDialog(tolerancePct: tolerancePct),
  );
}

/// A proper [StatefulWidget] dialog so that [TextEditingController] lifecycle
/// is tied to the widget, not a function scope. This prevents the
/// "controller used after dispose" crash that occurred when Flutter's closing
/// animation tried to rebuild text fields after manual disposal.
class _AddMeasurementPointDialog extends StatefulWidget {
  const _AddMeasurementPointDialog({required this.tolerancePct});
  final double tolerancePct;

  @override
  State<_AddMeasurementPointDialog> createState() =>
      _AddMeasurementPointDialogState();
}

class _AddMeasurementPointDialogState
    extends State<_AddMeasurementPointDialog> {
  // Controllers are safely disposed in dispose(), not in a function scope.
  final _labelController = TextEditingController();
  final _supplyBaseController = TextEditingController();
  final _exhaustBaseController = TextEditingController();
  final _supplyBoostController = TextEditingController();
  final _exhaustBoostController = TextEditingController();

  // Start with nothing selected — the user picks what they're adding.
  bool _includeSupply = false;
  bool _includeExhaust = false;
  bool _includeBoost = false;

  @override
  void dispose() {
    _labelController.dispose();
    _supplyBaseController.dispose();
    _exhaustBaseController.dispose();
    _supplyBoostController.dispose();
    _exhaustBoostController.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final raw = c.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  double? _clean(double? v) => (v != null && v > 0) ? v : null;

  void _save() {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;
    if (!_includeSupply && !_includeExhaust) return;

    final created = <MeasurementPoint>[];
    const uuid = Uuid();

    if (_includeSupply) {
      final base = _clean(_parse(_supplyBaseController));
      final boost = _includeBoost
          ? _clean(_parse(_supplyBoostController))
          : null;

      // Skip silently if supply was toggled on but no value was entered —
      // don't abort the whole save.
      if (base != null || boost != null) {
        created.add(
          MeasurementPoint(
            id: uuid.v4(),
            label: label,
            airType: AirType.supply,
            projectedBaseLs: base,
            projectedBoostLs: boost,
            tolerancePct: widget.tolerancePct,
          ),
        );
      }
    }

    if (_includeExhaust) {
      final base = _clean(_parse(_exhaustBaseController));
      final boost = _includeBoost
          ? _clean(_parse(_exhaustBoostController))
          : null;

      if (base != null || boost != null) {
        created.add(
          MeasurementPoint(
            id: uuid.v4(),
            label: label,
            airType: AirType.exhaust,
            projectedBaseLs: base,
            projectedBoostLs: boost,
            tolerancePct: widget.tolerancePct,
          ),
        );
      }
    }

    if (created.isEmpty) return; // Nothing valid was entered
    Navigator.pop(context, created);
  }

  Widget _numberField({
    required String title,
    required TextEditingController controller,
    String hint = 't.ex. 25',
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: title, hintText: hint),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: const Text('Lägg till flöde'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Rum / Etikett',
                hintText: 't.ex. Rum 102',
              ),
              autofocus: false,
            ),
            const SizedBox(height: 12),

            // Air type selection — nothing pre-selected.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AirTypeChip(
                  label: 'Tilluft',
                  selected: _includeSupply,
                  onSelected: (v) => setState(() => _includeSupply = v),
                ),
                _AirTypeChip(
                  label: 'Frånluft',
                  selected: _includeExhaust,
                  onSelected: (v) => setState(() => _includeExhaust = v),
                ),
              ],
            ),

            if (!_includeSupply && !_includeExhaust)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Välj Tilluft och/eller Frånluft.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              ),

            if (_includeSupply || _includeExhaust) ...[
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Har forcerat flöde'),
                value: _includeBoost,
                onChanged: (v) => setState(() => _includeBoost = v),
              ),
            ],

            // Supply fields
            if (_includeSupply) ...[
              const SizedBox(height: 4),
              _numberField(
                title: 'Tilluft – Grund (l/s)',
                controller: _supplyBaseController,
              ),
              if (_includeBoost) ...[
                const SizedBox(height: 12),
                _numberField(
                  title: 'Tilluft – Forcerat (l/s)',
                  controller: _supplyBoostController,
                ),
              ],
            ],

            // Exhaust fields
            if (_includeExhaust) ...[
              const SizedBox(height: 12),
              _numberField(
                title: 'Frånluft – Grund (l/s)',
                controller: _exhaustBaseController,
              ),
              if (_includeBoost) ...[
                const SizedBox(height: 12),
                _numberField(
                  title: 'Frånluft – Forcerat (l/s)',
                  controller: _exhaustBoostController,
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ångra'),
            ),
            const Spacer(),
            FilledButton(onPressed: _save, child: const Text('Spara')),
          ],
        ),
      ],
    );
  }
}

/// A [FilterChip] styled to match the app's [FilledButton] when selected:
/// solid teal background with white text and checkmark.
class _AirTypeChip extends StatelessWidget {
  const _AirTypeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF006876);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF374151),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      selectedColor: teal,
      checkmarkColor: Colors.white,
      backgroundColor: const Color(0xFFF3F4F6),
      side: BorderSide(color: selected ? teal : const Color(0xFFD1D5DB)),
      showCheckmark: true,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
