import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'file_downloader_method_channel.dart';

abstract class FileDownloaderPlatform extends PlatformInterface {
  /// Constructs a FileDownloaderPlatform.
  FileDownloaderPlatform() : super(token: _token);

  static final Object _token = Object();

  static FileDownloaderPlatform _instance = MethodChannelFileDownloader();

  /// The default instance of [FileDownloaderPlatform] to use.
  ///
  /// Defaults to [MethodChannelFileDownloader].
  static FileDownloaderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FileDownloaderPlatform] when
  /// they register themselves.
  static set instance(FileDownloaderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
