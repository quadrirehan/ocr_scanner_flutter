import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_scanner/domain/parsers.dart';

void main() {
  group('1. Luhn Algorithm Tests', () {
    test('Should return true for a valid credit card number', () {
      // Standard test VISA number
      expect(isValidCard("4111111111111111"), isTrue);
    });

    test('Should return false for an invalid credit card number', () {
      expect(isValidCard("4111111111111112"), isFalse);
    });

    test('Should handle strings with spaces or dashes correctly', () {
      expect(isValidCard("4111 1111 1111 1111"), isTrue);
      expect(isValidCard("4111-1111-1111-1111"), isTrue);
    });
  });

  group('2. Card Parser Tests', () {
    test('Should successfully parse a clean card OCR read', () {
      const rawText = '''
      BANK OF INDIA
      4111 1111 1111 1111
      VALID THRU 12/25
      JOHN DOE
      VISA
      ''';

      final result = parseCard(rawText);

      expect(result, isNotNull);
      expect(result!.number, "4111111111111111");
      expect(result.expiry, "12/25");
      expect(result.name, "JOHN DOE");
    });

    test('Should fix OCR misreads (O vs 0, I vs 1) and extract data', () {
      // Notice the letter 'O' instead of zero, and 'I' instead of one
      const noisyText = '''
      4I11 1111 1111 1111
      EXPIRES 12/25
      ''';

      final result = parseCard(noisyText);

      expect(result, isNotNull);
      expect(result!.number, "4111111111111111");
    });

    test('Should return null if card number fails Luhn validation', () {
      const rawText = "4111 1111 1111 1112 \n 12/25"; // Invalid number
      final result = parseCard(rawText);
      expect(result, isNull);
    });
  });

  group('3. Passbook Parser Tests', () {
    test('Should extract account number, IFSC, and Name from standard passbook', () {
      const rawText = '''
      STATE BANK
      NAME: JANE SMITH
      A/C NO: 31234567890
      IFSC CODE: SBIN0001234
      BRANCH: MAIN
      ''';

      final result = parsePassbook(rawText);

      expect(result, isNotNull);
      expect(result!.accountNumber, "31234567890");
      expect(result.ifscCode, "SBIN0001234");
      expect(result.name, "JANE SMITH");
    });

    test('Should extract the longest number as the account number when multiple numbers exist', () {
      const rawText = '''
      CUSTOMER ID: 12345678
      A/C: 987654321012345
      PHONE: 9988776655
      IFSC: HDFC0123456
      ''';

      final result = parsePassbook(rawText);

      expect(result, isNotNull);
      // It should pick the 15-digit account number, ignoring the 8-digit ID and 10-digit phone
      expect(result!.accountNumber, "987654321012345");
    });

    test('Should fix OCR misreads in Passbook (O vs 0)', () {
      // 'O' instead of '0' in the IFSC and account number
      const rawText = '''
      A/C: 123456789O
      IFSC: SBINO001234
      ''';

      final result = parsePassbook(rawText);

      expect(result, isNotNull);
      expect(result!.accountNumber, "1234567890");
      expect(result.ifscCode, "SBIN0001234");
    });
  });
}