import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// A callback type for tracking download progress.
typedef DownloadProgressCallback = void Function(double progress, double speed);

/// A utility class for downloading files and images with progress tracking.
class FileDownloader {
  static const int STATE_IDLE = 0;
  static const int STATE_DOWNLOADING = 1;
  static const int STATE_PAUSED = 2;

  int _downloadState = STATE_IDLE;
  bool _isCancelled = false;
  Completer<void>? _downloadCompleter;
  late Stopwatch _stopwatch;
  late http.Client client;

  /// Initializes a new instance of the [FileDownloader] class.
  FileDownloader() {
    client = http.Client();
    _stopwatch = Stopwatch()..start();
  }

  FileDownloader.custom({required this.client}) {
    _stopwatch = Stopwatch()..start();
  }

  /// Cancels the ongoing download.
  ///
  /// This method cancels the ongoing download, if any, and resets the download state to idle.
  Future<void> cancelDownload() async {
    _isCancelled = true;
    _downloadCompleter?.complete();
    _downloadCompleter = null;
    _downloadState = STATE_IDLE;
  }

  /// Pauses the ongoing download.
  ///
  /// This method pauses the ongoing download if the download is in progress.
  Future<void> pauseDownload() async {
    if (_downloadState == STATE_DOWNLOADING) {
      _downloadState = STATE_PAUSED;
    }
  }

  /// Resumes the paused download.
  ///
  /// This method resumes the paused download if it was previously paused.
  Future<void> resumeDownload() async {
    if (_downloadState == STATE_PAUSED) {
      _downloadState = STATE_DOWNLOADING;
      await _downloadCompleter?.future;
    }
  }

  /// Downloads an image from the given [imageUrl].
  ///
  /// This method downloads an image from the provided [imageUrl] and tracks the download progress.
  /// The [onProgress] callback is called during the download to provide progress updates.
  Future<Image> downloadImage(String imageUrl, DownloadProgressCallback onProgress) async {
    try {
      final response = await _startDownload(http.Request('GET', Uri.parse(imageUrl)), onProgress);
      return Image.memory(Uint8List.fromList(response));
    } catch (error) {
      _handleError('Image download error', error);
      throw error;
    } finally {
      _completeDownload(onProgress);
    }
  }

  /// Downloads a file from the given [fileUrl].
  ///
  /// This method downloads a file from the provided [fileUrl] and tracks the download progress.
  /// The [onProgress] callback is called during the download to provide progress updates.
  Future<String> downloadFile(String fileUrl, DownloadProgressCallback onProgress) async {
    _setupDownload();
    try {
      final response = await _startDownload(http.Request('GET', Uri.parse(fileUrl)), onProgress);
      return await _saveToFile(response, _deriveFileName(fileUrl));
    } catch (error) {
      _handleError('File download error', error);
      throw error;
    } finally {
      _completeDownload(onProgress);
    }
  }

  /// Downloads a file with multipart support from the given [fileUrl].
  ///
  /// This method downloads a file with multipart support from the provided [fileUrl] and tracks the download progress.
  /// The [onProgress] callback is called during the download to provide progress updates.
  Future<String> downloadFileMultipart(String fileUrl, DownloadProgressCallback onProgress, int numberOfParts) async {
    _setupDownload();
    try {
      final response = await _startDownload(http.MultipartRequest('GET', Uri.parse(fileUrl)), onProgress);
      return await _saveToFile(response, _deriveFileName(fileUrl));
    } catch (error) {
      _handleError('Multipart file download error', error);
      throw error;
    } finally {
      _completeDownload(onProgress);
    }
  }

  /// Initiates the file download using the provided [request].
  ///
  /// This private method initiates the file download by sending the specified [request] and
  /// returns the downloaded data.
  Future<List<int>> _startDownload(http.BaseRequest request, DownloadProgressCallback onProgress) async {
    final client = this.client;
    try {
      _stopwatch = Stopwatch()..start();
      final response = await client.send(request);

      if (response.statusCode == 200) {
        return await _downloadStream(response, onProgress);
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Failed to initiate download: $error');
    } finally {
      client.close();
    }
  }

  /// Downloads the file content from the provided [response].
  ///
  /// This private method downloads the file content from the provided [response] and
  /// provides progress updates through the [onProgress] callback.
  Future<List<int>> _downloadStream(http.StreamedResponse response, DownloadProgressCallback onProgress) async {
    final int totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;

    final List<int> combinedChunks = [];

    _isCancelled = false;
    _stopwatch.reset();

    await for (List<int> chunk in response.stream) {
      if (_isCancelled) break;

      combinedChunks.addAll(chunk);
      receivedBytes += chunk.length;

      final double progress = (receivedBytes / totalBytes) * 100;
      final double speed = _calculateSpeed(chunk);

      onProgress(progress, speed.isFinite ? speed : 0.0);
    }

    if (_isCancelled) {
      throw Exception('Download canceled');
    }

    return combinedChunks;
  }

  /// Calculates the download speed based on the provided [chunk].
  ///
  /// This private method calculates the download speed based on the provided [chunk] size.
  double _calculateSpeed(List<int> chunk) {
    return (chunk.length / _stopwatch.elapsed.inMicroseconds) * 1000000;
  }

  /// Derives the file name from the provided [fileUrl].
  ///
  /// This private method extracts the file name from the provided [fileUrl].
  String _deriveFileName(String fileUrl) {
    String fileName = fileUrl.split('/').last;
    if (fileName.isEmpty) {
      fileName = '${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
    }
    return fileName;
  }

  /// Saves the downloaded data to a file with the specified [fileName].
  ///
  /// This private method saves the downloaded [data] to a file with the specified [fileName].
  Future<String> _saveToFile(List<int> data, String fileName) async {
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final destinationPath = '${appDocumentsDir.path}/$fileName';
    final Uint8List fileBytes = Uint8List.fromList(data);

    try {
      await File(destinationPath).writeAsBytes(fileBytes);
      return destinationPath;
    } catch (error) {
      throw Exception('Failed to save file: $error');
    }
  }

  /// Completes the download process.
  ///
  /// This private method completes the download process by invoking the [onProgress] callback
  /// with 100% progress and zero speed to signify the completion.
  void _completeDownload(DownloadProgressCallback onProgress) {
    _downloadCompleter?.complete();
    _downloadCompleter = null;
    onProgress(100.0, 0.0);
    onProgress(0.0, 0.0);
  }

  /// Sets up the initial download state.
  ///
  /// This private method sets up the initial download state, including resetting cancellation flags.
  void _setupDownload() {
    _downloadState = STATE_DOWNLOADING;
    _isCancelled = false;
    _downloadCompleter = Completer<void>();
  }

  /// Handles errors during the download process.
  ///
  /// This private method handles errors during the download process and can be customized based on app requirements.
  void _handleError(String errorMessage, dynamic error) {
    print('$errorMessage: $error');
    // Customized error handling can be added based on app's requirements.
  }
}