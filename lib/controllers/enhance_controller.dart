import 'dart:convert';
import 'dart:io';

import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:serious_python/serious_python.dart';

class EnhanceController extends GetxController {
  var originalImage = Rxn<File>();
  var enhancedImage = Rxn<File>();
  var isProcessing = false.obs;
  var isPythonReady = false.obs;
  var isAiPro = false.obs;
  var inputImage = Rxn<File>();

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    startPythonBackend();
  }

  Future<void> startPythonBackend() async {
    try {
      String appRoot = (await getApplicationDocumentsDirectory()).path;
      String pythonLibZip = "assets/python_lib.zip";
      
      SeriousPython.run(pythonLibZip, environmentVariables: {
        "SERIOUS_PYTHON_SITE_PACKAGES": "$appRoot/site-packages",
      });
      
      await Future.delayed(const Duration(seconds: 3));
      isPythonReady.value = true;
      print("Python backend started via SeriousPython");
    } catch (e) {
      print("Error starting Python: $e");
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      originalImage.value = File(pickedFile.path);
      enhancedImage.value = null; // Reset enhanced
    }
  }

  Future<void> enhanceImage() async {
    if (originalImage.value == null) return;
    isProcessing.value = true;
    try {
      await _enhanceWithLocalPython();
    } catch (e) {
      print("Enhance error: $e");
      Get.snackbar("Error", "Processing failed: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _enhanceWithLocalPython() async {
    final inputPath = originalImage.value!.path;
    final outputPath = "${(await getTemporaryDirectory()).path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final response = await http.post(
      Uri.parse("http://127.0.0.1:8080/enhance"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "input_path": inputPath,
        "output_path": outputPath,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      enhancedImage.value = File(outputPath);
    } else {
      throw "Server Error: ${response.statusCode}";
    }
  }

  Future<void> removeBackground() async {
    final inputFile = enhancedImage.value ?? originalImage.value;
    if (inputFile == null) return;

    final inputPath = inputFile.path;
    final outputPath = "${(await getTemporaryDirectory()).path}/no_bg_${DateTime.now().millisecondsSinceEpoch}.jpg";
    
    isProcessing.value = true;
    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8080/remove_bg"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "input_path": inputPath,
          "output_path": outputPath,
          "rect": null,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        enhancedImage.value = File(outputPath);
      } else {
        Get.snackbar("Error", "Offline BG Removal failed");
      }
    } catch (e) {
      Get.snackbar("Error", "Processing failed: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> manualAdjust({int brightness = 0, int contrast = 0, int saturation = 0}) async {
    final inputFile = enhancedImage.value ?? originalImage.value;
    if (inputFile == null) return;

    final inputPath = inputFile.path;
    final outputPath = "${(await getTemporaryDirectory()).path}/adj_${DateTime.now().millisecondsSinceEpoch}.jpg";
    
    isProcessing.value = true;
    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8080/adjust"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "input_path": inputPath,
          "output_path": outputPath,
          "brightness": brightness,
          "contrast": contrast,
          "saturation": saturation,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        enhancedImage.value = File(outputPath);
      }
    } catch (e) {
      Get.snackbar("Error", "Adjustment failed: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> saveToGallery() async {
    final file = enhancedImage.value ?? originalImage.value;
    if (file == null) return;
    
    isProcessing.value = true;
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) await Gal.requestAccess();
      await Gal.putImage(file.path);
      Get.snackbar("Success", "Image saved to Gallery!");
    } catch (e) {
      Get.snackbar("Error", "Failed to save: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> saveToDownloads() async {
    final file = enhancedImage.value ?? originalImage.value;
    if (file == null) return;

    isProcessing.value = true;
    try {
      Directory? downloadsDir;
      if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
          downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir != null && await downloadsDir.exists()) {
        final fileName = "Rimini_${DateTime.now().millisecondsSinceEpoch}.jpg";
        final savePath = "${downloadsDir.path}/$fileName";
        await file.copy(savePath);
        Get.snackbar("Success", "Saved to Downloads: $fileName");
      } else {
        throw "Could not access Downloads folder";
      }
    } catch (e) {
      Get.snackbar("Error", "Download failed: $e");
    } finally {
      isProcessing.value = false;
    }
  }
}
