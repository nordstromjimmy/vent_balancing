/// Formats a flow value in l/s, e.g. "25.0 l/s", or "—" if null.
String fmtLs(double? v, {int decimals = 0}) =>
    v == null ? '—' : '${v.toStringAsFixed(decimals)} l/s';

/// Formats a flow value without the unit, or "—" if null.
String fmtLsRaw(double? v, {int decimals = 0}) =>
    v == null ? '—' : v.toStringAsFixed(decimals);

/// Formats a percentage, e.g. "95%", or "—" if null.
String fmtPct(double? v, {int decimals = 0}) =>
    v == null ? '—' : '${v.toStringAsFixed(decimals)}%';

/// Formats a signed deviation, e.g. "+5%" or "-12%", or "—" if null.
String fmtDeviationPct(double? v, {int decimals = 0}) {
  if (v == null) return '—';
  final sign = v >= 0 ? '+' : '';
  return '$sign${v.toStringAsFixed(decimals)}%';
}

/// Formats a signed delta, e.g. "+3.5 l/s" or "-1.0 l/s".
String fmtDeltaLs(double v, {int decimals = 0}) {
  final sign = v >= 0 ? '+' : '';
  return '$sign${v.toStringAsFixed(decimals)} l/s';
}
