import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../ui/card.dart';
import '../ui/button.dart';
import 'dart:math';
import '../services/fortune_service.dart'; // Added import for FortuneService

class DiaryCalendar extends StatefulWidget {
  final Function(String)? onDateSelect;
  final VoidCallback? onSettingsClick;
  final bool emoticonEnabled;
  final DateTime? userBirthday;
  final VoidCallback? onGoToMyPage;

  const DiaryCalendar({
    super.key,
    this.onDateSelect,
    this.onSettingsClick,
    this.emoticonEnabled = true,
    this.userBirthday,
    this.onGoToMyPage,
  });

  @override
  State<DiaryCalendar> createState() => _DiaryCalendarState();
}

class _DiaryCalendarState extends State<DiaryCalendar> {
  late DateTime currentDate;
  late Map<String, EmotionData> emotionData;

  // 사용자가 선택한 카테고리의 이모지만 사용
  String _getEmotionEmoji(Emotion emotion, AppState appState) {
    final selectedCategory = appState.selectedEmoticonCategory;
    
    // 사용자가 선택한 카테고리와 다른 감정인 경우, 선택된 카테고리의 기본 이모지 사용
    if (emotion != selectedCategory) {
      switch (selectedCategory) {
        case Emotion.fruit:
          return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39';
        case Emotion.animal:
          return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f';
        case Emotion.shape:
          return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5';
        case Emotion.weather:
          return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f';
      }
    }
    
    // 선택된 카테고리와 같은 감정인 경우 원래 이모지 사용
    final Map<Emotion, String> emotionEmojis = {
      Emotion.fruit: 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39',
      Emotion.animal: 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f',
      Emotion.shape: 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5',
      Emotion.weather: 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f',
    };
    
    return emotionEmojis[emotion] ?? emotionEmojis[Emotion.shape]!;
  }

  final Map<Emotion, Color> emotionColors = {
    Emotion.fruit: const Color(0xFFEA580C), // orange-500
    Emotion.animal: const Color(0xFF22C55E), // green-500
    Emotion.shape: const Color(0xFF3B82F6), // blue-500
    Emotion.weather: const Color(0xFFEAB308), // yellow-500
  };

  final List<String> monthNames = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월'
  ];

  final List<String> dayNames = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    currentDate = DateTime.now();

    
    // AppState에서 emotionData 가져오기
    final appState = Provider.of<AppState>(context, listen: false);
    emotionData = appState.emotionData;
    
    // 생년월일이 설정되어 있으면 운세 로드
    if (widget.userBirthday != null) {
      _loadTodaysFortune(widget.userBirthday!);
    }
  }

  Map<String, EmotionData> _generateCurrentMonthSampleData() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final daysInCurrentMonth = DateTime(year, month + 1, 0).day;
    
    final Map<String, EmotionData> sampleData = {};
    final emotions = Emotion.values;
    final emojis = [
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f',
    ];

    final random = Random();
    
    // Add some sample entries for the current month
    for (int day = 1; day <= min(daysInCurrentMonth, 10); day++) {
      final randomIndex = random.nextInt(emotions.length);
      sampleData['$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}'] = EmotionData(
        emotion: emotions[randomIndex],
        emoji: emojis[randomIndex],
      );
    }
    
    return sampleData;
  }

  void _navigateMonth(String direction) {
    setState(() {
      if (direction == 'prev') {
        currentDate = DateTime(currentDate.year, currentDate.month - 1);
      } else {
        currentDate = DateTime(currentDate.year, currentDate.month + 1);
      }
    });
  }

  String _getDateKey(int day) {
    return '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  void _handleDateClick(int day) {
    final dateKey = _getDateKey(day);
    print('Calendar date clicked: $dateKey');
    
    // AppState의 데이터를 사용하여 일기 존재 여부 확인
    final appState = Provider.of<AppState>(context, listen: false);
    final hasDiary = appState.emotionData.containsKey(dateKey) && 
                     appState.emotionData[dateKey]?.entry != null;
    
    if (widget.onDateSelect != null) {
      widget.onDateSelect!(dateKey);
    } else {
      appState.handleDateSelect(dateKey);
    }
  }

  String _currentFortune = '';
  bool _isLoadingFortune = false;

  Future<void> _loadTodaysFortune(DateTime birthday) async {
    if (_isLoadingFortune) return;
    
    setState(() {
      _isLoadingFortune = true;
    });

    try {
      // 생년월일을 YYYYMMDD 형식으로 변환
      final birthdayString = '${birthday.year}${birthday.month.toString().padLeft(2, '0')}${birthday.day.toString().padLeft(2, '0')}';
      
      // OpenAI API를 통해 운세 생성 시도
      final fortune = await FortuneService.generateFortune(birthdayString);
      
      if (fortune != null) {
        setState(() {
          _currentFortune = fortune;
        });
      } else {
        // API 실패 시 기본 운세 사용
        setState(() {
          _currentFortune = FortuneService.getDefaultFortune(birthday);
        });
      }
    } catch (e) {
      print('운세 로딩 중 오류: $e');
      // 오류 발생 시 기본 운세 사용
      setState(() {
        _currentFortune = FortuneService.getDefaultFortune(birthday);
      });
    } finally {
      setState(() {
        _isLoadingFortune = false;
      });
    }
  }


  List<Widget> _renderCalendarDays() {
    final year = currentDate.year;
    final month = currentDate.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOfMonth = DateTime(year, month, 1).weekday % 7;

    final days = <Widget>[];

    // Empty cells for days before the first day of the month
    for (int i = 0; i < firstDayOfMonth; i++) {
      days.add(const SizedBox(height: 90));
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey = _getDateKey(day);
      final dayData = emotionData[dateKey];
      final isToday = DateTime.now().year == year && 
                     DateTime.now().month == month && 
                     DateTime.now().day == day;

      days.add(
        SizedBox(
          height: 90, // 셀 높이를 늘려서 이모지가 짤리지 않도록 함
          child: Stack(
            clipBehavior: Clip.none, // 이모지가 짤리지 않도록 설정
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Material(
                    color: AppColors.calendarBg,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _handleDateClick(day),
                      hoverColor: AppColors.calendarDateHover,
                      child: Stack(
                        children: [
                          // 오늘 날짜 표시
                          if (isToday)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          // 감정 데이터가 있을 때 배경색
                          if (dayData != null)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: emotionColors[dayData.emotion]?.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          // 숫자 - 항상 중앙에 고정
                          Positioned.fill(
                            child: Center(
                              child: Text(
                                day.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isToday 
                                    ? AppColors.primary
                                    : AppColors.mutedForeground,
                                ),
                              ),
                            ),
                          ),
                          // 이모티콘 - Transform으로 셀 밖으로 이동 (절대 짤리지 않음)
                          if (dayData != null && widget.emoticonEnabled)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Transform.translate(
                                  offset: const Offset(0, -20),
                                  child: Consumer<AppState>(
                                    builder: (context, appState, child) {
                                      return Image.network(
                                        _getEmotionEmoji(dayData.emotion, appState),
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Text(
                                            '😊',
                                            style: TextStyle(fontSize: 12),
                                          );
                                        },
                                      );
                                    },

                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return days;
  }

  Widget _renderFortuneSection() {

    // 생년월일이 설정되지 않은 경우 마이페이지로 이동하는 카드 표시
    if (widget.userBirthday == null) {
      return AppCard(
        backgroundColor: AppColors.calendarBg,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGradientStart.withValues(alpha: 0.8),
                    AppColors.primaryGradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🎂', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '오늘의 운세',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '생년월일을 설정하시면 개인 맞춤 운세를 확인할 수 있어요!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: widget.onGoToMyPage,
                text: '마이페이지에서 생년월일 설정하기',
                variant: ButtonVariant.outline,
              ),
            ),
          ],
        ),
      );
    }

    final today = DateTime.now();
    final formatToday = '${today.month}월 ${today.day}일';

    return AppCard(
      backgroundColor: AppColors.calendarBg,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGradientStart.withValues(alpha: 0.8),
                  AppColors.primaryGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text('🔮', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '오늘의 운세',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatToday,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGradientStart.withValues(alpha: 0.1),
                  AppColors.primaryGradientEnd.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGradientStart.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),

            child: _isLoadingFortune
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '운세를 생성하고 있어요...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                )
              : Text(
                  _currentFortune.isNotEmpty ? _currentFortune : FortuneService.getDefaultFortune(widget.userBirthday!),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.foreground,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // AppState에서 최신 emotionData 가져오기
        emotionData = appState.emotionData;
        
        final year = currentDate.year;
        final month = currentDate.month;

        return Container(
      constraints: const BoxConstraints(minHeight: double.infinity),
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448), // max-w-md
            child: Column(
              children: [
                // Header with Logo and Settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(top: 16), // 원하는 만큼 조절 (예: 16)
                      child: Container(
                        height: 50,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Settings Button
                    AppButton(
                      onPressed: widget.onSettingsClick,
                      variant: ButtonVariant.ghost,
                      size: ButtonSize.icon,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.settings,
                          size: 20,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Calendar Card
                AppCard(
                  backgroundColor: AppColors.calendarBg,
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Month Navigation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppButton(
                            onPressed: () => _navigateMonth('prev'),
                            variant: ButtonVariant.ghost,
                            size: ButtonSize.icon,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.chevron_left, size: 16),
                            ),
                          ),
                          Text(
                            '$year.${month.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.foreground,
                            ),
                          ),
                          AppButton(
                            onPressed: () => _navigateMonth('next'),
                            variant: ButtonVariant.ghost,
                            size: ButtonSize.icon,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.chevron_right, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Day Headers
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        children: [
                          ...dayNames.map((day) => Container(
                            height: 32,
                            alignment: Alignment.center,
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedForeground,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Calendar Grid
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        children: _renderCalendarDays(),
                      ),
                    ],
                  ),
                ),

                // Today's Fortune Section
                _renderFortuneSection(),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
} 