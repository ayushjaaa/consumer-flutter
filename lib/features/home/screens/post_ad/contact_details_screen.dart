import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onetap365app/core/constants/api_constants.dart';
import 'package:onetap365app/data/services/storage_service.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/ads_provider.dart';
import 'ad_success_screen.dart';
import '../../widgets/continue_button.dart';
import 'package:http/http.dart' as http;

class ContactDetailsScreen extends StatefulWidget {
  final String type;
  final int categoryId;
  final String categoryName;
  final int? subcategoryId;
  final String? title;
  final String? description;
  final String? price;
  final String? mrp;
  final String? discount;

  const ContactDetailsScreen({
    Key? key,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    this.subcategoryId,
    this.title,
    this.description,
    this.price,
    this.mrp,
    this.discount,
  }) : super(key: key);

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  // Photo upload logic
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    // ...existing code...
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E221A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post an Ad',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(4, 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Contact Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // --- Photo Upload Section ---
                    const Text(
                      'Upload Photos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add cover photos to get more responses',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1A14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF1a2e2e),
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1a2e2e),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: Color(0xFF22C55E),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Click to upload photos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    ContinueButton(
                      onPressed: () => _handlePostAd(context),
                      text: 'Post Ad',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int currentStep, int totalSteps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: index < currentStep
                    ? AppColors.primary
                    : const Color(0xFF1a2e2e),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ...existing code...

  Future<void> _handlePostAd(BuildContext context) async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one photo.')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF22C55E)),
      ),
    );

    try {
      final adsProvider = context.read<AdsProvider>();
      final postAdData = adsProvider.postAdData;
      final String baseUrl = ApiConstants.baseUrl;
      final url = Uri.parse('$baseUrl/create-item');

      // Get token from storage
      final token = await StorageService.getToken();

      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Build fields - only include non-empty values to match backend requirements
      final Map<String, String> fields = {};

      // Required fields
      final itemType =
          (postAdData['item_type'] ?? widget.type).toString().toUpperCase();
      fields['item_type'] = itemType;
      fields['cat_id'] = (postAdData['cat_id'] ?? widget.categoryId).toString();
      fields['name'] = (postAdData['name'] ?? widget.title ?? '').toString();
      fields['description'] =
          (postAdData['description'] ?? widget.description ?? '').toString();
      fields['city'] = (postAdData['city'] ?? '').toString();
      fields['state'] = (postAdData['state'] ?? '').toString();
      fields['pincode'] = (postAdData['pincode'] ?? '').toString();

      // Price fields - ensure they're not empty/zero
      final String mrp =
          (postAdData['mrp'] ?? widget.mrp ?? widget.price ?? '0').toString();
      final String sellingPrice =
          (postAdData['selling_price'] ?? widget.price ?? '0').toString();

      fields['mrp'] = mrp;
      fields['selling_price'] = sellingPrice;

      // Optional fields - only add if they have valid values
      if (postAdData['subcat_id'] != null &&
          postAdData['subcat_id'].toString().isNotEmpty &&
          postAdData['subcat_id'].toString() != '0') {
        fields['subcat_id'] = postAdData['subcat_id'].toString();
      } else if (widget.subcategoryId != null && widget.subcategoryId! > 0) {
        fields['subcat_id'] = widget.subcategoryId.toString();
      }

      final discount =
          (postAdData['discount'] ?? widget.discount ?? '').toString();
      if (discount.isNotEmpty && discount != '0') {
        fields['discount'] = discount;
      }

      final review = (postAdData['review'] ?? '').toString();
      if (review.isNotEmpty && review != '0') {
        fields['review'] = review;
      }

      final address = (postAdData['address'] ?? '').toString();
      if (address.isNotEmpty) {
        fields['address'] = address;
      }

      // Add all fields to request
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      print('🔗 POST(CREATE AD) URL: $url');
      print('📤 Fields: $fields');
      print('📤 Photos: ${_selectedImages.length} files');

      // Add photos
      for (var image in _selectedImages) {
        request.files
            .add(await http.MultipartFile.fromPath('photos', image.path));
      }

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw TimeoutException(
            'Upload timed out after 300 seconds. The backend may be slow or the file may be too large.',
          );
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success - clear data and navigate to success screen
        adsProvider.clearPostAdData();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AdSuccessScreen()),
          (route) => route.isFirst,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to post ad. Status: ${response.statusCode}. ${response.body}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on TimeoutException catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload timeout: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      print('❌ Post Ad Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.clear();
          _selectedImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
}
