// ignore_for_file: avoid_print, use_key_in_widget_constructors, prefer_const_constructors_in_immutables

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
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomePageScreen extends StatefulWidget {
  final String title;
  HomePageScreen({required this.title});

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

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  GlobalKey key = GlobalKey();
  final GlobalKey _key1 = GlobalKey();
  final GlobalKey _key2 = GlobalKey();
  final GlobalKey _key3 = GlobalKey();

  @override
  void initState() {
    super.initState();
    // config text speach
    tts.setLanguage('id');
    tts.setSpeechRate(0.4);

    // config quick tour
    initTargets();
    createTutorial();
    Future.delayed(const Duration(milliseconds: 100), () {
      showTutorial();
    });
    speakTutorial();

    // memuat model tflite
    loadModel();
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
        canUseGallery: false,
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
        title: Text(
          widget.title,
        ),
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
      floatingActionButton: FloatingActionButton.large(
        key: _key1,
        onPressed: getImageFromCamera, //
        child: const Icon(
          Icons.camera_alt_rounded,
          size: 60,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  // posisi target untuk memunculkan quik tour
  void initTargets() {
    targets.add(
      TargetFocus(
        identify: "Target 0",
        keyTarget: _key1,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Text(
                    "Langkah Pertama",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Tekan tombol kamera di pojok kanan bawah",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
        radius: 0.5,
      ),
    );

    targets.add(
      TargetFocus(
        identify: "Target 1",
        keyTarget: _key1,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Text(
                    "Langkah Kedua",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Setelah masuk kehalaman scan, tekan tombol di tengah bawah untuk scan uang",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
        enableOverlayTab: true,
        radius: 0.5,
      ),
    );
  }

  // inisialisasi quick tour
  void createTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.blue,
      hideSkip: true,
      textSkip: "SKIP",
      alignSkip: Alignment.topRight,
      paddingFocus: 10,
      opacityShadow: 0.9,
      onFinish: () {
        print("finish");
        tts.stop();
      },
      onClickTarget: (target) {
        print('onClickTarget: ${target.identify}');
        tts.pause();
        if (target.identify == 'Target 0') {
          tts.speak(
              '   Langkah kedua,    Setelah masuk kehalaman scan,   tekan tombol di tengah bawah untuk scan uang  ');
        }
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        print("target: $target");
        print(
            "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
      },
      onClickOverlay: (target) {
        print('onClickOverlay: ${target.identify.toString()}');
        tutorialCoachMark.next();
      },
      onSkip: () {
        print("skip");
      },
    );
  }

  // menjalankan fungsi quick tour
  void showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.blue,
      hideSkip: true,
      textSkip: "SKIP",
      alignSkip: Alignment.topRight,
      paddingFocus: 10,
      opacityShadow: 0.9,
      onFinish: () {
        print("finish");
      },
      onClickTarget: (target) {
        print('onClickTarget: ${target.identify}');

        // menambahkan suara ketika quick tour
        if (target.identify == 'Target 0') {
          tts.speak(
              '   Langkah kedua,    Setelah masuk kehalaman scan,   tekan tombol di tengah bawah untuk scan uang  ');
        }
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        print("target: $target");
        print(
            "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
      },
      onClickOverlay: (target) {
        print('onClickOverlay: $target');
      },
      onSkip: () {
        print("skip");
      },
    )..show(context: this.context);

    print('target show ${tutorialCoachMark.targets[0].identify}');
  }

  // menambahkan suara ketika quick tour
  void speakTutorial() {
    if (tutorialCoachMark.targets[0].identify == 'Target 0') {
      tts.speak(
          '   Langkah pertama,    Tekan tombol kamera di pojok kanan bawah  ');
    }
  }
}
