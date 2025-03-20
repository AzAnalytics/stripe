import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  /// 🔹 Ouvrir Google Maps avec l'adresse du restaurant
  Future<void> openGoogleMaps(String address) async {
    final Uri googleMapsAppUri = Uri.parse("geo:0,0?q=${Uri.encodeComponent(address)}");
    final Uri googleMapsWebUri =
    Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");

    if (await canLaunchUrl(googleMapsAppUri)) {
      await launchUrl(googleMapsAppUri);
    } else if (await canLaunchUrl(googleMapsWebUri)) {
      await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
    } else {
      print("❌ Impossible d'ouvrir Google Maps");
    }
  }
}
