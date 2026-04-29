import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:medscan/screens/medicine_screen.dart';
import 'package:medscan/services/firestore_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessing = false;
  bool _hasFoundMatch = false;
  bool _isDataLoaded = false;

  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, String>> _medicineDataFromDB = [];

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {

    _firestoreService.getMedicines().listen(
      (snapshot) {

        if (mounted) {
          setState(() {
            _medicineDataFromDB = snapshot.docs.map((doc) {
              String dbName = doc.data()['name'].toString();

              return {
                'searchName': dbName.toLowerCase().trim(),
                'realName': doc.id,
              };
            }).toList();
            _isDataLoaded = true;
          });
          if (_controller == null) {
            _initializeCamera();
          }
        }
      },
      onError: (error) {
        print("FIRESTORE FOUT: $error");
      },
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      _controller!.startImageStream((CameraImage image) {
        if (!_isProcessing) {
          _isProcessing = true;
          _processImage(image);
        }
      });
      setState(() {});
    } catch (e) {
      print("Fout bij initialiseren camera: $e");
      return;
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_hasFoundMatch) return;

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImageMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation90deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      String gescandeTekst = recognizedText.text.toLowerCase().replaceAll(
        '\n',
        ' ',
      );

      if (gescandeTekst.trim().isNotEmpty) {
      }

      String matchedRealName = "";
      bool foundMatch = false;

      for (var med in _medicineDataFromDB) {
        String searchName = med['searchName']!;
        if (searchName.length > 3 && gescandeTekst.contains(searchName)) {
          foundMatch = true;
          matchedRealName = med['realName']!;
          break;
        }
      }

      if (foundMatch) {
        setState(() {
          _hasFoundMatch = true;
        });

        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => MedicineScreen(medicineName: matchedRealName),
          ),
        );

        return;
      }
    } catch (e) {
      print("Fout bij verwerken afbeelding: $e");
    }

    await Future.delayed(const Duration(seconds: 1));
    _isProcessing = false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        !_isDataLoaded) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double scannerWidth = screenWidth * 0.7;
    final double scannerHeight = scannerWidth * 0.6;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Scan Strip',
          style: TextStyle(color: CupertinoColors.white),
        ),
        backgroundColor: Color(0x00000000),
        border: null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize!.height,
              height: _controller!.value.previewSize!.width,
              child: CameraPreview(_controller!),
            ),
          ),

          ColorFiltered(
            colorFilter: ColorFilter.mode(
              CupertinoColors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: CupertinoColors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: scannerWidth,
                    height: scannerHeight,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: scannerWidth, height: scannerHeight),

                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Lijn de naam uit in het kader',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
