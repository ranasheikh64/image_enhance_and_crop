import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_cropper/image_cropper.dart';
import '../controllers/enhance_controller.dart';

class EditorScreen extends StatelessWidget {
  final EnhanceController controller = Get.find();

  EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Pro Editor",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.blueAccent),
              onPressed: () => _onExport(),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.greenAccent),
              onPressed: () => Get.back(),
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Obx(() {
                        final img =
                            controller.enhancedImage.value ??
                            controller.originalImage.value;
                        if (img == null)
                          return const Text(
                            "No image selected",
                            style: TextStyle(color: Colors.white),
                          );
                        return Hero(
                          tag: "image",
                          child: InteractiveViewer(
                            child: Image.file(
                              img,
                              key: ValueKey(img.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  _buildToolbar(),
                ],
              ),
            ),
            Obx(
              () => controller.isProcessing.value
                  ? Container(
                      color: Colors.black45,
                      child: const Center(
                        child: SpinKitFadingCircle(
                          color: Colors.blueAccent,
                          size: 50,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomTools(),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolButton(Icons.crop, "Crop", () => _onCrop()),
          _toolButton(Icons.layers_clear, "Remove BG", () => _onRemoveBg()),
          _toolButton(
            Icons.photo_size_select_large,
            "Resize",
            () => _onResize(),
          ),
          _toolButton(Icons.tune, "Adjust", () => _onAdjust()),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTools() {
    return SafeArea(
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PRO TOOLS",
                  style: GoogleFonts.outfit(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  "Manual adjustments active",
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("SAVE CHANGES"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onCrop() async {
    final file =
        controller.enhancedImage.value ?? controller.originalImage.value;
    if (file == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: const Color(0xFF6366F1),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
            PassportUSPreset(),
            PassportEUPreset(),
          ],
        ),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
            PassportUSPreset(),
            PassportEUPreset(),
          ],
        ),
      ],
    );

    if (croppedFile != null) {
      controller.enhancedImage.value = File(croppedFile.path);
    }
  }

  void _onRemoveBg() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Remove Background",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _actionTile(
              Icons.brush,
              "Remove Background",
              "Precise offline background removal",
              Colors.blueAccent,
              () {
                Get.back();
                controller.removeBackground();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String sub,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      onTap: onTap,
    );
  }

  void _onResize() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Standard Sizes",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sizePreset("Passport (2x2)", "US Passport"),
                _sizePreset("Passport (35x45)", "EU/BD Passport"),
                _sizePreset("A4", "Standard Print"),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sizePreset(String label, String sub) {
    return InkWell(
      onTap: () {
        Get.back();
        // Implement resizing logic
        Get.snackbar("AIPRO", "Resizing to $label...");
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.aspect_ratio, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  void _onAdjust() {
    double brightness = 0;
    double contrast = 0;
    double saturation = 0;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Manual Adjustments",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _sliderRow(
                  "Brightness",
                  brightness,
                  -100,
                  100,
                  (val) => setState(() => brightness = val),
                ),
                _sliderRow(
                  "Contrast",
                  contrast,
                  -100,
                  100,
                  (val) => setState(() => contrast = val),
                ),
                _sliderRow(
                  "Saturation",
                  saturation,
                  -100,
                  100,
                  (val) => setState(() => saturation = val),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      controller.manualAdjust(
                        brightness: brightness.toInt(),
                        contrast: contrast.toInt(),
                        saturation: saturation.toInt(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text("APPLY ADJUSTMENTS"),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onExport() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Export Image",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _actionTile(
              Icons.photo_library,
              "Save to Gallery",
              "Add to your phone's photo library",
              Colors.orangeAccent,
              () {
                Get.back();
                controller.saveToGallery();
              },
            ),
            _actionTile(
              Icons.folder_copy,
              "Download Folder",
              "Save to system downloads folder",
              Colors.greenAccent,
              () {
                Get.back();
                controller.saveToDownloads();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              value.toInt().toString(),
              style: const TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
          inactiveColor: Colors.white12,
        ),
      ],
    );
  }
}

class PassportUSPreset implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (600, 600); // 2x2 inch
  @override
  String get name => 'US Passport (2x2")';
}

class PassportEUPreset implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (35, 45); // 35x45 mm
  @override
  String get name => 'EU/BD Passport (35x45mm)';
}
