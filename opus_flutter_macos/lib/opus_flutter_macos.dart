import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:opus_flutter_platform_interface/opus_flutter_platform_interface.dart';
import 'package:path_provider/path_provider.dart';

/// macOS implementation of [OpusFlutterPlatform].
class OpusFlutterMacOS extends OpusFlutterPlatform {
  static const String _licenseFile = 'opus_license.txt';
  static const String _libraryAsset = 'libopus_universal.dylib';
  static const String _bundlePrefix = 'packages/opus_flutter_macos/assets/';
  static const String _envOverride = 'OPUS_FLUTTER_MACOS_LIB';

  static const List<String> _candidateLibraries = <String>[
    'libopus.dylib',
    '/opt/homebrew/lib/libopus.dylib',
    '/opt/homebrew/opt/opus/lib/libopus.dylib',
    '/usr/local/lib/libopus.dylib',
    '/usr/lib/libopus.dylib',
  ];

  static Future<Directory> _workDirectory() async {
    final String tmpPath = (await getTemporaryDirectory()).absolute.path;
    final Directory dir = Directory('$tmpPath/opus_flutter_macos/opus').absolute;
    await dir.create(recursive: true);
    return dir;
  }

  static Future<String?> _copyLibraryFromAssets() async {
    try {
      final ByteData data = await rootBundle.load('$_bundlePrefix$_libraryAsset');
      final Directory dir = await _workDirectory();
      final File libraryFile = File('${dir.path}/$_libraryAsset');
      if (!(await libraryFile.exists())) {
        await libraryFile.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }

      await _ensureLicense(dir);
      return libraryFile.path;
    } on FlutterError {
      return null;
    }
  }

  static Future<void> _ensureLicense(Directory dir) async {
    try {
      final ByteData data = await rootBundle.load('$_bundlePrefix$_licenseFile');
      final File license = File('${dir.path}/$_licenseFile');
      if (!(await license.exists())) {
        await license.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
    } on FlutterError {
      // License asset is optional.
    }
  }

  static DynamicLibrary? _tryOpen(String path) {
    try {
      return DynamicLibrary.open(path);
    } on ArgumentError {
      return null;
    } on IOException {
      return null;
    } on Exception {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Registers the macOS implementation.
  static void registerWith() {
    OpusFlutterPlatform.instance = OpusFlutterMacOS();
  }

  @override
  Future<dynamic> load() async {
    final String? overridePath = Platform.environment[_envOverride];
    if (overridePath != null && overridePath.isNotEmpty) {
      final DynamicLibrary? overridden = _tryOpen(overridePath);
      if (overridden != null) {
        return overridden;
      }
    }

    final String? assetPath = await _copyLibraryFromAssets();
    if (assetPath != null) {
      final DynamicLibrary? fromAsset = _tryOpen(assetPath);
      if (fromAsset != null) {
        return fromAsset;
      }
    }

    for (final String candidate in _candidateLibraries) {
      final DynamicLibrary? resolved = _tryOpen(candidate);
      if (resolved != null) {
        return resolved;
      }
    }

    throw UnsupportedError(
      'Could not locate a usable libopus.dylib on macOS. Set $_envOverride to '
      'the full path of a libopus.dylib, or bundle one at '
      '${_bundlePrefix}$_libraryAsset.',
    );
  }
}
