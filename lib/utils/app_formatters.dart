import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final NumberFormat _percentFormat = NumberFormat.percentPattern();
  static final NumberFormat _numberFormat = NumberFormat('#,###');
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MM/dd/yyyy');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy h:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _weekdayFormat = DateFormat('EEEE');

  static String formatCurrency(double value) => _currencyFormat.format(value);
  static String formatPercent(double value) => _percentFormat.format(value / 100);
  static String formatNumber(int value) => _numberFormat.format(value);
  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
  static String formatWeekday(DateTime date) => _weekdayFormat.format(date);

  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static String formatStudentName(String firstName, String lastName) {
    return '$firstName $lastName';
  }

  static String formatInitials(String firstName, String lastName) {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  static String formatPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return phone;
  }
}

class AppValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must contain at least one uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must contain at least one lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain at least one number';
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    final num? number = num.tryParse(value);
    if (number == null) return 'Enter a valid number';
    if (number < 0) return '$fieldName must be positive';
    return null;
  }
}

class AppConstants {
  static const String appName = 'SchoolPulse';
  static const String appTagline = 'District School Intelligence & Early Warning System';

  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  static const Duration defaultAnimationDuration = Duration(milliseconds: 200);
  static const Duration snackbarDuration = Duration(seconds: 4);

  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;

  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets largePadding = EdgeInsets.all(24.0);

  static const List<String> gradeLevels = [
    'PK', 'K', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
  ];

  static const List<String> feeTypes = [
    'Tuition',
    'Registration',
    'Transportation',
    'Uniform',
    'Books & Materials',
    'Technology',
    'Activities',
    'Meals',
    'Other',
  ];
}