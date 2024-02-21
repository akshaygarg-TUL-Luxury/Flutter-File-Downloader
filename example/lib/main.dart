import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:file_downloader/file_downloader.dart';
import 'package:open_file_plus/open_file_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String progress = '0';
  String speed = '0';
  final _fileDownloaderPlugin = FileDownloader();

  @override
  void initState() {
    super.initState();
  }

  void downloadImage() async {
    // Use any of the below URL for testing
    // String url = 'https://cdn.pixabay.com/photo/2016/05/05/02/37/sunset-1373171_1280.jpg';
    // String url = 'https://www.learningcontainer.com/bfd_download/large-sample-image-file-download-for-testing/';
    String url = 'https://onlinetestcase.com/wp-content/uploads/2023/06/10-MB-MP3.mp3';


    // uncomment any one of the below function to try

    // return _fileDownloaderPlugin.downloadImage(url, (p, s) {
    //   setState(() {
    //     progress = p.toStringAsFixed(0);
    //     speed = (s / 1000000).toStringAsFixed(2);
    //     // print('Progress is -> $progress');
    //     // print('Speed is -> $speed');
    //   });
    // });

    Future<String> future = _fileDownloaderPlugin.downloadFile(url, (p, s) {
        setState(() {
          progress = p.toStringAsFixed(0);
          speed = (s / 1000000).toStringAsFixed(2);
        });
    });

    // Future<String> future = _fileDownloaderPlugin.downloadFileMultipart(url, (p, s) {
    //   setState(() {
    //     progress = p.toStringAsFixed(0);
    //     speed = (s / 1000000).toStringAsFixed(2);
    //   });
    // }, 10);

    await future.then((String value) {
      print(value);
      OpenFile.open(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Progress is -> $progress %'),
              Text('Speed is -> $speed MB/s'),
              ElevatedButton(
                  onPressed: () {
                    downloadImage();
                  },
                  child: const Text('Download'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
