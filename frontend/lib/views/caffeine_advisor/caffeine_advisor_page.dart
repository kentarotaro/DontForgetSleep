import 'package:flutter/material.dart';
import '../../models/caffeine_advisor_model.dart';
import '../../services/mock_caffeine_service.dart';
import '../../widgets/caffeine_advisor/info_card.dart';
import '../../widgets/caffeine_advisor/nap_card.dart';
import '../../theme/app_colors.dart';
class CaffeineAdvisorPage extends StatefulWidget {
  const CaffeineAdvisorPage({Key? key}) : super(key: key);

  @override
  State<CaffeineAdvisorPage> createState() => _CaffeineAdvisorPageState();
}

class _CaffeineAdvisorPageState extends State<CaffeineAdvisorPage>
    with SingleTickerProviderStateMixin {
  final MockCaffeineService _service = MockCaffeineService();
  CaffeineAdvisorData? _data;
  bool _isLoading = true;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _shimmerAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _loadData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await _service.fetchData();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load data')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            'Caffeine Advisor',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildSkeleton()
            : _data == null
                ? const Center(
                    child: Text('No data available',
                        style: TextStyle(color: Colors.white)))
                : _buildContent(),
      ),
    );
  }

  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              _buildSkeletonCard(220, _shimmerAnimation.value),
              const SizedBox(height: 24),
              _buildSkeletonCard(280, _shimmerAnimation.value),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard(double height, double opacity) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity * 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          _buildCaffeineWindowCard(),
          const SizedBox(height: 24),
          _buildNapAdvisorSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCaffeineWindowCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff210D1B), Color(0xFF271647)], // Soft purple gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color:  const Color(0xff4B1E2F), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.coffee_outlined, color: Color(0xFFFFB300), size: 22),
              SizedBox(width: 10),
              Text(
                'Caffeine Window',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  title: 'Best time',
                  value: _data!.bestTime,
                  subtitle: '90 min after wake',
                  valueColor: const Color(0xFF00D794), // Bright cyan-green
                  // titleColor: const Color.fromARGB(255, 215, 1, 1), // Safe green for title
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InfoCard(
                  title: 'Latest cutoff',
                  value: _data!.latestCutoff,
                  subtitle: '8h before bed',
                  valueColor: const Color(0xFFFF5252), // Bright pink-red
                  // titleColor: const Color.fromARGB(255, 131, 255, 82), // Danger red for title
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF251E31), //26213F
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _data!.isSafeWindow ? Icons.check : Icons.close,
                  color: _data!.isSafeWindow
                      ? const Color(0xFF00D794)
                      : const Color(0xFFFF5252),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _data!.statusMessage,
                    style: TextStyle(
                      color: _data!.isSafeWindow
                          ? const Color(0xFF00D794)
                          : const Color(0xFFFF5252),
                      fontSize: 14,
                      // fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNapAdvisorSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF222B3A), Color(0xFF1E192E)], // Darker teal-blue/purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.nightlight_round_sharp, color: Color(0xFF00BFA5), size: 20),
              SizedBox(width: 10),
              Text(
                'Nap Advisor',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: NapCard(
                    title: _data!.naps[0].title,
                    duration: _data!.naps[0].duration,
                    description: _data!.naps[0].description,
                    isRecommended: _data!.naps[0].isRecommended,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NapCard(
                    title: _data!.naps[1].title,
                    duration: _data!.naps[1].duration,
                    description: _data!.naps[1].description,
                    isRecommended: _data!.naps[1].isRecommended,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C0E30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Best nap window today',
                  style: TextStyle(
                    color: AppColors.purple300,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _data!.bestNapWindow,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _data!.bestNapSubtitle,
                  style: const TextStyle(
                    color: AppColors.purple300,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
