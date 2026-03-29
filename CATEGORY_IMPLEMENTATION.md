# Category Management Implementation - Backend API Integration

## Overview
Categories in the OneTap365 app are now **fetched from the backend API** and are **NOT created locally**. The Admin creates and manages all categories in the backend database, and the mobile app displays them dynamically.

---

## Implementation Details

### 1. **API Configuration**

**Endpoint**: `GET /api/all-categories`  
**Authentication**: Bearer Token required

File: `lib/core/constants/api_constants.dart`
```dart
static const String allCategories = '/all-categories';
```

### 2. **Category Model**

File: `lib/data/models/category_model.dart`

The model handles various response formats from the backend:
- `id` or `category_id`
- `name` or `category_name`
- `is_active` or `active`
- Supports parent categories with `parent_id`
- Includes icon, color, and description fields

### 3. **Category Repository**

File: `lib/data/repositories/category_repository.dart`

**Key Features**:
- Automatically retrieves Bearer token from storage
- Sets authentication header before API calls
- Handles multiple response formats:
  - Direct array: `[{...}, {...}]`
  - Nested in 'data': `{data: [{...}]}`
  - Nested in 'categories': `{categories: [{...}]}`
- Provides methods:
  - `getAllCategories()` - Fetch all categories
  - `getCategoryById(id)` - Get specific category
  - `getActiveCategories()` - Only active categories

### 4. **API Service Updates**

File: `lib/data/services/api_service.dart`

Updated to use the correct endpoint:
```dart
Future<dynamic> getCategories() async {
  return get(ApiConstants.allCategories);
}
```

### 5. **Home Screen Integration**

File: `lib/features/home/screens/home_screen.dart`

**State Management**:
- `_categories` - List of categories from backend
- `_isLoadingCategories` - Loading state
- `_categoriesError` - Error handling

**Lifecycle**:
```dart
@override
void initState() {
  super.initState();
  _fetchCategories(); // Fetch on screen load
}
```

**UI States**:
1. **Loading**: Shows CircularProgressIndicator
2. **Error**: Shows error message with retry button
3. **Empty**: Shows "No categories available"
4. **Success**: Displays categories in grid (first 6)

### 6. **Category Card Widget**

File: `lib/features/home/widgets/category_card.dart`

**Image Display from Backend**:
The widget now properly displays category images uploaded by the admin via the backend API:
- Displays images from the `category.icon` field as network images
- Supports both full URLs and relative paths (automatically resolves to full URL)
- Falls back to Material icons if image fails to load or is not provided
- Shows loading indicator while image is being fetched

**Smart Icon & Color Mapping**:
The widget automatically assigns appropriate fallback icons and colors:
- Mobile/Phone → `Icons.phone_iphone`, Blue
- Vehicle/Car → `Icons.directions_car`, Orange
- Property/Home → `Icons.home`, Teal
- Jobs → `Icons.work`, Purple
- Furniture → `Icons.chair`, Amber
- Fashion → `Icons.checkroom`, Pink
- Electronics → `Icons.computer`, Cyan
- Sports → `Icons.sports_soccer`, Green
- Books/Education → `Icons.book`, Indigo
- Pets → `Icons.pets`, Brown
- Default → `Icons.category`, Grey

---

### 7. **Image Utility for Category Images**

File: `lib/core/utils/image_utils.dart`

**Purpose**: Centralized image handling for category images with smart URL resolution

**Key Features**:
- `buildCategoryImage()` - Display network images with fallback icons
- `buildCategoryImageLarge()` - Larger variant for header displays
- Automatic URL resolution (handles relative paths and full URLs)
- Error handling with graceful fallback to Material icons
- Loading state with animated progress indicator
- Proper image caching via Flutter's Image.network

**Usage Example**:
```dart
ImageUtils.buildCategoryImage(
  imageUrl: category.icon,  // Can be URL path or filename
  fallbackIcon: Icons.category,
  iconColor: Colors.blue,
  size: 30,
)
```

---

### 8. **Backend Image Upload**

Admin Panel API Endpoint:
```curl
curl --location --globoff '{{base_url}}/api/create-category' \
  --form 'name="Fashion"' \
  --form 'icon=@"/path/to/Fashion.png"'
```

Expected Response:
- Backend stores image file
- Returns category object with `icon` field containing image URL or path
- Image stored typically in `/uploads/`, `/images/`, or `/public/` directory

---

### 9. **Screens Using Category Images**

#### CategoryCard Widget
- Location: `lib/features/home/widgets/category_card.dart`
- Displays in: Home screen category grid, browsing screens
- Image size: 30x30

#### CategoryBrowseScreen
- Location: `lib/features/home/screens/category_browse_screen.dart`
- Displays category image in AppBar header with name
- Image size: 40x40
- Shows full category listings/items

#### CategoryListScreen
- Location: `lib/features/home/screens/category_list_screen.dart`
- Shows all categories in grid view
- Images displayed in circular avatars
- Includes category description if available
- Image size: 32x32

---

## Category Image Response Format

**Expected API Response**:
```json
[
  {
    "id": 1,
    "name": "Fashion",
    "icon": "/uploads/categories/Fashion.png",
    "color": "#FF69B4",
    "description": "Clothing, shoes, and accessories",
    "is_active": true,
    "category_id": null,
    "parent_id": null
  },
  {
    "id": 2,
    "name": "Electronics",
    "icon": "https://api.example.com/uploads/Electronics.jpg",
    "color": "#00CED1",
    "description": "Electronic devices and gadgets",
    "is_active": true,
    "category_id": null,
    "parent_id": null
  }
]
```

**Supported Icon Formats**:
1. Relative paths: `/uploads/categories/Fashion.png` → Resolved to full URL
2. Full URLs: `https://api.example.com/uploads/Fashion.jpg` → Used as-is
3. Icon names: `phone_iphone` → Converted to Material icons (fallback)
4. Hex colors: `#FF69B4` → Parsed and applied

---

## Error Handling

### Image Loading Errors
```dart
// If image URL is invalid or network request fails
// → Falls back to Material icon specified in fallbackIcon parameter
// → Logs error but continues displaying fallback

// Example handling:
ImageUtils.buildCategoryImage(
  imageUrl: category.icon,  // Might be invalid
  fallbackIcon: Icons.category,  // Used if image fails
  iconColor: Colors.grey,
  size: 30,
)
```

### Network Errors
```dart
try {
  final categories = await _categoryRepository.getAllCategories();
  setState(() => _categories = categories);
} catch (e) {
  setState(() => _categoriesError = e.toString());
}
```

### UI Feedback
- **No Internet**: Shows error with retry button
- **Invalid Token**: API returns 401, shows error
- **Server Error**: Shows error message
- **Empty Response**: Shows "No categories available"

---

## Important Notes

❌ **NEVER** do this:
```dart
// DON'T create local categories
final categories = [
  Category(name: 'Mobiles'),
  Category(name: 'Vehicles'),
];
```

✅ **ALWAYS** do this:
```dart
// DO fetch from backend
final categories = await _categoryRepository.getAllCategories();
```

---

## Testing the Implementation

### 1. With Valid Token
```dart
// Token automatically retrieved from storage
final categories = await CategoryRepository().getAllCategories();
print(categories.length); // Should print actual count from backend
```

### 2. Testing in UI
1. Launch app → Login/Signup
2. Navigate to HomeScreen
3. Scroll to "Browse Categories" section
4. Should see loading indicator briefly
5. Categories from backend displayed in grid

### 3. Testing Error States
- **Offline**: Turn off internet → See retry button
- **Invalid Token**: Clear storage → See authentication error
- **Empty Database**: Backend has no categories → See "No categories available"

---

## Backend Requirements

The Admin backend should provide:

**Endpoint**: `GET /api/all-categories`

**Response Format** (choose one):

**Option 1: Direct Array**
```json
[
  {
    "id": 1,
    "name": "Mobiles",
    "description": "Mobile phones and accessories",
    "icon": "phone",
    "color": "#2196F3",
    "is_active": true
  },
  {
    "id": 2,
    "name": "Vehicles",
    "is_active": true
  }
]
```

**Option 2: Nested in 'data'**
```json
{
  "success": true,
  "data": [
    {"id": 1, "name": "Mobiles"},
    {"id": 2, "name": "Vehicles"}
  ]
}
```

**Option 3: Nested in 'categories'**
```json
{
  "categories": [
    {"id": 1, "name": "Mobiles"},
    {"id": 2, "name": "Vehicles"}
  ]
}
```

All three formats are supported by the CategoryRepository!

---

## Summary

✅ Categories are **fetched from backend API**  
✅ **Bearer token authentication** implemented  
✅ **Error handling** with retry functionality  
✅ **Loading states** for better UX  
✅ **Smart icon mapping** based on category names  
✅ Only **active categories** displayed  
✅ **No local category creation** - all data from Admin

The app is now fully integrated with your backend for category management!
