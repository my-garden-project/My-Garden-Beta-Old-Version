import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PackageScannerScreen extends StatefulWidget {
  const PackageScannerScreen({super.key});

  @override
  State<PackageScannerScreen> createState() => _PackageScannerScreenState();
}

class _PackageScannerScreenState extends State<PackageScannerScreen> {
  bool _handled = false;

  void _handleCapture(BarcodeCapture capture) {
    if (_handled || capture.barcodes.isEmpty) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .firstOrNull;
    if (value == null) return;
    _handled = true;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: const Text(
          'Сканувати пакет',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            key: const Key('package-barcode-scanner'),
            tapToFocus: true,
            onDetect: _handleCapture,
            errorBuilder: (context, error) => _ScannerUnavailable(
              message: error.errorCode.name,
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 290,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 18,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Наведіть камеру на EAN або QR-код пакування. Після сканування підтвердьте: це насіння, добриво чи засіб захисту.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: FilledButton.tonalIcon(
              key: const Key('enter-barcode-manually'),
              onPressed: _enterManually,
              icon: const Icon(Icons.keyboard_alt_outlined),
              label: const Text('Ввести код вручну'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enterManually() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Код із пакування'),
        content: TextField(
          key: const Key('manual-barcode-field'),
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.text,
          inputFormatters: [LengthLimitingTextInputFormatter(64)],
          decoration: const InputDecoration(
            labelText: 'EAN / QR-код',
            hintText: 'Наприклад, 5901234123457',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Продовжити'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && mounted) Navigator.pop(context, result);
  }
}

class _ScannerUnavailable extends StatelessWidget {
  final String message;

  const _ScannerUnavailable({required this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111111),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 54,
              ),
              const SizedBox(height: 14),
              const Text(
                'Камера недоступна',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'На Simulator скористайтеся ручним введенням. На телефоні перевірте дозвіл камери.\n$message',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
