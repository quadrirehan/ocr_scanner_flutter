import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../domain/parsers.dart';

final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  return ScannerNotifier();
});

class ScannerState {
  final bool isScanning;
  final CardDetails? extractedCard;
  final BankDetails? extractedBank;
  final String? error;
  final String? imagePath; // Added for image preview

  ScannerState({
    this.isScanning = false,
    this.extractedCard,
    this.extractedBank,
    this.error,
    this.imagePath,
  });
}

class ScannerNotifier extends StateNotifier<ScannerState> {
  ScannerNotifier() : super(ScannerState());
  final textRecognizer = TextRecognizer();

  Future<void> processImage(String imagePath, bool isCard) async {
    state = ScannerState(isScanning: true, imagePath: imagePath);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);

      if (isCard) {
        final card = parseCard(recognizedText.text);
        state = ScannerState(
            isScanning: false,
            imagePath: imagePath,
            extractedCard: card,
            error: card == null ? "No valid card found. Please rescan." : null
        );
      } else {
        final bank = parsePassbook(recognizedText.text);
        state = ScannerState(
            isScanning: false,
            imagePath: imagePath,
            extractedBank: bank,
            error: bank == null ? "No valid passbook details found." : null
        );
      }
    } catch (e) {
      state = ScannerState(isScanning: false, error: "Failed to process image.");
    }
  }

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }
}