import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'providers/scanner_provider.dart';
import 'domain/parsers.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _cameras = await availableCameras();
  runApp(const ProviderScope(child: OcrScannerApp()));
}

class OcrScannerApp extends StatelessWidget {
  const OcrScannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late CameraController controller;
  bool isCardMode = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await
    _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(scannerProvider.notifier).processImage(image.path, isCardMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);

    if (!controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Document Scanner')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: CameraPreview(controller),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Passbook", style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: isCardMode,
                  onChanged: (val) => setState(() => isCardMode = val),
                ),
                const Text("Card", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                onPressed: scannerState.isScanning ? null : _pickImageFromGallery,
                label: const Text('Upload Image'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera),
                onPressed: scannerState.isScanning ? null : () async {
                  final image = await controller.takePicture();
                  ref.read(scannerProvider.notifier).processImage(image.path, isCardMode);
                },
                label: Text(scannerState.isScanning ? 'Scanning...' : 'Scan Now'),
              ),
            ],
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildResultsView(scannerState),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultsView(ScannerState state) {
    if (state.isScanning) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.imagePath == null) {
      return const Center(child: Text('Awaiting scan or upload...'));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Preview
        Container(
          width: 100,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(state.imagePath!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Extracted Data
        Expanded(
          child: SingleChildScrollView(
            child: _buildExtractedText(state),
          ),
        ),
      ],
    );
  }

  Widget _buildExtractedText(ScannerState state) {
    if (state.error != null) {
      return Text(state.error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
    }

    if (state.extractedCard != null && isCardMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card Found:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          const SizedBox(height: 8),
          Text('Number: ${maskCardNumber(state.extractedCard!.number)}', style: const TextStyle(fontSize: 14)),
          Text('Expiry: ${state.extractedCard!.expiry}', style: const TextStyle(fontSize: 14)),
          Text('Name: ${state.extractedCard!.name ?? "Not Detected"}', style: const TextStyle(fontSize: 14)),
        ],
      );
    }

    if (state.extractedBank != null && !isCardMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Passbook Found:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
          const SizedBox(height: 8),
          Text('Account: ${state.extractedBank!.accountNumber}', style: const TextStyle(fontSize: 14)),
          Text('IFSC: ${state.extractedBank!.ifscCode}', style: const TextStyle(fontSize: 14)),
          Text('Name: ${state.extractedBank!.name ?? "Not Detected"}', style: const TextStyle(fontSize: 14)),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}