# Ad Posting Implementation Guide

## Overview
This implementation integrates the **POST /api/create-item** endpoint with your Flutter app to post ads and display them in the trending section.

## ✅ Completed Implementation

### 1. **Ad Model** (`lib/data/models/ad_model.dart`)
- Handles all ad data fields matching your API
- Supports both RENT and SELL item types
- Parses photos from various formats (array, comma-separated string)
- Fields: item_type, cat_id, subcat_id, name, description, mrp, selling_price, discount, review, city, state, pincode, photos

### 2. **Ads Repository** (`lib/data/repositories/ads_repository.dart`)
- **`createAd()`** - Posts ad to `/api/create-item` with multipart/form-data
- **`getTrendingAds()`** - Fetches trending ads from `/api/trending-ads`
- **`getAds()`** - Fetches all ads from `/api/ads`
- Automatically handles Bearer token authentication

### 3. **Ads Provider** (`lib/providers/ads_provider.dart`)
- State management for ads
- **`postAd()`** - Submits ad to backend
- **`fetchTrendingAds()`** - Loads trending ads for home screen
- **`updatePostAdData()`** - Collects ad data through multi-step flow
- **`addPhotos()`** / **`removePhoto()`** - Manages photo uploads

### 4. **API Service** (`lib/data/services/api_service.dart`)
- **`createAd()`** - Sends multipart form data with photos
- **`getTrendingAds()`** - Fetches trending ads
- Uses Bearer token from storage automatically

### 5. **Home Screen** (`lib/features/home/screens/home_screen.dart`)
- Fetches trending ads on load
- Displays ads from backend in trending section
- Shows loading/error states
- Displays:
  - Ad images (first photo)
  - Ad name/title
  - Price (with /mo for RENT type)
  - Location (city, state)
  - Time ago
  - Badges (TRENDING, HOT DEAL, VERIFIED)

### 6. **Contact Details Screen** (Updated)
- Collects final ad information
- Integrates with AdsProvider
- **`_handlePostAd()`** - Submits complete ad to backend
- Shows loading dialog during submission
- Navigates to success screen on completion
- Updated constructor to accept all ad data

---

## 🔧 Configuration Required

### API Endpoints (Already Added)
```dart
// lib/core/constants/api_constants.dart
static const String createItem = '/create-item';
static const String getAds = '/ads';
static const String getTrendingAds = '/trending-ads';
```

### Provider Registration (Already Done)
```dart
// lib/main.dart
ChangeNotifierProvider(create: (_) => AdsProvider()),
```

---

## 📋 Post Ad Flow Integration (Needs Update)

### Current Flow Issues:
The post ad screens need to be updated to pass data through the complete flow:

**Current Flow:**
```
PostAdTypeScreen → SelectCategoryScreen → AddDetailsScreen → UploadPhotosScreen → ContactDetailsScreen
```

### Required Updates:

#### 1. **PostAdTypeScreen** ✅ (No changes needed)
- User selects SELL or RENT

#### 2. **SelectCategoryScreen** (Needs Update)
```dart
// Update to accept selected type and pass category ID
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AddDetailsScreen(
      type: widget.type,  // "SELL" or "RENT"
      categoryId: selectedCategoryId,  // Category ID from backend
      categoryName: selectedCategoryName,
    ),
  ),
);
```

#### 3. **AddDetailsScreen** (Needs Update)
```dart
// Update constructor to receive and pass forward
class AddDetailsScreen extends StatefulWidget {
  final String type;
  final int categoryId;
  final String categoryName;
  
  // Update navigation to UploadPhotosScreen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => UploadPhotosScreen(
        type: widget.type,
        categoryId: widget.categoryId,
        categoryName: widget.categoryName,
        subcategoryId: selectedSubcategoryId,
        title: _titleController.text,
        description: _descriptionController.text,
        price: _priceController.text,
        mrp: _mrpController.text,
        discount: _discountController.text,
      ),
    ),
  );
}
```

#### 4. **UploadPhotosScreen** (Needs Update)
```dart
// Add photos to provider before navigation
import 'package:provider/provider.dart';
import '../../../../providers/ads_provider.dart';

// In onPressed:
final adsProvider = context.read<AdsProvider>();
adsProvider.addPhotos(_selectedImages);

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ContactDetailsScreen(
      type: widget.type,
      categoryId: widget.categoryId,
      categoryName: widget.categoryName,
      subcategoryId: widget.subcategoryId,
      title: widget.title,
      description: widget.description,
      price: widget.price,
      mrp: widget.mrp,
      discount: widget.discount,
    ),
  ),
);
```

#### 5. **ContactDetailsScreen** ✅ (Already Updated)
- Receives all ad data
- Submits to backend via provider
- Shows success/error states

---

## 🚀 How It Works

### Posting an Ad:

1. User navigates through post ad flow
2. Each screen collects specific data
3. UploadPhotosScreen adds photos to provider
4. ContactDetailsScreen calls `adsProvider.postAd()`
5. Provider sends multipart request with all data:
   ```dart
   FormData:
   - item_type: "RENT" or "SELL"
   - cat_id: category ID
   - subcat_id: subcategory ID (optional)
   - name: ad title
   - description: ad description
   - mrp: original price
   - selling_price: selling/rent price
   - discount: discount amount
   - review: rating (optional)
   - city: city name
   - state: state name
   - pincode: postal code
   - photos: multiple files
   - contact_name, contact_phone, contact_email, website (optional)
   ```

6. Backend returns success response
7. App shows success screen
8. Home screen trending section updates

### Viewing Ads:

1. HomeScreen calls `adsProvider.fetchTrendingAds()` on load
2. Provider fetches from `/api/trending-ads`
3. Ads displayed in trending section with:
   - First photo from photos array
   - Name, price, location
   - Badge based on is_trending, is_hot_deal, is_verified
   - Time ago from created_at

---

## 🔍 Backend Response Format

### Expected Success Response:
```json
{
  "success": true,
  "message": "Ad posted successfully",
  "data": {
    "id": 123,
    "item_type": "RENT",
    "cat_id": 1,
    "name": "Samsung AC",
    "selling_price": "9500",
    "city": "Bangalore",
    "state": "Karnataka",
    "photos": ["url1", "url2"],
    "created_at": "2026-01-24T10:30:00Z"
  }
}
```

### Trending Ads Response:
```json
{
  "data": [
    {
      "id": 1,
      "name": "iPhone 15 Pro",
      "selling_price": "145000",
      "city": "Mumbai",
      "state": "Maharashtra",
      "photos": ["https://..."],
      "is_trending": true,
      "created_at": "2026-01-24T09:00:00Z"
    }
  ]
}
```

Or direct array:
```json
[
  {"id": 1, "name": "..."},
  {"id": 2, "name": "..."}
]
```

Both formats are supported!

---

## 🎯 Next Steps

### To Complete Integration:

1. **Update SelectCategoryScreen**:
   - Fetch categories from backend (already implemented)
   - Pass category ID (not name) to next screen
   
2. **Update AddDetailsScreen**:
   - Accept categoryId parameter
   - Pass all collected data to UploadPhotosScreen

3. **Update UploadPhotosScreen**:
   - Add photos to AdsProvider before navigation
   - Pass all data to ContactDetailsScreen

4. **Test the Flow**:
   ```bash
   flutter run
   ```
   - Post a test ad
   - Verify it appears in trending section
   - Check Bearer token is sent in headers

---

## 📝 Example Usage

### Posting an Ad:
```dart
final adsProvider = context.read<AdsProvider>();

// Collect data through screens
adsProvider.updatePostAdData({
  'item_type': 'RENT',
  'cat_id': 1,
  'name': 'Samsung AC',
  'description': 'Like new condition',
  'mrp': '12000',
  'selling_price': '9500',
  'discount': '2500',
  'city': 'Bangalore',
  'state': 'Karnataka',
  'pincode': '560001',
});

// Add photos
adsProvider.addPhotos([File('path/to/photo1.jpg')]);

// Submit
bool success = await adsProvider.postAd();
```

### Fetching Trending Ads:
```dart
final adsProvider = context.read<AdsProvider>();
await adsProvider.fetchTrendingAds(limit: 10);

// Access ads
List<Ad> trending = adsProvider.trendingAds;
```

---

## ✅ Summary

**Completed:**
- ✅ Ad model with all fields
- ✅ Ads repository with create/fetch methods
- ✅ Ads provider for state management
- ✅ API service integration
- ✅ Home screen trending section
- ✅ Contact details screen submission
- ✅ Bearer token authentication
- ✅ Multi-format response parsing

**Pending:**
- ⏳ Update SelectCategoryScreen to pass category ID
- ⏳ Update AddDetailsScreen parameters
- ⏳ Update UploadPhotosScreen to use provider

Once the flow screens are updated to pass data correctly, ads will post successfully and appear in the trending section!
