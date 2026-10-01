import 'package:flutter_test/flutter_test.dart';
import '../lib/utils/app_formatters.dart';

void main() {
  group('AppFormatters', () {
    test('formatCurrency formats correctly', () {
      expect(AppFormatters.formatCurrency(0), equals('\$0.00'));
      expect(AppFormatters.formatCurrency(100), equals('\$100.00'));
      expect(AppFormatters.formatCurrency(1234.56), equals('\$1,234.56'));
      expect(AppFormatters.formatCurrency(1000000), equals('\$1,000,000.00'));
    });

    test('formatNumber formats correctly', () {
      expect(AppFormatters.formatNumber(0), equals('0'));
      expect(AppFormatters.formatNumber(1000), equals('1,000'));
      expect(AppFormatters.formatNumber(1000000), equals('1,000,000'));
    });

    test('formatPercent formats correctly', () {
      expect(AppFormatters.formatPercent(0), equals('0%'));
      expect(AppFormatters.formatPercent(50), equals('50%'));
      expect(AppFormatters.formatPercent(100), equals('100%'));
      expect(AppFormatters.formatPercent(99.5), equals('100%'));
    });

    test('formatDate formats correctly', () {
      final date = DateTime(2024, 1, 15, 10, 30);
      expect(AppFormatters.formatDate(date), equals('Jan 15, 2024'));
      expect(AppFormatters.formatShortDate(date), equals('01/15/2024'));
      expect(AppFormatters.formatTime(date), equals('10:30 AM'));
    });

    test('formatRelativeTime formats correctly', () {
      final now = DateTime.now();
      
      final justNow = AppFormatters.formatRelativeTime(now);
      expect(justNow, equals('Just now'));

      final minutesAgo = AppFormatters.formatRelativeTime(now.subtract(const Duration(minutes: 5)));
      expect(minutesAgo, equals('5 minutes ago'));

      final hourAgo = AppFormatters.formatRelativeTime(now.subtract(const Duration(hours: 1)));
      expect(hourAgo, equals('1 hour ago'));

      final hoursAgo = AppFormatters.formatRelativeTime(now.subtract(const Duration(hours: 3)));
      expect(hoursAgo, equals('3 hours ago'));

      final dayAgo = AppFormatters.formatRelativeTime(now.subtract(const Duration(days: 1)));
      expect(dayAgo, equals('1 day ago'));

      final daysAgo = AppFormatters.formatRelativeTime(now.subtract(const Duration(days: 5)));
      expect(daysAgo, equals('5 days ago'));

      final monthAgo = AppFormatters.formatRelativeTime(now.subtract(const Duration(days: 30)));
      expect(monthAgo, equals('30 days ago'));

      final yearAgo = AppFormatters.formatRelativeTime(now.subtract(const Duration(days: 400)));
      expect(yearAgo, equals('1 year ago'));
    });

    test('formatStudentName formats correctly', () {
      expect(AppFormatters.formatStudentName('John', 'Doe'), equals('John Doe'));
      expect(AppFormatters.formatStudentName('Jane', 'Smith'), equals('Jane Smith'));
    });

    test('formatInitials formats correctly', () {
      expect(AppFormatters.formatInitials('John', 'Doe'), equals('JD'));
      expect(AppFormatters.formatInitials('Alice', 'Brown'), equals('AB'));
      expect(AppFormatters.formatInitials('', 'Doe'), equals('D'));
      expect(AppFormatters.formatInitials('John', ''), equals('J'));
    });

    test('formatPhoneNumber formats correctly', () {
      expect(AppFormatters.formatPhoneNumber('1234567890'), equals('(123) 456-7890'));
      expect(AppFormatters.formatPhoneNumber('123-456-7890'), equals('(123) 456-7890'));
      expect(AppFormatters.formatPhoneNumber('123'), equals('123'));
    });
  });

  group('AppValidators', () {
    test('validateEmail returns correct results', () {
      expect(AppValidators.validateEmail('test@example.com'), isNull);
      expect(AppValidators.validateEmail('user.name@domain.org'), isNull);
      
      expect(AppValidators.validateEmail(''), equals('Email is required'));
      expect(AppValidators.validateEmail(null), equals('Email is required'));
      expect(AppValidators.validateEmail('invalid'), equals('Enter a valid email address'));
      expect(AppValidators.validateEmail('missing@domain'), equals('Enter a valid email address'));
      expect(AppValidators.validateEmail('@domain.com'), equals('Enter a valid email address'));
    });

    test('validatePassword returns correct results', () {
      expect(AppValidators.validatePassword('Password123'), isNull);
      expect(AppValidators.validatePassword('SecurePass1'), isNull);
      expect(AppValidators.validatePassword('MyPass1234'), isNull);
      
      expect(AppValidators.validatePassword(''), equals('Password is required'));
      expect(AppValidators.validatePassword(null), equals('Password is required'));
      expect(AppValidators.validatePassword('short'), equals('Password must be at least 8 characters'));
      expect(AppValidators.validatePassword('nouppercase123'), equals('Password must contain at least one uppercase letter'));
      expect(AppValidators.validatePassword('NOLOWERCASE123'), equals('Password must contain at least one lowercase letter'));
      expect(AppValidators.validatePassword('NoNumbers'), equals('Password must contain at least one number'));
    });

    test('validateRequired returns correct results', () {
      expect(AppValidators.validateRequired('value', 'Field'), isNull);
      expect(AppValidators.validateRequired('  ', 'Field'), equals('Field is required'));
      expect(AppValidators.validateRequired('', 'Field'), equals('Field is required'));
      expect(AppValidators.validateRequired(null, 'Field'), equals('Field is required'));
    });

    test('validatePhone returns correct results', () {
      expect(AppValidators.validatePhone('1234567890'), isNull);
      expect(AppValidators.validatePhone('+1 123 456 7890'), isNull);
      expect(AppValidators.validatePhone(''), isNull);
      expect(AppValidators.validatePhone(null), isNull);
      
      expect(AppValidators.validatePhone('123'), equals('Enter a valid phone number'));
      expect(AppValidators.validatePhone('abc'), equals('Enter a valid phone number'));
    });

    test('validatePositiveNumber returns correct results', () {
      expect(AppValidators.validatePositiveNumber('100', 'Amount'), isNull);
      expect(AppValidators.validatePositiveNumber('0', 'Amount'), isNull);
      expect(AppValidators.validatePositiveNumber('99.99', 'Amount'), isNull);
      
      expect(AppValidators.validatePositiveNumber('', 'Amount'), equals('Amount is required'));
      expect(AppValidators.validatePositiveNumber('abc', 'Amount'), equals('Enter a valid number'));
      expect(AppValidators.validatePositiveNumber('-10', 'Amount'), equals('Amount must be positive'));
    });
  });

  group('AppConstants', () {
    test('constants have expected values', () {
      expect(AppConstants.appName, equals('SchoolPulse'));
      expect(AppConstants.appTagline, equals('District School Intelligence & Early Warning System'));
      expect(AppConstants.defaultPageSize, equals(20));
      expect(AppConstants.maxPageSize, equals(100));
      expect(AppConstants.gradeLevels.length, equals(14));
      expect(AppConstants.feeTypes.length, equals(9));
    });
  });
}