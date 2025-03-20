import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeDialog extends StatelessWidget {
  final String couponCode;

  const QrCodeDialog({super.key, required this.couponCode});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Votre QR Code"),
      content: SizedBox(
        width: 250,
        height: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: couponCode.isNotEmpty ? couponCode : "Code non valide",
                version: QrVersions.auto,
                size: 200.0,
                errorStateBuilder: (context, error) => const Center(
                  child: Text("QR Code invalide", style: TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                couponCode.isNotEmpty ? "Code : $couponCode" : "Aucun code disponible",
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Fermer"),
        ),
      ],
    );
  }
}
