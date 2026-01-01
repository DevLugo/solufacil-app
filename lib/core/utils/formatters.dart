import 'package:intl/intl.dart';

/// Formatters for currency, dates, and other common formats
class Formatters {
  Formatters._();

  // Currency formatter - Mexican Peso
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final _currencyFormatterNoDecimals = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final _numberFormatter = NumberFormat('#,##0.00', 'es_MX');

  // Date formatters
  static final _dateFormatter = DateFormat('dd/MM/yyyy', 'es_MX');
  static final _dateShortFormatter = DateFormat('dd/MMM/yyyy', 'es_MX');
  static final _dateFullFormatter = DateFormat("d 'de' MMMM 'de' yyyy", 'es_MX');
  static final _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm', 'es_MX');

  /// Format a number as Mexican Peso currency
  static String currency(num? value) {
    if (value == null) return '\$0.00';
    return _currencyFormatter.format(value);
  }

  /// Format a number as Mexican Peso currency without decimals
  static String currencyCompact(num? value) {
    if (value == null) return '\$0';
    return _currencyFormatterNoDecimals.format(value);
  }

  /// Format a number with thousands separator
  static String number(num? value) {
    if (value == null) return '0.00';
    return _numberFormatter.format(value);
  }

  /// Format a date as dd/MM/yyyy
  static String date(DateTime? date) {
    if (date == null) return '-';
    return _dateFormatter.format(date);
  }

  /// Format a date as dd/MMM/yyyy (e.g., 15/Mar/2024)
  static String dateShort(DateTime? date) {
    if (date == null) return '-';
    return _dateShortFormatter.format(date);
  }

  /// Format a date as "d de MMMM de yyyy" (e.g., 15 de marzo de 2024)
  static String dateFull(DateTime? date) {
    if (date == null) return '-';
    return _dateFullFormatter.format(date);
  }

  /// Format a date with time
  static String dateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeFormatter.format(date);
  }

  /// Parse a date string in ISO 8601 format
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Format percentage
  static String percentage(num? value, {int decimals = 0}) {
    if (value == null) return '0%';
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Calculate and format payment progress percentage
  static String paymentProgress(num? paid, num? total) {
    if (total == null || total == 0) return '0%';
    final progress = ((paid ?? 0) / total * 100).clamp(0, 100);
    return '${progress.toStringAsFixed(0)}%';
  }

  /// Format phone number
  static String phone(String? phone) {
    if (phone == null || phone.isEmpty) return '-';
    // Remove non-numeric characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return phone;
  }

  /// Truncate text with ellipsis
  static String truncate(String? text, int maxLength) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Format relative time (e.g., "hace 5 min")
  static String relativeTime(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'hace un momento';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return 'hace $mins min${mins == 1 ? '' : 's'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'hace $hours hora${hours == 1 ? '' : 's'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'hace $days día${days == 1 ? '' : 's'}';
    } else {
      return dateShort(date);
    }
  }
}
