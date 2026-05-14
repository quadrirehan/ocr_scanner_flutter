class CardDetails {
  final String number;
  final String expiry;
  final String? name;

  CardDetails({required this.number, required this.expiry, this.name});
}

class BankDetails {
  final String accountNumber;
  final String ifscCode;
  final String? name;

  BankDetails({required this.accountNumber, required this.ifscCode, this.name});
}

// 1. Card Parser
CardDetails? parseCard(String rawText) {
  final cardRegExp = RegExp(r'(?:\d[ -]*?){13,19}');
  final expiryRegExp = RegExp(r'\b(0[1-9]|1[0-2])[ /-]*(2[4-9]|[3-9]\d)\b');

  // Only use cleanText for finding the numbers
  final cleanText = rawText.toUpperCase().replaceAll('O', '0').replaceAll('I', '1');

  final cardMatch = cardRegExp.firstMatch(cleanText);
  final expiryMatch = expiryRegExp.firstMatch(cleanText);

  if (cardMatch != null && expiryMatch != null) {
    String number = cardMatch.group(0)!.replaceAll(RegExp(r'[ -]'), '');

    // Name Extraction (Use RAW text so names like JOHN don't become J0HN)
    String? extractedName;
    final lines = rawText.toUpperCase().split('\n');
    final excludeWords = ['VISA', 'MASTER', 'MASTERCARD', 'RUPAY', 'VALID', 'THRU', 'EXPIRES', 'MONTH', 'YEAR', 'CREDIT', 'DEBIT', 'BANK', 'CARD'];

    for (var line in lines) {
      // Keep only letters and format spacing
      String cleanLine = line.replaceAll(RegExp(r'[^A-Z\s]'), '').trim().replaceAll(RegExp(r'\s+'), ' ');

      if (cleanLine.isNotEmpty && cleanLine.split(' ').length >= 2) {
        bool containsExcluded = excludeWords.any((word) => cleanLine.contains(word));
        if (!containsExcluded && cleanLine.length > 6) {
          extractedName = cleanLine;
          break;
        }
      }
    }

    if (isValidCard(number)) {
      return CardDetails(number: number, expiry: expiryMatch.group(0)!, name: extractedName);
    }
  }
  return null;
}

// 2. Passbook Parser
BankDetails? parsePassbook(String rawText) {
  // Use cleanText exclusively for finding the account number
  final cleanText = rawText.toUpperCase().replaceAll('O', '0').replaceAll('I', '1');
  final digitRegExp = RegExp(r'\b\d{9,18}\b');

  // IFSC Regex: 4 letters, then a zero (or 'O' misread), then 6 characters
  final ifscRegExp = RegExp(r'[A-Z]{4}[0O][A-Z0-9]{6}');

  final matches = digitRegExp.allMatches(cleanText);
  String? bestAccount;
  for (final match in matches) {
    String num = match.group(0)!;
    if (bestAccount == null || num.length > bestAccount.length) {
      bestAccount = num;
    }
  }

  // Use RAW text for IFSC so we don't accidentally ruin the first 4 bank letters
  final ifscMatch = ifscRegExp.firstMatch(rawText.toUpperCase());
  String? finalIfsc;

  if (ifscMatch != null) {
    String temp = ifscMatch.group(0)!;
    // Force the 5th character to be a '0' and fix any trailing 'O's
    finalIfsc = '${temp.substring(0, 4)}0${temp.substring(5).replaceAll('O', '0')}';
  }

  // Name Extraction (Use RAW text)
  String? extractedName;
  final lines = rawText.toUpperCase().split('\n');
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('NAME') || lines[i].contains('MR ') || lines[i].contains('MRS ') || lines[i].contains('MS ')) {
      String possibleName = lines[i].replaceAll(RegExp(r'.*(NAME|MR\.|MRS\.|MR |MRS |MS |MS\.)\s*:?'), '').trim();
      possibleName = possibleName.replaceAll(RegExp(r'[^A-Z\s]'), '').trim();

      if (possibleName.isNotEmpty && possibleName.length > 2) {
        extractedName = possibleName;
        break;
      } else if (i + 1 < lines.length) {
        String nextLine = lines[i+1].replaceAll(RegExp(r'[^A-Z\s]'), '').trim();
        if (nextLine.isNotEmpty) {
          extractedName = nextLine;
          break;
        }
      }
    }
  }

  if (bestAccount != null && finalIfsc != null) {
    return BankDetails(accountNumber: bestAccount, ifscCode: finalIfsc, name: extractedName);
  }
  return null;
}

// 3. Luhn Algorithm Validator
bool isValidCard(String cardNumber) {
  String cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
  if (cleaned.isEmpty) return false;

  int sum = 0;
  bool alternate = false;

  for (int i = cleaned.length - 1; i >= 0; i--) {
    int n = int.parse(cleaned[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

String maskCardNumber(String cardNumber) {
  if (cardNumber.length < 4) return cardNumber;
  String lastFour = cardNumber.substring(cardNumber.length - 4);
  return 'XXXX XXXX XXXX $lastFour';
}