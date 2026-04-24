import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../constants.dart';

class VersionService {
  static Future<Map<String, dynamic>?> getVersionInfo() async {
    try {
      final response = await http.get(Uri.parse('$kBaseUrl/version'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching version info: $e');
    }
    return null;
  }

  static Future<bool> checkForUpdate() async {
    if (kIsWeb) return false;

    final versionInfo = await getVersionInfo();
    if (versionInfo == null) return false;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

    final latestVersion = versionInfo['latestVersion'] as String?;
    final latestBuild = versionInfo['buildNumber'] as int?;
    final isForced = versionInfo['isForced'] as bool? ?? false;

    if (latestVersion == null || latestBuild == null) return false;

    // Compare version and build number
    if (isVersionGreater(latestVersion, currentVersion) || (latestVersion == currentVersion && latestBuild > currentBuild)) {
      return isForced;
    }

    return false;
  }

  static bool isVersionGreater(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static String getDownloadUrl(String filename) {
    // Assuming the APKs are served from the root public folder
    final baseUrl = kBaseUrl.replaceAll('/api', '');
    return '$baseUrl/$filename';
  }
}
