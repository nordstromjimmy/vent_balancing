import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../domain/measurement_point.dart';

Future<List<MeasurementPoint>?> showAddMeasurementPointDialog(
  BuildContext context,
) async {
  const uuid = Uuid();

  final labelController = TextEditingController();

  // Base flows
  final supplyBaseController = TextEditingController();
  final exhaustBaseController = TextEditingController();

  // Boost flows
  final supplyBoostController = TextEditingController();
  final exhaustBoostController = TextEditingController();

  bool includeSupply = true;
  bool includeExhaust = true;
  bool includeBoost = false;

  InputDecoration dec(String label, String hint) =>
      InputDecoration(labelText: label, hintText: hint);

  Widget numberField({
    required String title,
    required TextEditingController controller,
    String hint = 't.ex. 25',
  }) {
    return TextField(
      controller: controller,
      decoration: dec(title, hint),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    );
  }

  double? parseCtrl(TextEditingController c) {
    final raw = c.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  double? clean(double? v) => (v != null && v > 0) ? v : null;

  final result = await showDialog<List<MeasurementPoint>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('Lägg till flöde'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: dec('Rum / Etikett', 't.ex. Rum 102'),
                    autofocus: false,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tilluft'),
                        selected: includeSupply,
                        onSelected: (v) =>
                            setLocalState(() => includeSupply = v),
                      ),
                      FilterChip(
                        label: const Text('Frånluft'),
                        selected: includeExhaust,
                        onSelected: (v) =>
                            setLocalState(() => includeExhaust = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Har forcerat flöde'),
                    value: includeBoost,
                    onChanged: (v) => setLocalState(() => includeBoost = v),
                  ),
                  const SizedBox(height: 8),
                  if (includeSupply) ...[
                    numberField(
                      title: 'Tilluft – Grund (l/s)',
                      controller: supplyBaseController,
                    ),
                    if (includeBoost) ...[
                      const SizedBox(height: 12),
                      numberField(
                        title: 'Tilluft – Forcerat (l/s)',
                        controller: supplyBoostController,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  if (includeExhaust) ...[
                    numberField(
                      title: 'Frånluft – Grund (l/s)',
                      controller: exhaustBaseController,
                    ),
                    if (includeBoost) ...[
                      const SizedBox(height: 12),
                      numberField(
                        title: 'Frånluft – Forcerat (l/s)',
                        controller: exhaustBoostController,
                      ),
                    ],
                  ],
                  if (!includeSupply && !includeExhaust)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Välj Tilluft och/eller Frånluft.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ångra'),
              ),
              FilledButton(
                onPressed: () {
                  final baseLabel = labelController.text.trim();
                  if (baseLabel.isEmpty) return;
                  if (!includeSupply && !includeExhaust) return;

                  final created = <MeasurementPoint>[];

                  if (includeSupply) {
                    final base = clean(parseCtrl(supplyBaseController));
                    final boost = includeBoost
                        ? clean(parseCtrl(supplyBoostController))
                        : null;

                    if (base == null && boost == null) return;

                    created.add(
                      MeasurementPoint(
                        id: uuid.v4(),
                        label: baseLabel,
                        airType: AirType.supply,
                        projectedBaseLs: base,
                        projectedBoostLs: boost,
                      ),
                    );
                  }

                  if (includeExhaust) {
                    final base = clean(parseCtrl(exhaustBaseController));
                    final boost = includeBoost
                        ? clean(parseCtrl(exhaustBoostController))
                        : null;

                    if (base == null && boost == null) return;

                    created.add(
                      MeasurementPoint(
                        id: uuid.v4(),
                        label: baseLabel,
                        airType: AirType.exhaust,
                        projectedBaseLs: base,
                        projectedBoostLs: boost,
                      ),
                    );
                  }

                  Navigator.pop(context, created);
                },
                child: const Text('Spara'),
              ),
            ],
          );
        },
      );
    },
  );

  // Avoid controller leaks
  labelController.dispose();
  supplyBaseController.dispose();
  exhaustBaseController.dispose();
  supplyBoostController.dispose();
  exhaustBoostController.dispose();

  return result;
}
