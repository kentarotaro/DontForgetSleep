import '../models/caffeine_advisor_model.dart';

class MockCaffeineService {
  Future<CaffeineAdvisorData> fetchData() async {
    // Simulate network delay for loading state
    await Future.delayed(const Duration(seconds: 1));

    return CaffeineAdvisorData(
      bestTime: '09:30',
      latestCutoff: '15:00',
      statusMessage: "It's 10:30 AM — you're in the safe window",
      isSafeWindow: true,
      bestNapWindow: '13:00 – 13:20',
      bestNapSubtitle: 'Between your job and next commitment',
      naps: [
        NapRecommendation(
          title: 'Power Nap',
          duration: '10–20 min',
          description: "Quick recharge. Won't disrupt tonight's sleep.",
          isRecommended: true,
        ),
        NapRecommendation(
          title: 'Full Cycle',
          duration: '~90 min',
          description: 'Deep recovery. Only if you have a 2h gap.',
          isRecommended: false,
        ),
      ],
    );
  }
}
