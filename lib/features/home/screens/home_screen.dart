import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onetap365app/data/services/storage_service.dart';
import 'package:onetap365app/features/auth/screens/signin_screen.dart';
import 'package:onetap365app/features/home/screens/book_service/service_categories.dart';
import 'package:onetap365app/features/home/screens/category_browse_screen.dart';
import 'package:onetap365app/features/home/screens/category_list_screen.dart';
import 'package:onetap365app/features/home/screens/post_ad/post_ad_type_screen.dart';
import 'package:onetap365app/features/home/widgets/category_card.dart';
import 'package:onetap365app/features/home/widgets/featured_listing_card.dart';
import 'package:onetap365app/features/home/widgets/listing_card.dart';
import 'package:onetap365app/features/home/widgets/trending_header.dart';
import 'package:onetap365app/features/home/widgets/subscribe_plan_dialog.dart';
import 'package:onetap365app/features/profile/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/ad_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../providers/ads_provider.dart';

import 'package:onetap365app/features/cash2keys/screens/cash2keys_home_screen.dart';
import '../widgets/bottom_nav_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ambient Particle Painter
// ─────────────────────────────────────────────────────────────────────────────
class _Particle {
  double x, y, size, speed, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final double animValue;
  final List<_Particle> particles;
  final Color color;

  _ParticlePainter({
    required this.animValue,
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y - animValue * p.speed * 60) % size.height;
      final paint = Paint()
        ..color = color.withOpacity(
            p.opacity * (0.4 + 0.6 * math.sin(animValue * 2 + p.x)))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
          Offset(p.x * size.width, dy < 0 ? dy + size.height : dy),
          p.size,
          paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // 0 = cannot post, 1 = can post
  int _canPostAdFlag = 1;
  int _isSubscription = 0;
  int _isAds = 0;
  int _selectedIndex = 0;
  final CategoryRepository _categoryRepository = CategoryRepository();

  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  String? _categoriesError;
  bool _isAuthenticated = false;
  bool _authChecked = false;

  // Animation controllers
  late final AnimationController _particleController;
  late final AnimationController _headerController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _pulseFade;

  late final List<_Particle> _particles;
  final _random = math.Random(42);

  @override
  void initState() {
    super.initState();

    _particles = List.generate(
        28,
        (i) => _Particle(
              x: _random.nextDouble(),
              y: _random.nextDouble() * 800,
              size: 1.0 + _random.nextDouble() * 2.5,
              speed: 0.3 + _random.nextDouble() * 0.6,
              opacity: 0.15 + _random.nextDouble() * 0.35,
            ));

    _particleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();

    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _headerFade =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _headerController, curve: Curves.easeOutCubic));

    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseFade = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);

    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();

    _initAuthAndFetch();
    if (_isAuthenticated) {
      _fetchCanPostAdFlag();
    }
    Future.delayed(
        const Duration(milliseconds: 100), () => _headerController.forward());
  }

  @override
  void dispose() {
    _particleController.dispose();
    _headerController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _initAuthAndFetch() async {
    final isLoggedIn = await StorageService.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = isLoggedIn;
      _authChecked = true;
      if (!isLoggedIn) {
        _isLoadingCategories = false;
        _categories = [];
        _categoriesError = null;
      }
    });
    if (isLoggedIn) {
      _fetchCategories();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchTrendingAds());
      _fetchCanPostAdFlag();
    }
  }

  Future<void> _fetchCanPostAdFlag() async {
    try {
      final adsRepo = context.read<AdsProvider>().adsRepository;
      final apiService = adsRepo.apiService;
      final token = await StorageService.getToken();
      if (token != null) {
        apiService.setAuthToken(token);
      }
      final response = await apiService.getMyAds();
      // Debug: print the full response from backend
      // ignore: avoid_print
      print('DEBUG getMyAds response:');
      print(response);
      // New logic: if response['data'] is empty, user can post; else, cannot
      int canPost = 1;
      if (response is Map && response.containsKey('data')) {
        final data = response['data'];
        if (data is List && data.isNotEmpty) {
          canPost = 0; // User already posted an ad, cannot post again
        } else {
          canPost = 1; // No ads, can post
        }
      }
      setState(() {
        _canPostAdFlag = canPost;
      });
    } catch (e) {
      setState(() {
        _canPostAdFlag = 1;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = true;
        _categoriesError = null;
      });
      final categories = await _categoryRepository.getAllCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesError = e.toString();
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchTrendingAds() async {
    final adsProvider = context.read<AdsProvider>();
    await adsProvider.fetchAllItems();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeContent(),
      Cash2KeysHomeScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _selectedIndex == 2 ? null : _buildAppBar(),
      body: Stack(
        children: [
          // Ambient particles layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _ParticlePainter(
                  animValue: _particleController.value,
                  particles: _particles,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          // Radial glow top-right
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.18),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Radial glow bottom-left
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.10),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildSearch(),
          _buildPostAdButton(),
          _buildFeatures(),
          _buildCategories(),
          _buildTrending(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AppBar(
            backgroundColor: AppColors.background.withOpacity(0.55),
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(0.85),
                    AppColors.background.withOpacity(0.4),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withOpacity(0.15),
                    width: 0.8,
                  ),
                ),
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // Logo icon dot
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6, bottom: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.6),
                            blurRadius: 8)
                      ],
                    ),
                  ),
                  Text('OneTap',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      )),
                  Text('365',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      )),
                ],
              ),
            ),
            actions: [
              AnimatedBuilder(
                animation: _pulseFade,
                builder: (context, child) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded,
                          color: Colors.white70, size: 24),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(_pulseFade.value),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.red
                                    .withOpacity(0.5 * _pulseFade.value),
                                blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white70, size: 22),
                onPressed: () {},
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 92, 22, 4),
      child: FadeTransition(
        opacity: _headerFade,
        child: SlideTransition(
          position: _headerSlide,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.25), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: AppColors.primary),
                    ),
                    const SizedBox(width: 6),
                    Text('Good day',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome\nBack!',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.05,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discover amazing deals near you',
                style: GoogleFonts.dmMono(
                    fontSize: 13, color: Colors.white38, letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search products, cars, jobs, properties…',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.28), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.primary.withOpacity(0.7), size: 22),
                suffixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Text('Filter',
                      style: GoogleFonts.dmMono(
                        color: AppColors.primary,
                        fontSize: 11,
                      )),
                ),
                filled: true,
                fillColor: const Color(0xFF081410).withOpacity(0.85),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.1), width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.1), width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.4), width: 1.2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostAdButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: _canPostAdFlag == 0 ? 0.5 : 1.0,
              child: _AnimatedActionButton(
                onTap: () {
                  if (!_isAuthenticated) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SignInScreen()));
                    return;
                  }
                  if (_canPostAdFlag == 0) {
                    showDialog(
                      context: context,
                      builder: (context) => const SubscribePlanDialog(),
                    );
                    return;
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PostAdTypeScreen()));
                },
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withGreen(200)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('Post an Ad',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: _AnimatedActionButton(
            onTap: () {
              if (!_isAuthenticated) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => SignInScreen()));
                return;
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ServiceCategoriesScreen()));
            },
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFF081812),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.handyman_rounded,
                        color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text('Book Service',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      (Icons.shield_outlined, 'Secure', 'Verified deals'),
      (Icons.flash_on_rounded, 'Quick', 'List in seconds'),
      (Icons.currency_rupee_rounded, 'Best Price', 'Great deals'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
      child: Row(
        children: features.asMap().entries.map((entry) {
          final i = entry.key;
          final f = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
              child: _StaggeredFadeIn(
                delay: Duration(milliseconds: 200 + i * 120),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081812),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.12), width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(f.$1, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(f.$2,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                      const SizedBox(height: 2),
                      Text(f.$3,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white38),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategories() {
    if (!_authChecked) return const SizedBox.shrink();
    if (!_isAuthenticated) {
      return _buildGuestPrompt(
          title: 'Browse Categories',
          message: 'Sign in to view categories and listings.');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Browse Categories',
            subtitle: "Find what you're looking for",
            actionLabel: 'All →',
            onAction: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CategoryListScreen())),
          ),
          const SizedBox(height: 16),
          if (_isLoadingCategories)
            _buildShimmerGrid()
          else if (_categoriesError != null)
            _buildErrorState(onRetry: _fetchCategories)
          else if (_categories.isEmpty)
            _buildEmptyState('No categories available')
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories
                  .where((c) => c.isActive)
                  .take(6)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) => _StaggeredFadeIn(
                        delay: Duration(milliseconds: 80 * entry.key),
                        child: CategoryCard(category: entry.value),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTrending() {
    if (!_authChecked) return const SizedBox.shrink();
    if (!_isAuthenticated) {
      return _buildGuestPrompt(
          title: 'Trending Listings',
          message: 'Sign in to see trending ads near you.');
    }

    return Consumer<AdsProvider>(
      builder: (context, adsProvider, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                title: 'Trending Now',
                subtitle: 'Most popular listings',
                actionLabel: '',
                onAction: null,
                hasBadge: true,
              ),
              const SizedBox(height: 14),
              if (adsProvider.isLoadingTrending)
                _buildListingShimmer()
              else if (adsProvider.trendingError != null)
                _buildErrorState(onRetry: _fetchTrendingAds)
              else if (adsProvider.trendingAds.isEmpty)
                _buildEmptyState('No trending ads available')
              else
                ...adsProvider.trendingAds
                    .asMap()
                    .entries
                    .map(
                      (entry) => _StaggeredFadeIn(
                        delay: Duration(milliseconds: 60 * entry.key),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ListingCard(
                            ad: entry.value,
                            image: entry.value.photos.isNotEmpty
                                ? entry.value.photos.first
                                : 'https://via.placeholder.com/400',
                            badge: _getBadgeText(entry.value),
                            badgeColor: _getBadgeColor(entry.value),
                            title: entry.value.name,
                            price:
                                '₹ ${entry.value.sellingPrice}${entry.value.itemType == 'RENT' ? ' / mo' : ''}',
                            location:
                                '${entry.value.city}, ${entry.value.state}',
                            time: _getTimeAgo(entry.value.createdAt),
                          ),
                        ),
                      ),
                    )
                    .toList(),
            ],
          ),
        );
      },
    );
  }

  // ── Section Header ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required String actionLabel,
    VoidCallback? onAction,
    bool hasBadge = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      )),
                  if (hasBadge) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.3), width: 0.8),
                      ),
                      child: Text('LIVE',
                          style: GoogleFonts.dmMono(
                            fontSize: 9,
                            color: Colors.orange,
                            letterSpacing: 1,
                          )),
                    ),
                  ],
                ],
              ),
            ),
            if (onAction != null && actionLabel.isNotEmpty)
              GestureDetector(
                onTap: onAction,
                child: Text(actionLabel,
                    style: GoogleFonts.dmMono(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    )),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  // ── Shimmer placeholders ────────────────────────────────────────────────────
  Widget _buildShimmerGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(
          6,
          (i) => _ShimmerBox(
                controller: _shimmerController,
                width: (MediaQuery.of(context).size.width - 44 - 20) / 3,
                height: 90,
                borderRadius: 14,
              )),
    );
  }

  Widget _buildListingShimmer() {
    return Column(
      children: List.generate(
          3,
          (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ShimmerBox(
                  controller: _shimmerController,
                  width: double.infinity,
                  height: 100,
                  borderRadius: 16,
                ),
              )),
    );
  }

  // ── Error / Empty states ────────────────────────────────────────────────────
  Widget _buildErrorState({required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.red.withOpacity(0.7), size: 44),
            const SizedBox(height: 12),
            const Text('Something went wrong',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded,
                  color: AppColors.primary, size: 16),
              label: Text('Retry', style: TextStyle(color: AppColors.primary)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message,
            style: const TextStyle(color: Colors.white38, fontSize: 14)),
      ),
    );
  }

  // ── Guest Prompt ────────────────────────────────────────────────────────────
  Widget _buildGuestPrompt({required String title, required String message}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF081812),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.15), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
            const SizedBox(height: 6),
            Text(message,
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => SignInScreen())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.75)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Text('Sign In →',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _getBadgeText(Ad ad) {
    if (ad.isTrending == true) return 'TRENDING';
    if (ad.isHotDeal == true) return 'HOT DEAL';
    if (ad.isVerified == true) return 'VERIFIED';
    return '';
  }

  Color _getBadgeColor(Ad ad) {
    if (ad.isTrending == true) return Colors.orange;
    if (ad.isHotDeal == true) return Colors.red;
    if (ad.isVerified == true) return Colors.green;
    return Colors.grey;
  }

  String _getTimeAgo(DateTime? date) {
    if (date == null) return 'Recently';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    return 'Over a month ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Animated Widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Tap-scale animation wrapper for buttons
class _AnimatedActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _AnimatedActionButton({required this.child, required this.onTap});

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Staggered fade-in + slide-up
class _StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _StaggeredFadeIn({required this.child, required this.delay});

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

/// Shimmer loading placeholder
class _ShimmerBox extends StatelessWidget {
  final AnimationController controller;
  final double width, height, borderRadius;

  const _ShimmerBox({
    required this.controller,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final shimmerValue = controller.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + shimmerValue * 3, 0),
              end: Alignment(-0.5 + shimmerValue * 3, 0),
              colors: const [
                Color(0xFF0B1A14),
                Color(0xFF122A1E),
                Color(0xFF0B1A14),
              ],
            ),
          ),
        );
      },
    );
  }
}
