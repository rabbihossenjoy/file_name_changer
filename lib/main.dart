import 'dart:html' as html;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App File Name Changer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DropzoneViewController _controller;
  bool _dragging = false;
  final TextEditingController _textController = TextEditingController();
  final Set<String> _processedFiles = {};
  bool _isShowingDialog = false;

  void _pickFiles() async {
    if (_textController.text.trim().isEmpty) {
      _showAlertMessage('Please enter your app name');
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      Uint8List fileBytes = result.files.first.bytes!;
      String fileName = result.files.first.name;

      _processFile(fileBytes, fileName);
    }
  }

  void _processFile(Uint8List fileBytes, String fileName) {
    String customName = _textController.text.trim();
    String arm64FileName = '$customName-arm64-v8a.apk';
    String armeabiFileName = '$customName-armeabi-v7a.apk';

    if (fileName.endsWith('arm64-v8a-release.apk') &&
        !_processedFiles.contains(arm64FileName)) {
      _processedFiles.add(arm64FileName);
      _downloadFile(fileBytes, arm64FileName);
    } else if (fileName.endsWith('armeabi-v7a-release.apk') &&
        !_processedFiles.contains(armeabiFileName)) {
      _processedFiles.add(armeabiFileName);
      _downloadFile(fileBytes, armeabiFileName);
    }
  }

  void _downloadFile(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _showAlertMessage(String message) {
    if (_isShowingDialog) return;
    _isShowingDialog = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isShowingDialog = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App File Name Changer"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter an app name',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFiles,
              child: const Text('Pick Files'),
            ),
            const SizedBox(height: 20),
            Container(
              width: 300,
              height: 200,
              color: Colors.grey[200],
              child: DropzoneView(
                onCreated: (controller) => _controller = controller,
                onDrop: (dynamic ev) async {
                  if (_textController.text.trim().isEmpty) {
                    _showAlertMessage('Please enter your app name');
                    return;
                  }

                  final fileName = await _controller.getFilename(ev);
                  final fileBytes = await _controller.getFileData(ev);
                  _processFile(fileBytes, fileName);
                },
                onDropMultiple: (List<dynamic>? ev) async {
                  if (ev != null) {
                    for (var e in ev) {
                      if (_textController.text.trim().isEmpty) {
                        _showAlertMessage('Please enter your app name');
                        return;
                      }

                      final fileName = await _controller.getFilename(e);
                      final fileBytes = await _controller.getFileData(e);
                      _processFile(fileBytes, fileName);
                    }
                  }
                },
                onHover: () => setState(() => _dragging = true),
                onLeave: () => setState(() => _dragging = false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
