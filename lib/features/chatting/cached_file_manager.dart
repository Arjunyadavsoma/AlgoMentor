import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

/// ✅ Handles caching of chat files to save bandwidth & load faster
class CachedFileManager {
  static CachedFileManager? _instance;
  static CachedFileManager get instance => _instance ??= CachedFileManager._internal();

  CachedFileManager._internal();

  /// ✅ Get local cache directory
  Future<String> _getCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/chat_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  /// ✅ Get cached file path for a given URL
  Future<File> _getLocalFile(String url) async {
    final cacheDir = await _getCacheDir();
    final fileName = p.basename(url); // extract file name from URL
    return File('$cacheDir/$fileName');
  }

  /// ✅ Check if file exists locally (cached)
  Future<bool> isFileCached(String url) async {
    final file = await _getLocalFile(url);
    return file.exists();
  }

  /// ✅ Fetch file: from cache if available, otherwise download & cache it
  Future<File> fetchFile(String url) async {
    final file = await _getLocalFile(url);

    if (await file.exists()) {
      print('📂 Loaded from cache: ${file.path}');
      return file;
    }

    print('🌐 Downloading: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      print('✅ Cached: ${file.path}');
      return file;
    } else {
      throw Exception('❌ Failed to download file: $url');
    }
  }

  /// ✅ Clear the entire cache (optional admin feature)
  Future<void> clearCache() async {
    final cacheDir = Directory(await _getCacheDir());
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      await cacheDir.create(); // recreate after clearing
      print('🗑 Cache cleared');
    }
  }

  /// ✅ Remove a single file from cache
  Future<void> removeFile(String url) async {
    final file = await _getLocalFile(url);
    if (await file.exists()) {
      await file.delete();
      print('🗑 Removed cached file: ${file.path}');
    }
  }
}
