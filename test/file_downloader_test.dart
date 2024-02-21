import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:file_downloader/file_downloader.dart';

class MockClient extends http.BaseClient {
  int statusCode;
  late Uint8List responseData;

  MockClient({this.statusCode = 200});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(http.ByteStream.fromBytes(responseData), statusCode);
  }
}

void main() {
  group('FileDownloader', () {
    test('downloadImage returns Image', () async {
      const imageUrl = 'http://example.com/image.jpg';
      final fileDownloader = FileDownloader.custom(client: MockClient());

      final image = await fileDownloader.downloadImage(imageUrl, (_, __) {});

      expect(image, isA<Image>());
    });

    test('downloadFile saves file and returns path', () async {
      const fileUrl = 'http://example.com/file.txt';
      final fileDownloader = FileDownloader.custom(client: MockClient());

      final filePath = await fileDownloader.downloadFile(fileUrl, (_, __) {});

      expect(filePath, isNotEmpty);
      expect(await File(filePath).exists(), isTrue);
    });

    test('downloadFileMultipart saves file and returns path', () async {
      const fileUrl = 'http://example.com/file.txt';
      final fileDownloader = FileDownloader.custom(client: MockClient());

      final filePath = await fileDownloader.downloadFileMultipart(fileUrl, (_, __) {}, 2);

      expect(filePath, isNotEmpty);
      expect(await File(filePath).exists(), isTrue);
    });

    test('cancelDownload cancels ongoing download', () async {
      const fileUrl = 'http://example.com/large_file.txt';
      final fileDownloader = FileDownloader.custom(client: MockClient());

      final Future<void> downloadFuture = fileDownloader.downloadFile(fileUrl, (_, __) {});

      // Wait for a short time and then cancel the download
      await Future.delayed(const Duration(milliseconds: 500));
      await fileDownloader.cancelDownload();

      // Ensure that the download was canceled and didn't complete
      expect(downloadFuture, throwsA(isA<Exception>()));
    });

    test('pauseDownload and resumeDownload pause and resume ongoing download', () async {
      const fileUrl = 'http://example.com/large_file.txt';
      final fileDownloader = FileDownloader.custom(client: MockClient());

      // Start the download
      final Future<void> downloadFuture = fileDownloader.downloadFile(fileUrl, (_, __) {});

      // Wait for a short time and then pause the download
      await Future.delayed(const Duration(milliseconds: 500));
      await fileDownloader.pauseDownload();

      // Ensure that the download is paused and hasn't completed yet
      expect(downloadFuture, throwsA(isA<Exception>()));

      // Wait for a short time and then resume the download
      await Future.delayed(const Duration(milliseconds: 500));
      await fileDownloader.resumeDownload();

      // Ensure that the download completes successfully
      await expectLater(downloadFuture, completes);
    });
  });
}
