import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _SolveFor { flow, kFactor, pressure }

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  _SolveFor _solveFor = _SolveFor.flow;

  final _kController = TextEditingController();
  final _pController = TextEditingController();
  final _qController = TextEditingController();

  String? _result;
  String? _resultLabel;
  String? _error;

  @override
  void dispose() {
    _kController.dispose();
    _pController.dispose();
    _qController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _result = null;
      _error = null;
    });

    double? parse(TextEditingController c) {
      final raw = c.text.trim().replaceAll(',', '.');
      if (raw.isEmpty) return null;
      return double.tryParse(raw);
    }

    final k = parse(_kController);
    final p = parse(_pController);
    final q = parse(_qController);

    switch (_solveFor) {
      case _SolveFor.flow:
        if (k == null || p == null) {
          setState(() => _error = 'Ange K-faktor och tryck (Pa).');
          return;
        }
        if (k <= 0 || p < 0) {
          setState(() => _error = 'K och ΔP måste vara positiva värden.');
          return;
        }
        final result = k * sqrt(p);
        setState(() {
          _result = '${result.toStringAsFixed(1)} l/s';
          _resultLabel = 'Luftflöde (Q)';
        });

      case _SolveFor.kFactor:
        if (q == null || p == null) {
          setState(() => _error = 'Ange luftflöde (l/s) och tryck (Pa).');
          return;
        }
        if (q <= 0 || p <= 0) {
          setState(() => _error = 'Q och ΔP måste vara större än noll.');
          return;
        }
        final result = q / sqrt(p);
        setState(() {
          _result = result.toStringAsFixed(3);
          _resultLabel = 'K-faktor';
        });

      case _SolveFor.pressure:
        if (q == null || k == null) {
          setState(() => _error = 'Ange luftflöde (l/s) och K-faktor.');
          return;
        }
        if (q <= 0 || k <= 0) {
          setState(() => _error = 'Q och K måste vara större än noll.');
          return;
        }
        final result = pow(q / k, 2).toDouble();
        setState(() {
          _result = '${result.toStringAsFixed(1)} Pa';
          _resultLabel = 'Tryckdifferens (ΔP)';
        });
    }
  }

  void _reset() {
    setState(() {
      _kController.clear();
      _pController.clear();
      _qController.clear();
      _result = null;
      _resultLabel = null;
      _error = null;
    });
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // Visual cue that this field is the one being solved for
        fillColor: enabled
            ? null
            : Theme.of(context).colorScheme.surfaceContainerLow,
        suffixIcon: !enabled
            ? const Tooltip(
                message: 'Beräknas automatiskt',
                child: Icon(Icons.functions, size: 18),
              )
            : null,
      ),
      onSubmitted: (_) => _calculate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final solveForFlow = _solveFor == _SolveFor.flow;
    final solveForK = _solveFor == _SolveFor.kFactor;
    final solveForP = _solveFor == _SolveFor.pressure;

    return Scaffold(
      appBar: AppBar(title: const Text('Kalkylator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Formula card ───────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.functions, color: cs.primary, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q = K × √ΔP',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Q = Luftflöde (l/s)   K = K-faktor   ΔP = Tryck (Pa)',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.outline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Solve for selector ─────────────────────────────────────────
            Text('BERÄKNA', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            SegmentedButton<_SolveFor>(
              segments: const [
                ButtonSegment(
                  value: _SolveFor.flow,
                  label: Text('Flöde (Q)'),
                  icon: Icon(Icons.air, size: 16),
                ),
                ButtonSegment(
                  value: _SolveFor.kFactor,
                  label: Text('K-faktor'),
                  icon: Icon(Icons.tune, size: 16),
                ),
                ButtonSegment(
                  value: _SolveFor.pressure,
                  label: Text('Tryck (ΔP)'),
                  icon: Icon(Icons.compress, size: 16),
                ),
              ],
              selected: {_solveFor},
              onSelectionChanged: (s) {
                setState(() {
                  _solveFor = s.first;
                  _result = null;
                  _error = null;
                });
              },
            ),

            const SizedBox(height: 24),

            // ── Input fields ───────────────────────────────────────────────
            Text('VÄRDEN', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _field(
                      controller: _qController,
                      label: 'Luftflöde Q (l/s)',
                      hint: 't.ex. 25',
                      enabled: !solveForFlow,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _kController,
                      label: 'K-faktor',
                      hint: 't.ex. 1.25',
                      enabled: !solveForK,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _pController,
                      label: 'Tryckdifferens ΔP (Pa)',
                      hint: 't.ex. 45',
                      enabled: !solveForP,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Calculate button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text('Beräkna'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // ── Result ─────────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFBF2020).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFBF2020).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFBF2020),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFBF2020),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    Text(
                      _resultLabel ?? 'Resultat',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
