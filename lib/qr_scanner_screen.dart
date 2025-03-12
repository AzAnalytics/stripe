import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool isProcessing = false;

  /// 🔹 Vérifier et valider le coupon scanné
  Future<void> validateCoupon(String scannedCode) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection("coupons")
          .where("uniqueCode", isEqualTo: scannedCode)
          .where("isActive", isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showValidationScreen(false);
        setState(() => isProcessing = false);
        return;
      }

      // 🔥 Désactiver le coupon
      String couponId = query.docs.first.id;
      await FirebaseFirestore.instance.collection("coupons").doc(couponId).update({
        "isActive": false,
        "usedAt": Timestamp.now(),
      });

      _showValidationScreen(true);
    } catch (e) {
      showMessage("❌ Erreur lors de la validation : $e");
    }

    setState(() => isProcessing = false);
  }

  /// 🔹 Affiche une boîte de dialogue après validation du coupon
  void _showValidationScreen(bool isValid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isValid ? "Coupon Validé" : "Coupon Invalide"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.cancel,
                color: isValid ? Colors.green : Colors.red,
                size: 60,
              ),
              const SizedBox(height: 10),
              Text(
                isValid ? "✅ Ce coupon est valide !" : "❌ Ce coupon a déjà été utilisé ou est invalide.",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Afficher un message dans un SnackBar
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner un Coupon"), backgroundColor: Colors.orange),
      body: MobileScanner(
        onDetect: (capture) {
          if (capture.barcodes.isNotEmpty) {
            final String? code = capture.barcodes.first.rawValue;
            if (code != null) {
              validateCoupon(code);
            }
          }
        },
      ),
    );
  }
}
