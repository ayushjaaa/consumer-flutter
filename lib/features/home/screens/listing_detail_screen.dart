import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onetap365app/data/services/storage_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/ad_model.dart';
import 'package:intl/intl.dart';

class ListingDetailScreen extends StatefulWidget {
  final Ad ad;

  const ListingDetailScreen({
    super.key,
    required this.ad,
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  int _selectedImageIndex = 0;
  bool _isFavorite = false;
  bool _phoneRevealed = false;

  String _formatPrice(String price) {
    final numPrice = double.tryParse(price) ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    );
    return formatter.format(numPrice);
  }

  String _getMemberSince() {
    if (widget.ad.createdAt != null) {
      return DateFormat('MMM yyyy').format(widget.ad.createdAt!);
    }
    return 'Recently';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Show dialog with phone number
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2e2e),
        title: Text(
          'Call Seller',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'Phone: $phoneNumber',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: const Color(0xFF22C55E)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a1e1e),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: const Color(0xFF0a1e1e),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // Implement share functionality
                  },
                ),
              ],
            ),

            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Image
                  _buildImageSection(),

                  // Product Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.ad.name,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Price
                        Text(
                          _formatPrice(widget.ad.sellingPrice),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Location
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white54,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.ad.city}, ${widget.ad.state}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Details Section
                        _buildDetailsSection(),
                        const SizedBox(height: 16),

                        // Seller Information
                        _buildSellerInformation(),
                        const SizedBox(height: 16),

                        // Action Buttons
                        _buildActionButtons(),
                        const SizedBox(height: 24),

                        // Product Highlights
                        if (widget.ad.description.isNotEmpty)
                          _buildProductHighlights(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final photos = widget.ad.photos.isNotEmpty
        ? widget.ad.photos
        : ['https://via.placeholder.com/400'];

    return Column(
      children: [
        // Main Image
        Container(
          height: 300,
          width: double.infinity,
          color: Colors.white,
          child: Image.network(
            photos[_selectedImageIndex],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported, size: 50),
              );
            },
          ),
        ),

        // Thumbnail Carousel
        if (photos.length > 1)
          Container(
            height: 80,
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedImageIndex == index
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        photos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.image, size: 20),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2e2e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Category', widget.ad.categoryName ?? 'N/A'),
          const SizedBox(height: 12),
          _buildDetailRow('Type', widget.ad.subcategoryName ?? 'N/A'),
          const SizedBox(height: 12),
          _buildDetailRow('Condition',
              widget.ad.itemType == 'RENT' ? 'For Rent' : 'For Sale'),
          const SizedBox(height: 12),
          _buildDetailRow('City', widget.ad.city),
          if (widget.ad.pincode.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Pincode', widget.ad.pincode),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.ad.contactPhone != null) {
                _makePhoneCall(widget.ad.contactPhone!);
              }
            },
            icon: const Icon(Icons.phone, color: Colors.white),
            label: Text(
              'Call Seller',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Implement chat functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat feature coming soon')),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            label: Text(
              'Chat',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductHighlights() {
    // Parse description into bullet points if it contains newlines or dashes
    final description = widget.ad.description;
    final highlights = description.contains('\n')
        ? description
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList()
        : [description];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product highlights:',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...highlights.map((highlight) {
          final text = highlight.trim();
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '- ',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Expanded(
                  child: Text(
                    text.startsWith('-') ? text.substring(1).trim() : text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSellerInformation() {
    final userName = widget.ad.contactName ?? 'Seller';
    final phone =
        (widget.ad.contactPhone != null && widget.ad.contactPhone!.isNotEmpty)
            ? widget.ad.contactPhone!
            : '';
    final maskedPhone = _phoneRevealed
        ? (phone.isNotEmpty ? phone : 'Not available')
        : (phone.isNotEmpty
            ? (phone.length > 4
                ? '${phone.substring(0, phone.length - 4)}XXXX'
                : 'XXXXXXXXXX')
            : 'Not available');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a2e2e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller Information',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Member since ${_getMemberSince()}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0a1e1e),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.phone, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    maskedPhone,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_phoneRevealed && phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final loggedIn = await StorageService.isLoggedIn();
                if (loggedIn) {
                  setState(() {
                    _phoneRevealed = true;
                  });
                } else {
                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1a2e2e),
                      title: Text('Login Required',
                          style: GoogleFonts.inter(color: Colors.white)),
                      content: Text(
                          'Please log in to reveal the seller\'s phone number.',
                          style: GoogleFonts.inter(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close',
                              style:
                                  GoogleFonts.inter(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text(
                'Click to reveal phone number',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
