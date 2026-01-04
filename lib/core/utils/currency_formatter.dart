import 'formatters.dart';

/// Convenience function for formatting currency values.
/// Uses Formatters.currency() internally.
String formatCurrency(num? value) => Formatters.currency(value);

/// Convenience function for compact currency formatting.
String formatCurrencyCompact(num? value) => Formatters.currencyCompact(value);
