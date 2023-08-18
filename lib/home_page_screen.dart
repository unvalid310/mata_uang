// ignore_for_file: avoid_print

import 'dart:io';

import 'package:edge_detection/edge_detection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mata_uang/classifier/classifier.dart';
import 'package:mata_uang/string_util.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePageScreen> createState() => _MyHomePageState();
}

enum _ResultStatus {
  notStarted,
  notFound,
  found,
}

class _MyHomePageState extends State<HomePageScreen> {
  String? _imagePath;
  String? _nominalLabel;
  Classifier? _classifier;

  final _ResultStatus _resultStatus = _ResultStatus.notStarted;

  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    loadModel();
    tts.setLanguage('id');
    tts.setSpeechRate(0.4);
  }

  // load model data set
  loadModel() async {
    final classifier = await Classifier.loadWith(
      labelsFileName: 'assets/labels.txt',
      modelFileName: 'model_unquant.tflite',
    );

    setState(() {
      _classifier = classifier;
    });
  }

  // Proses scaning foto uang
  Future<void> getImageFromCamera() async {
    bool isCameraGranted = await Permission.camera.request().isGranted;
    if (!isCameraGranted) {
      isCameraGranted =
          await Permission.camera.request() == PermissionStatus.granted;
    }

    if (!isCameraGranted) {
      return;
    }

    // Generate filepath untuk menyimpan foto sementara
    String imagePath = join((await getApplicationSupportDirectory()).path,
        "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.jpeg");

    try {
      //Proses crop dan menentukan bidang yang disimpan
      bool success = await EdgeDetection.detectEdge(
        imagePath,
        canUseGallery: true,
        androidScanTitle: 'Scanning',
        androidCropTitle: 'Crop',
        androidCropBlackWhiteTitle: 'Black White',
        androidCropReset: 'Reset',
      );
      print("success: $success");
    } catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      _imagePath = imagePath;
    });

    // Klasifikasi gambar berdasarkan foto
    _analyzeImage(File(_imagePath!));
  }

  // Klasifikasi foto
  void _analyzeImage(File image) async {
    final imageInput = img.decodeImage(image.readAsBytesSync())!;

    final resultCategory = _classifier?.predict(imageInput);

    // hasil klasifikasi lebih dari 50%
    final result = resultCategory!.score >= 0.5
        ? _ResultStatus.found
        : _ResultStatus.notFound;
    final label = resultCategory.label;

    String nominal = await translate(label);

    setState(() {
      _nominalLabel = label;
    });

    // conversi nominal ke suara
    tts.speak(nominal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              (_imagePath != null)
                  ? Visibility(
                      visible: _imagePath != null,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(
                          File(_imagePath ?? ''),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset('assets/image_placeholder.png'),
                    ),
              const SizedBox(height: 20),
              const Text(
                'Nominal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                (_nominalLabel != null) ? convertToIdr(_nominalLabel!, 2) : '',
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              (_nominalLabel != null)
                  ? ElevatedButton(
                      onPressed: () async {
                        tts.speak(await translate(_nominalLabel!));
                      },
                      child: const Icon(Icons.volume_up_rounded),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImageFromCamera, //
        child: const Icon(Icons.camera_alt_rounded),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
