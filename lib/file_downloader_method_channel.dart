import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'file_downloader_platform_interface.dart';

/// An implementation of [FileDownloaderPlatform] that uses method channels.
class MethodChannelFileDownloader extends FileDownloaderPlatform  {
  @visibleForTesting
  final methodChannel = const MethodChannel('file_downloader');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
