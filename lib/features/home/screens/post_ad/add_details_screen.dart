// ...existing code...
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import '../../../../providers/ads_provider.dart';
import '../../../../core/constants/api_constants.dart';
import 'contact_details_screen.dart';
import 'map_picker_screen.dart';
import '../../widgets/continue_button.dart';

class AddDetailsScreen extends StatefulWidget {
  final String type;
  final int categoryId;
  final String categoryName;
  const AddDetailsScreen({
    Key? key,
    required this.type,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<AddDetailsScreen> createState() => _AddDetailsScreenState();
}

class _AddDetailsScreenState extends State<AddDetailsScreen> {
  Future<void> _fetchLocationFromPincode(String pincode) async {
    if (pincode.length < 5) return;
    try {
      final response = await http
          .get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffice = data[0]['PostOffice'][0];
          setState(() {
            _cityController.text = postOffice['District'] ?? '';
            selectedState = postOffice['State'] ?? '';
            _addressController.text = postOffice['Name'] ?? '';
          });
        }
      }
    } catch (e) {
      // Optionally show error or ignore
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _addressController = TextEditingController();
  String? selectedState;

  List<Map<String, dynamic>> _subCategories = [];
  Map<String, dynamic>? selectedSubCategory;
  bool _isLoadingSubCategories = true;
  String? _subCategoryError;

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
  }

  Future<void> _fetchSubCategories() async {
    try {
      setState(() {
        _isLoadingSubCategories = true;
        _subCategoryError = null;
      });

      final String baseUrl = ApiConstants.baseUrl;
      final response = await http
          .get(Uri.parse('$baseUrl/category/?cat_id=${widget.categoryId}'));
      log('Subcategory API response: ' + response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Use 'data' key for subcategories
        final subcats = List<Map<String, dynamic>>.from(data['data'] ?? []);
        log('Parsed subcategories: ' + subcats.toString());
        setState(() {
          _subCategories = subcats;
          _isLoadingSubCategories = false;
        });
      } else {
        setState(() {
          _subCategoryError = 'Failed to fetch subcategories';
          _isLoadingSubCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _subCategoryError = e.toString();
        _isLoadingSubCategories = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AddDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      setState(() {
        selectedSubCategory = null;
        _subCategories = [];
      });
      _fetchSubCategories();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
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
          _buildProgressBar(3, 4),
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
                      'Add Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.categoryName} (${widget.type}) - Add more features',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildLabel('TITLE*'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _titleController,
                      hintText: 'eg. iPhone 15 Pro (256GB)',
                      onChanged: (value) {
                        // Handle onChanged logic if needed
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Sub-Category'),
                    const SizedBox(height: 8),
                    _buildSubCategoryDropdown(),
                    const SizedBox(height: 20),
                    _buildLabel('DESCRIPTION'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _descriptionController,
                      hintText: 'Include the item\'s detail',
                      maxLines: 5,
                      onChanged: (value) {
                        // Handle onChanged logic if needed
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('PRICE*'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _priceController,
                      hintText: 'eg. 45,000',
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        // Handle onChanged logic if needed
                      },
                    ),
                    const SizedBox(height: 32),

                    // --- Location Section ---
                    _buildLabel('STATE*'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1A14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1a2e2e)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedState,
                          hint: const Text(
                            'Select State',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 14),
                          ),
                          dropdownColor: const Color(0xFF0B1A14),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white54),
                          items: [
                            'Maharashtra',
                            'Karnataka',
                            'Tamil Nadu',
                            'Delhi',
                            'Gujarat',
                            'Rajasthan'
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedState = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CITY*'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _cityController,
                                hintText: 'eg. Mumbai',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('PINCODE'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _pincodeController,
                                hintText: 'eg. 698875',
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  if (value.length >= 5) {
                                    _fetchLocationFromPincode(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('ADDRESS/LANDMARK'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _addressController,
                      hintText: 'eg. Near Railway Station',
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.map),
                        label: const Text('Choose from Map'),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapPickerScreen(),
                            ),
                          );
                          if (result != null && result is Map) {
                            setState(() {
                              _addressController.text = result['address'] ?? '';
                              // Try to parse city, state, pincode from address string if possible
                              final address = result['address'] ?? '';
                              final parts = address
                                  .split(',')
                                  .map((e) => e.trim())
                                  .toList();
                              if (parts.length >= 4) {
                                _cityController.text = parts[parts.length - 3];
                                selectedState = parts[parts.length - 2];
                                _pincodeController.text = parts.last;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Photo Upload Section ---
                    // (Removed from here, now in ContactDetailsScreen)

                    const SizedBox(height: 32),
                    // --- End Photo Upload Section ---

                    ContinueButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Save data to provider
                          final adsProvider = context.read<AdsProvider>();

                          adsProvider.updatePostAdData({
                            'item_type': widget.type,
                            'cat_id': widget.categoryId,
                            'subcat_id': selectedSubCategory?['id'],
                            'name': _titleController.text.trim(),
                            'description': _descriptionController.text.trim(),
                            'selling_price': _priceController.text.trim(),
                            'city': _cityController.text.trim(),
                            'state': selectedState ?? '',
                            'pincode': _pincodeController.text.trim(),
                            'address': _addressController.text.trim(),
                          });

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactDetailsScreen(
                                type: widget.type,
                                categoryId: widget.categoryId,
                                categoryName: widget.categoryName,
                                subcategoryId: selectedSubCategory?['id'],
                              ),
                            ),
                          );
                        }
                      },
                      text: 'Next',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF0B1A14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1a2e2e)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1a2e2e)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF22C55E)),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: (value) {
        if (hintText.contains('*') && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }

  Widget _buildSubCategoryDropdown() {
    if (_isLoadingSubCategories) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_subCategoryError != null) {
      return Text(_subCategoryError!,
          style: const TextStyle(color: Colors.red));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1a2e2e)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          isExpanded: true,
          value: selectedSubCategory,
          hint: const Text(
            'Select Sub-Category',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          dropdownColor: const Color(0xFF0B1A14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          items: _subCategories.map((subCat) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: subCat,
              child: Text(
                subCat['name'] ?? '',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (Map<String, dynamic>? newValue) {
            setState(() {
              selectedSubCategory = newValue;
            });
          },
        ),
      ),
    );
  }
}
