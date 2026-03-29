import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onetap365app/data/repositories/auth_repository.dart';

class KYCScreen extends StatefulWidget {
  const KYCScreen({Key? key}) : super(key: key);

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  int currentStep = 0; // 0: Aadhar Front, 1: Aadhar Back, 2: Verified
  XFile? aadharFrontImage;
  XFile? aadharBackImage;
  final TextEditingController _aadharNumberController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  bool _isSubmitting = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  setState(() {
                    currentStep--;
                  });
                },
              )
            : null,
      ),
      body: currentStep == 2 ? _buildVerifiedScreen() : _buildAadharScreen(),
    );
  }

  Widget _buildAadharScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Progress Bar
            _buildProgressBar(),
            const SizedBox(height: 40),
            // Title
            Text(
              currentStep == 0 ? 'Aadhar Card (Front)' : 'Aadhar Card (Back)',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              currentStep == 0
                  ? 'Please upload your Aadhar card below for completing your first step of KYC.'
                  : 'Please upload your Aadhar card below for completing your first step of KYC.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            // Input Field (for front)
            if (currentStep == 0) ...[
              _buildInputField('Aadhar Card Number'),
              const SizedBox(height: 40),
            ],
            // Upload Area
            _buildUploadArea(
              currentStep == 0
                  ? 'Upload aadhar card front photo'
                  : 'Upload your aadhar card back',
            ),
            const SizedBox(height: 40),
            // Consent Checkbox (for back)
            if (currentStep == 1) ...[
              _buildConsentCheckbox(),
              const SizedBox(height: 30),
            ],
            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: 20),
            // Help Text
            Text(
              'If you are facing any difficulties, please get in touch\nwith us on Whatsapp',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        // Step 1
        Expanded(
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentStep >= 0 ? Colors.green : Colors.grey[300],
                ),
                child: Center(
                  child: currentStep > 0
                      ? const Icon(Icons.check, color: Colors.white, size: 28)
                      : const Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aadhar\nFront',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        // Line between step 1 and 2
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 3,
                color: currentStep >= 1 ? Colors.green : Colors.grey[300],
              ),
            ],
          ),
        ),
        // Step 2
        Expanded(
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentStep >= 1 ? Colors.green : Colors.grey[300],
                ),
                child: Center(
                  child: currentStep > 1
                      ? const Icon(Icons.check, color: Colors.white, size: 28)
                      : Text(
                          '2',
                          style: TextStyle(
                            color: currentStep >= 1
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aadhar\nBack',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        // Line between step 2 and 3
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 3,
                color: currentStep >= 2 ? Colors.green : Colors.grey[300],
              ),
            ],
          ),
        ),
        // Step 3
        Expanded(
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: currentStep >= 2 ? Colors.green : Colors.grey[300],
                ),
                child: Center(
                  child: currentStep > 2
                      ? const Icon(Icons.check, color: Colors.white, size: 28)
                      : Text(
                          '3',
                          style: TextStyle(
                            color: currentStep >= 2
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verified',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _aadharNumberController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(bool isFront) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          if (isFront) {
            aadharFrontImage = pickedFile;
          } else {
            aadharBackImage = pickedFile;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _handleFrontUpload() async {
    final aadhaar = _aadharNumberController.text.trim();
    if (aadhaar.isEmpty || aadhaar.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 12 digit Aadhaar number')),
      );
      return;
    }
    if (aadharFrontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload Aadhaar front image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _authRepository.uploadAadhaarFront(
        imageFile: File(aadharFrontImage!.path),
        aadhaarNumber: aadhaar,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          currentStep = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Front uploaded')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Upload failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleBackUpload() async {
    if (aadharBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload Aadhaar back image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _authRepository.uploadAadhaarBack(
        imageFile: File(aadharBackImage!.path),
      );

      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          currentStep = 2;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Back uploaded')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Upload failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildUploadArea(String label) {
    final isImageSelected =
        currentStep == 0 ? aadharFrontImage != null : aadharBackImage != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isImageSelected
          ? Column(
              children: [
                const Icon(Icons.check_circle, size: 50, color: Colors.green),
                const SizedBox(height: 12),
                Text(
                  'Image selected successfully',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.green),
                ),
              ],
            )
          : Column(
              children: [
                Icon(Icons.cloud_upload_outlined,
                    size: 40, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _pickImage(currentStep == 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Upload +'),
                ),
              ],
            ),
    );
  }

  Widget _buildConsentCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: true,
          onChanged: (value) {},
        ),
        Expanded(
          child: Text(
            'I hereby agree that the above document belongs to me and voluntarily give my consent to OneTap365 to utilize it as my identity proof for KYC purpose only',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting
            ? null
            : currentStep == 2
                ? null
                : () async {
                    if (currentStep == 0) {
                      await _handleFrontUpload();
                    } else if (currentStep == 1) {
                      await _handleBackUpload();
                    }
                  },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                currentStep == 2 ? 'Verified' : 'Submit',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildVerifiedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 60),
          ),
          const SizedBox(height: 30),
          const Text(
            'KYC Completed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Thanks for submitting your document we\'ll verify it and complete your KYC as soon as possible',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate back to home
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/main', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Back to home',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _aadharNumberController.dispose();
    super.dispose();
  }
}
