import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_compare_slider/image_compare_slider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'editor_screen.dart';
import '../controllers/enhance_controller.dart';

class HomeScreen extends StatelessWidget {
  final EnhanceController controller = Get.put(EnhanceController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          "RIMINI ENHANCE",
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (controller.originalImage.value == null)
                  _buildEmptyState()
                else
                  _buildImagePreview(),
                const SizedBox(height: 40),
                _buildActions(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 64, color: Colors.blueAccent),
          const SizedBox(height: 16),
          Text(
            "Select an image to enhance",
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: controller.enhancedImage.value != null
              ? ImageCompareSlider(
                  itemOne: Image.file(controller.originalImage.value!, fit: BoxFit.cover),
                  itemTwo: Image.file(controller.enhancedImage.value!, fit: BoxFit.cover),
                  dividerColor: Colors.white,
                  handleColor: Colors.blueAccent,
                )
              : Image.file(controller.originalImage.value!, fit: BoxFit.cover),
        ),
        const SizedBox(height: 16),
        Text(
          controller.enhancedImage.value != null ? "Visual comparison (Before/After)" : "Original Preview",
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (controller.originalImage.value == null)
          GestureDetector(
            onTap: () => controller.pickImage(ImageSource.gallery),
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: Text(
                  "PICK FROM GALLERY",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              GestureDetector(
                onTap: controller.isProcessing.value ? null : controller.enhanceImage,
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: controller.isProcessing.value ? Colors.grey[800] : const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Center(
                    child: controller.isProcessing.value
                        ? const SpinKitThreeBounce(color: Colors.white, size: 24)
                        : Text(
                            "ENHANCE IMAGE",
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Get.to(() => EditorScreen()),
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit, color: Colors.blueAccent),
                        const SizedBox(width: 10),
                        Text(
                          "EDIT PRO",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => controller.pickImage(ImageSource.gallery),
                child: const Text("Replace Image", style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
      ],
    );
  }
}
