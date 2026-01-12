import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

/// Utility class for cache data compression and integrity checks
class CacheCompression {
  static const int _compressionThreshold = 1024; // Compress if > 1KB

  /// Compresses data using gzip if it exceeds the threshold
  static String compress(String data) {
    if (data.length < _compressionThreshold) {
      return data; // Don't compress small data
    }

    try {
      final bytes = utf8.encode(data);
      final compressed = gzip.encode(bytes);
      final base64Compressed = base64.encode(compressed);

      // Only use compression if it actually reduces size
      if (base64Compressed.length < data.length) {
        return 'gzip:$base64Compressed';
      }
      return data;
    } catch (e) {
      // If compression fails, return original data
      return data;
    }
  }

  /// Decompresses data if it was compressed
  static String decompress(String data) {
    if (!data.startsWith('gzip:')) {
      return data; // Not compressed
    }

    try {
      final base64Data = data.substring(5); // Remove 'gzip:' prefix
      final compressed = base64.decode(base64Data);
      final decompressed = gzip.decode(compressed);
      return utf8.decode(decompressed);
    } catch (e) {
      // If decompression fails, return original data
      return data;
    }
  }

  /// Generates a checksum (MD5 hash) for data integrity verification
  static String generateChecksum(String data) {
    return md5.convert(utf8.encode(data)).toString();
  }

  /// Verifies data integrity using checksum
  static bool verifyChecksum(String data, String expectedChecksum) {
    final actualChecksum = generateChecksum(data);
    return actualChecksum == expectedChecksum;
  }

  /// Gets the size of data in bytes (after potential compression)
  static int getDataSize(String data) {
    return utf8.encode(data).length;
  }

  /// Estimates compression ratio
  static double estimateCompressionRatio(String originalData, String compressedData) {
    if (originalData.isEmpty) return 1.0;
    return getDataSize(compressedData) / getDataSize(originalData);
  }
}