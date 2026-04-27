import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _kController = TextEditingController();
  final _pController = TextEditingController();

  String? _result;
  String? _error;

  @override
  void dispose() {
    _kController.dispose();
    _pController.dispose();
    super.dispose();
  }

  void _calculate() {
    double? parse(TextEditingController c) {
      final raw = c.text.trim().replaceAll(',', '.');
      if (raw.isEmpty) return null;
      return double.tryParse(raw);
    }

    final k = parse(_kController);
    final p = parse(_pController);

    if (k == null || p == null) {
      setState(() {
        _result = null;
        _error = 'Ange både K-faktor och tryck (Pa).';
      });
      return;
    }

    if (k <= 0 || p < 0) {
      setState(() {
        _result = null;
        _error = 'K och ΔP måste vara positiva värden.';
      });
      return;
    }

    final q = k * sqrt(p);
    setState(() {
      _error = null;
      _result = q.toStringAsFixed(1);
    });
  }

  void _reset() {
    setState(() {
      _kController.clear();
      _pController.clear();
      _result = null;
      _error = null;
    });
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, hintText: hint),
      onSubmitted: (_) => _calculate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkylator'),
        actions: [
          IconButton(
            tooltip: 'Rensa',
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
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
                            fontSize: 22,
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

            const SizedBox(height: 24),

            // ── Inputs ─────────────────────────────────────────────────────
            Text('VÄRDEN', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _field(
                      controller: _kController,
                      label: 'K-faktor',
                      hint: 't.ex. 1.25',
                    ),
                    const SizedBox(height: 12),
                    _field(
                      controller: _pController,
                      label: 'Tryckdifferens ΔP (Pa)',
                      hint: 't.ex. 45',
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

            // ── Error ──────────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFBF2020).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFBF2020).withValues(alpha: 0.3),
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

            // ── Result ─────────────────────────────────────────────────────
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  children: [
                    Text(
                      'LUFTFLÖDE (Q)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_result l/s',
                      style: TextStyle(
                        fontSize: 40,
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
