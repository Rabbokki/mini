import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../ui/card.dart';
import '../ui/button.dart';
import '../services/user_service.dart';
import '../services/user_settings_service.dart';
import 'dart:math';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final GlobalKey _birthdayInputKey = GlobalKey(); // 생일 입력 박스의 위치를 찾기 위한 키
  bool _voiceEnabled = true;
  double _voiceVolume = 50;
  String _userName = '사용자';
  bool _isProfileDialogOpen = false;
  bool _isEmojiDialogOpen = false;
  bool _isCalendarVisible = false;
  String _tempName = '사용자';
  DateTime? _tempBirthday;
  DateTime _currentCalendarDate = DateTime.now(); // 현재 표시중인 달력의 년/월 상태 추가
  
  // Emoji categories state
  Map<Emotion, List<String>> _emojiCategories = {
    Emotion.shape: ['⭐', '🔶', '🔷', '⚫', '🔺'],
    Emotion.fruit: ['🍎', '🍊', '🍌', '🍇', '🍓'],
    Emotion.animal: ['🐶', '🐱', '🐰', '🐸', '🐼'],
    Emotion.weather: ['☀️', '🌧️', '⛈️', '🌈', '❄️']
  };
  
  Emotion _selectedEmotion = Emotion.shape;

  final Map<Emotion, String> _emotionLabels = {
    Emotion.shape: '도형',
    Emotion.fruit: '과일',
    Emotion.animal: '동물',
    Emotion.weather: '날씨'
  };

  final Map<Emotion, int> _emotionScores = {
    Emotion.shape: 70,
    Emotion.fruit: 80,
    Emotion.animal: 85,
    Emotion.weather: 75
  };

  final List<String> _availableEmojis = [
    // 과일
    '🍎', '🍊', '🍋', '🍌', '🍍', '🥭', '🍑', '🍒', '🍓', '🫐', '🥝', '🍅', '🫒', '🥥', '🥑', '🍆', '🥔', '🥕', '🌽', '🌶️', '🫑', '🥒', '🥬', '🥦', '🧄', '🧅', '🍄', '🥜', '🌰', '🍇', '🍈', '🍉',
    // 동물
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🪱', '🐛', '🦋', '🐌', '🐞', '🐜', '🪰', '🪲', '🪳', '🦗', '🕷️', '🕸️', '🦂', '🐢', '🐍', '🦎', '🦖', '🦕', '🐙', '🦑', '🦐', '🦞', '🦀', '🐡', '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🐊', '🐅', '🐆', '🦓', '🦍', '🦧', '🐘', '🦛', '🦏', '🐪', '🐫', '🦒', '🦘', '🐃', '🐂', '🐄', '🐎', '🐖', '🐏', '🐑', '🦙', '🐐', '🦌', '🐕', '🐩', '🦮', '🐈', '🪶', '🐓', '🦃', '🦚', '🦜', '🦢', '🐇', '🦝', '🦨', '🦡', '🦫',
    // 도형
    '⭐', '🌟', '✨', '⚡', '💥', '🔥', '🌈', '☀️', '🌞', '🌝', '🌛', '🌜', '🌚', '🌕', '🌖', '🌗', '🌘', '🌑', '🌒', '🌓', '🌔', '🔴', '🟠', '🟡', '🟢', '🔵', '🟣', '🟤', '⚫', '⚪', '🟥', '🟧', '🟨', '🟩', '🟦', '🟪', '🟫', '⬛', '⬜', '◼️', '◻️', '◾', '◽', '▪️', '▫️', '🔶', '🔷', '🔸', '🔹', '🔺', '🔻', '💠', '🔘', '🔳', '🔲',
    // 날씨
    '☀️', '🌤️', '⛅', '🌥️', '🌦️', '🌧️', '⛈️', '🌩️', '🌨️', '❄️', '☃️', '⛄', '🌬️', '💨', '🌪️', '🌫️', '🌈', '☂️', '☔', '⚡', '🌊', '💧', '💦', '🧊'
  ];

  // 카테고리별 사용 가능한 이모티콘 맵 추가
  final Map<Emotion, List<String>> _availableEmoticonsByCategory = {
    Emotion.shape: ['⭐', '🌟', '✨', '⚡', '💥', '🔥', '🌈', '☀️', '🌞', '🌝', '🌛', '🌜', '🌚', '🌕', '🌖', '🌗', '🌘', '🌑', '🌒', '🌓', '🌔', '🔴', '🟠', '🟡', '🟢', '🔵', '🟣', '🟤', '⚫', '⚪', '🟥', '🟧', '🟨', '🟩', '🟦', '🟪', '🟫', '⬛', '⬜', '◼️', '◻️', '◾', '◽', '▪️', '▫️', '🔶', '🔷', '🔸', '🔹', '🔺', '🔻', '💠', '🔘', '🔳', '🔲'],
    Emotion.fruit: ['🍎', '🍊', '🍋', '🍌', '🍍', '🥭', '🍑', '🍒', '🍓', '🫐', '🥝', '🍅', '🫒', '🥥', '🥑', '🍆', '🥔', '🥕', '🌽', '🌶️', '🫑', '🥒', '🥬', '🥦', '🧄', '🧅', '🍄', '🥜', '🌰', '🍇', '🍈', '🍉'],
    Emotion.animal: ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🪱', '🐛', '🦋', '🐌', '🐞', '🐜', '🪰', '🪲', '🪳', '🦗', '🕷️', '🕸️', '🦂', '🐢', '🐍', '🦎', '🦖', '🦕', '🐙', '🦑', '🦐', '🦞', '🦀', '🐡', '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🐊', '🐅', '🐆', '🦓', '🦍', '🦧', '🐘', '🦛', '🦏', '🐪', '🐫', '🦒', '🦘', '🐃', '🐂', '🐄', '🐎', '🐖', '🐏', '🐑', '🦙', '🐐', '🦌', '🐕', '🐩', '🦮', '🐈', '🪶', '🐓', '🦃', '🦚', '🦜', '🦢', '🕊️', '🐇', '🦝', '🦨', '🦡', '🦫'],
    Emotion.weather: ['☀️', '🌤️', '⛅', '🌥️', '🌦️', '🌧️', '⛈️', '🌩️', '🌨️', '❄️', '☃️', '⛄', '🌬️', '💨', '🌪️', '🌫️', '🌈', '☂️', '☔', '⚡', '🌊', '💧', '💦', '🧊'],
  };

  @override
  void initState() {
    super.initState();
    _tempName = _userName;
    _loadUserProfile();
    _loadUserSettings();
  }
  
  // 사용자 프로필 로드
  Future<void> _loadUserProfile() async {
    try {
      final userData = await UserService.getUserProfile();
      setState(() {
        _userName = userData?['username'] ?? '사용자';
        _tempName = _userName;
        final birthdayStr = userData?['birthday'];
        if (birthdayStr != null && birthdayStr.isNotEmpty) {
          final birthday = UserService.parseBirthday(birthdayStr);
          if (birthday != null) {
            // AppState에도 생일 정보 업데이트
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AppState>().setUserBirthday(birthday);
            });
          }
        }
      });
    } catch (e) {
      print('프로필 로드 실패: $e');
      // 토큰이 없거나 인증 실패 시 로그인 페이지로 이동
              if (e.toString().contains('토큰이 없습니다') || e.toString().contains('401')) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await context.read<AppState>().handleLogout();
          });
        }
    }
  }

  // 사용자 설정 로드
  Future<void> _loadUserSettings() async {
    try {
      // 서버에서 사용자 설정 불러오기
      final settings = await UserSettingsService.getUserSettings();
      final appState = context.read<AppState>();
      
      print('서버에서 불러온 설정: $settings'); // 디버깅용
      
      setState(() {
        _voiceEnabled = settings['voice_enabled'] ?? appState.voiceEnabled;
        _voiceVolume = (settings['voice_volume'] ?? appState.voiceVolume).toDouble();
        
        // emoticon_categories 타입 변환 수정
        final emoticonCategoriesData = settings['emoticon_categories'] ?? appState.emoticonCategories;
        _emojiCategories = Map<Emotion, List<String>>.from(
          emoticonCategoriesData.map((key, value) {
            // List<dynamic>을 List<String>으로 변환
            final List<String> stringList = (value as List).map((item) => item.toString()).toList();
            return MapEntry(Emotion.values.firstWhere((e) => e.name == key), stringList);
          })
        );
        
        // 마지막 선택된 카테고리 불러오기
        final lastCategory = settings['last_selected_emotion_category'] ?? appState.lastSelectedEmotionCategory;
        print('마지막 선택된 카테고리: $lastCategory'); // 디버깅용
        print('설정 전 _selectedEmotion: ${_selectedEmotion.name}'); // 디버깅용
        _selectedEmotion = Emotion.values.firstWhere(
          (e) => e.name == lastCategory,
          orElse: () => Emotion.shape
        );
        print('설정 후 _selectedEmotion: ${_selectedEmotion.name}'); // 디버깅용
      });
      
      // AppState도 업데이트 (서버 저장 없이)
      final emoticonCategoriesForAppState = _emojiCategories.map((key, value) => MapEntry(key.name, value));
      appState.updateSettingsFromServer(
        voiceEnabled: _voiceEnabled,
        voiceVolume: _voiceVolume.toInt(),
        emoticonCategories: emoticonCategoriesForAppState,
        lastSelectedEmotionCategory: _selectedEmotion.name,
      );
      
      print('AppState 업데이트 완료: ${_selectedEmotion.name}'); // 디버깅용
      
    } catch (e) {
      print('사용자 설정 로드 실패: $e');
      // 서버에서 불러오기 실패 시 AppState에서 불러오기
      try {
        final appState = context.read<AppState>();
        setState(() {
          _voiceEnabled = appState.voiceEnabled;
          _voiceVolume = appState.voiceVolume.toDouble();
          _emojiCategories = Map<Emotion, List<String>>.from(
            appState.emoticonCategories.map((key, value) => 
              MapEntry(Emotion.values.firstWhere((e) => e.name == key), value)
            )
          );
          _selectedEmotion = Emotion.values.firstWhere(
            (e) => e.name == appState.lastSelectedEmotionCategory,
            orElse: () => Emotion.shape
          );
        });
      } catch (e2) {
        print('AppState에서 설정 로드 실패: $e2');
      }
    }
  }



  String _formatDate(DateTime? date) {
    if (date == null) return '생일 미설정';
    return '${date.year}년 ${date.month.toString().padLeft(2, '0')}월 ${date.day.toString().padLeft(2, '0')}일';
  }

  Future<void> _handleSaveProfile(AppState appState) async {
    try {
      // 백엔드에 프로필 정보 업데이트
      final birthdayStr = _tempBirthday != null 
          ? UserService.formatBirthday(_tempBirthday)
          : null;
      
      await UserService.updateUserProfile(
        name: _tempName,
        birthday: _tempBirthday,
      );
      
      setState(() {
        _userName = _tempName;
      });
      
      if (_tempBirthday != null) {
        appState.setUserBirthday(_tempBirthday!);
      }
      
      setState(() {
        _isProfileDialogOpen = false;
      });
      
      // 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 성공적으로 저장되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleCancelProfile(AppState appState) {
    setState(() {
      _tempName = _userName;
      _tempBirthday = appState.userBirthday;
      _isProfileDialogOpen = false;
    });
  }

  void _handleEmojiSelect(String emoji) {
    setState(() {
      var currentEmojis = _emojiCategories[_selectedEmotion]!;
      if (currentEmojis.contains(emoji)) {
        currentEmojis.remove(emoji);
      } else if (currentEmojis.length < 5) {
        currentEmojis.add(emoji);
      }
    });
  }

  void _handleCategorySelect(Emotion emotion) async {
    setState(() {
      _selectedEmotion = emotion;
    });
    // AppState에 마지막 선택된 카테고리 저장
    await context.read<AppState>().setLastSelectedEmotionCategory(emotion.name);
  }

  Future<void> _resetToDefault() async {
    try {
      final appState = context.read<AppState>();
      
      // 기본값으로 설정
      final defaultCategories = {
        'shape': ['⭐', '🔶', '🔷', '⚫', '🔺'],
        'fruit': ['🍎', '🍊', '🍌', '🍇', '🍓'],
        'animal': ['🐶', '🐱', '🐰', '🐸', '🐼'],
        'weather': ['☀️', '🌧️', '⛈️', '🌈', '❄️']
      };
      
      // 서버에 기본값 저장
      await UserSettingsService.updateUserSettings(
        emoticonCategories: defaultCategories,
        lastSelectedEmotionCategory: 'shape',
      );
      
      // AppState 업데이트
      await appState.setEmoticonCategories(defaultCategories);
      await appState.setLastSelectedEmotionCategory('shape');
      
      setState(() {
        _emojiCategories = Map<Emotion, List<String>>.from(
          defaultCategories.map((key, value) => 
            MapEntry(Emotion.values.firstWhere((e) => e.name == key), value)
          )
        );
        // 선택된 카테고리를 도형으로 변경
        _selectedEmotion = Emotion.shape;
      });
    } catch (e) {
      print('이모티콘 카테고리 초기화 실패: $e');
      rethrow;
    }
  }

  // 행복 지수 계산
  Map<String, dynamic> _calculateHappinessData(AppState appState) {
    final now = DateTime.now();
    final currentMonthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}-';
    
    final currentMonthData = appState.emotionData.entries
        .where((entry) => entry.key.startsWith(currentMonthPrefix) && entry.value.entry != null)
        .toList();
    
    final totalDays = currentMonthData.length;
    
    if (totalDays == 0) {
      return {
        'totalDays': 0,
        'happinessIndex': 50,
        'happinessEmoji': '🐸',
        'happinessColor': const Color(0xFFEAB308),
        'gaugeAngle': 90.0
      };
    }
    
    final averageScore = currentMonthData.fold(0, (sum, entry) => 
        sum + _emotionScores[entry.value.emotion]!) / totalDays;
    
    final happinessIndex = averageScore.round();
    final gaugeAngle = 180 - (happinessIndex / 100) * 180; // 180 to 0 degrees
    final happinessEmoji = happinessIndex >= 51 ? '🐶' : happinessIndex >= 21 ? '🐸' : '🐱';
    
    // 행복 색상 계산 (빨강에서 초록으로)
    final red = max(0, 255 - (happinessIndex * 2.55));
    final green = min(255, happinessIndex * 2.55);
    final happinessColor = Color.fromARGB(255, red.round(), green.round(), 0);
    
    return {
      'totalDays': totalDays,
      'happinessIndex': happinessIndex,
      'happinessEmoji': happinessEmoji,
      'happinessColor': happinessColor,
      'gaugeAngle': gaugeAngle
    };
  }



  // 달력 날짜 계산을 위한 헬퍼 함수들
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int _getFirstWeekdayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday % 7;
  }

  List<_CalendarDay> _getCalendarDays(int year, int month) {
    final List<_CalendarDay> days = [];
    
    // 이전 달의 마지막 날짜들
    final prevMonth = month - 1;
    final prevYear = prevMonth == 0 ? year - 1 : year;
    final prevMonthDays = _getDaysInMonth(prevYear, prevMonth == 0 ? 12 : prevMonth);
    final firstWeekday = _getFirstWeekdayOfMonth(year, month);
    
    for (var i = 0; i < firstWeekday; i++) {
      days.add(_CalendarDay(
        date: DateTime(prevYear, prevMonth == 0 ? 12 : prevMonth, prevMonthDays - firstWeekday + i + 1),
        isCurrentMonth: false,
      ));
    }
    
    // 현재 달의 날짜들
    final daysInMonth = _getDaysInMonth(year, month);
    for (var i = 1; i <= daysInMonth; i++) {
      days.add(_CalendarDay(
        date: DateTime(year, month, i),
        isCurrentMonth: true,
      ));
    }
    
    // 다음 달의 시작 날짜들
    final nextMonth = month + 1;
    final nextYear = nextMonth == 13 ? year + 1 : year;
    final remainingDays = 42 - days.length; // 6주 * 7일 = 42일로 맞추기
    
    for (var i = 1; i <= remainingDays; i++) {
      days.add(_CalendarDay(
        date: DateTime(nextYear, nextMonth == 13 ? 1 : nextMonth, i),
        isCurrentMonth: false,
      ));
    }
    
    return days;
  }

  // 달력의 top 위치를 계산하는 함수
  double _getCalendarTopPosition() {
    final RenderBox? renderBox = _birthdayInputKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final height = renderBox.size.height;
      return position.dy + height + 4; // 입력 박스 아래 4픽셀 간격
    }
    return 0;
  }

  // 달력의 left 위치를 계산하는 함수
  double _getCalendarLeftPosition() {
    final RenderBox? renderBox = _birthdayInputKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      return position.dx;
    }
    return 0;
  }

  // 프리미엄 카테고리 여부 확인 (모든 카테고리 사용 가능)
  bool _isPremiumCategory(Emotion emotion) {
    return false; // 모든 카테고리를 무료로 사용 가능
  }

  Widget _buildEmojiDialog(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF5EFE6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 448,  // 모달 너비 고정
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '이모티콘 카테고리 설정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isEmojiDialogOpen = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 카테고리 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 도형을 첫 번째로 이동
                _buildCategoryButton(Emotion.shape),
                _buildCategoryButton(Emotion.fruit),
                _buildCategoryButton(Emotion.animal),
                _buildCategoryButton(Emotion.weather),
              ],
            ),
            const SizedBox(height: 24),

            // 선택된 카테고리 제목
            Row(
              children: [
                Text(
                  '${_emotionLabels[_selectedEmotion]} 카테고리 (5개)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
              ],
            ),
            const SizedBox(height: 16),

            // 선택된 이모지들
            Container(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var emoji in _emojiCategories[_selectedEmotion]!)
                    Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 하단 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    try {
                      await _resetToDefault();
                      // 성공 메시지 표시
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이모티콘 카테고리가 초기화되었습니다.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      print('이모티콘 카테고리 초기화 실패: $e');
                      // 오류 메시지 표시
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('초기화 실패: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                  ),
                  child: const Text('기본값으로 초기화'),
                ),
                                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final appState = context.read<AppState>();
                        final categories = _emojiCategories.map((key, value) => 
                          MapEntry(key.name, value)
                        );
                        
                        // 서버에 설정 저장
                        await UserSettingsService.updateUserSettings(
                          emoticonCategories: categories,
                          lastSelectedEmotionCategory: _selectedEmotion.name,
                        );
                        
                        // AppState 업데이트
                        await appState.setEmoticonCategories(categories);
                        await appState.setLastSelectedEmotionCategory(_selectedEmotion.name);
                        
                        setState(() {
                          _isEmojiDialogOpen = false;
                        });
                        
                        // 성공 메시지 표시
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('이모티콘 카테고리가 저장되었습니다.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        print('이모티콘 카테고리 저장 실패: $e');
                        // 오류 메시지 표시
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('저장 실패: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB68D6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('완료'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리 버튼 위젯
  Widget _buildCategoryButton(Emotion emotion) {
    return TextButton(
      onPressed: () => _handleCategorySelect(emotion),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          _selectedEmotion == emotion 
            ? const Color(0xFFB68D6B)
            : Colors.transparent,
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _emotionLabels[emotion]!,
            style: TextStyle(
              color: _selectedEmotion == emotion ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
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
        final happinessData = _calculateHappinessData(appState);
        
        return Material(
          color: AppColors.background,
          child: Stack(  // SafeArea를 Stack으로 감싸기
            children: [
              SafeArea(
                child: Container(
              padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      AppButton(
                        onPressed: () => appState.handleBackToCalendar(),
                        variant: ButtonVariant.ghost,
                        size: ButtonSize.icon,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: AppColors.calendarDateHover,
                          ),
                          child: const Icon(Icons.arrow_back, size: 20),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          '마이페이지',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.foreground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Profile Section
                          AppCard(
                            backgroundColor: AppColors.calendarBg,
                            borderRadius: BorderRadius.circular(24),
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(appState.userBirthday),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    AppButton(
                                      onPressed: () {
                                        setState(() {
                                          _tempName = _userName;
                                          _tempBirthday = appState.userBirthday;
                                          _isProfileDialogOpen = true;
                                        });
                                      },
                                      variant: ButtonVariant.ghost,
                                      size: ButtonSize.icon,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: AppColors.calendarDateHover,
                                        ),
                                        child: const Icon(Icons.settings, size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Mood Data Section
                          AppCard(
                            backgroundColor: AppColors.calendarBg,
                            borderRadius: BorderRadius.circular(24),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '이번 달 기분 분석',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '총 일기 수',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                    Text(
                                      '${happinessData['totalDays']}일',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Happiness Gauge
                                Center(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 200,
                                        height: 120,
                                        child: CustomPaint(
                                          painter: HappinessGaugePainter(
                                            happinessIndex: happinessData['happinessIndex'],
                                            gaugeAngle: happinessData['gaugeAngle'],
                                            happinessColor: happinessData['happinessColor'],
                                            happinessEmoji: happinessData['happinessEmoji'],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Column(
                                        children: [
                                          Text(
                                            '${happinessData['happinessIndex']}%',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: happinessData['happinessColor'],
                                            ),
                                          ),
                                          Text(
                                            '행복 지수',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Voice Setting
                          AppCard(
                            backgroundColor: AppColors.calendarBg,
                            borderRadius: BorderRadius.circular(24),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'AI 목소리 음성 기능',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Switch(
                                      value: _voiceEnabled,
                                      onChanged: (value) async {
                                        setState(() {
                                          _voiceEnabled = value;
                                        });
                                        await appState.setVoiceEnabled(value);
                                      },
                                      activeColor: AppColors.primary,
                                    ),
                                  ],
                                ),
                                
                                if (_voiceEnabled) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        '음성 볼륨',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${_voiceVolume.round()}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Slider(
                                    value: _voiceVolume,
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    onChanged: (value) async {
                                      setState(() {
                                        _voiceVolume = value;
                                      });
                                      await appState.setVoiceVolume(value.round());
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Emoticon Setting
                          AppCard(
                            backgroundColor: AppColors.calendarBg,
                            borderRadius: BorderRadius.circular(24),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '이모티콘 표시',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '캘린더에 감정 이모티콘을 표시합니다',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: appState.emoticonEnabled,
                                      onChanged: (value) async {
                                        appState.setEmoticonEnabled(value);
                                      },
                                      activeColor: AppColors.primary,
                                    ),
                                  ],
                                ),
                                
                                if (appState.emoticonEnabled) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        '이모티콘 카테고리 관리',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      AppButton(
                                        onPressed: () {
                                          setState(() {
                                            _isEmojiDialogOpen = true;
                                          });
                                        },
                                        variant: ButtonVariant.outline,
                                        child: const Text('편집'),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Quick Preview
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '현재 설정된 카테고리',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.mutedForeground,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.muted.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  _emotionLabels[_selectedEmotion]!,
                                                  style: const TextStyle(fontSize: 12),
                                                ),

                                              ],
                                            ),
                                            Row(
                                              children: [
                                                ...(_emojiCategories[_selectedEmotion]!.take(3).map((emoji) => 
                                                  Text(emoji, style: const TextStyle(fontSize: 12)))),
                                                if (_emojiCategories[_selectedEmotion]!.length > 3)
                                                  Text(
                                                    '+${_emojiCategories[_selectedEmotion]!.length - 3}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.mutedForeground,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Logout Button
                          AppCard(
                            backgroundColor: AppColors.calendarBg,
                            borderRadius: BorderRadius.circular(24),
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        InkWell(
                                          onTap: appState.handleLogout,
                                          child: Container(
                              width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFA97B56),  // 진한 갈색으로 변경
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                    '로그아웃',
                                    style: TextStyle(
                                      fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.foreground,  // 텍스트 색상을 흰색으로 변경
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 프로필 설정 모달
              if (_isProfileDialogOpen)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: Material(
                        color: AppColors.calendarBg,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 헤더
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '프로필 설정',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() {
                                      _isProfileDialogOpen = false;
                                    }),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // 이름 입력
                              const Text(
                                '이름',
                                style: TextStyle(
                                  fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: TextEditingController(),  // 초기값 제거
                                onChanged: (value) => _tempName = value,
                                decoration: InputDecoration(
                                  hintText: '이름을 입력하세요.',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 생일 선택
                              const Text(
                                '생일',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 날짜 표시 박스
                              InkWell(
                                key: _birthdayInputKey, // 위치 추적을 위한 키 추가
                                onTap: () {
                                  setState(() {
                                    _isCalendarVisible = !_isCalendarVisible;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _tempBirthday != null 
                                          ? '${_tempBirthday!.year}년 ${_tempBirthday!.month}월 ${_tempBirthday!.day}일'
                                          : '생일을 선택하세요.',
                                        style: TextStyle(
                                          color: _tempBirthday == null
                                              ? AppColors.mutedForeground
                                              : AppColors.foreground,
                            ),
                          ),
                        ],
                      ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // 버튼
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AppButton(
                                    onPressed: () => _handleCancelProfile(appState),
                                    variant: ButtonVariant.ghost,
                                    child: const Text('취소'),
                                  ),
                                  const SizedBox(width: 8),
                                  AppButton(
                                    onPressed: () => _handleSaveProfile(appState),
                                    variant: ButtonVariant.primary,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: const Text('저장'),
                    ),
                  ),
                ],
              ),
                            ],
            ),
          ),
                      ),
                    ),
                  ),
                ),
              // 달력 팝오버
              if (_isCalendarVisible && _isProfileDialogOpen)
                Positioned(
                  top: _getCalendarTopPosition(),
                  left: _getCalendarLeftPosition(),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 320,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 월 선택 헤더
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {
                                  setState(() {
                                    _currentCalendarDate = DateTime(
                                      _currentCalendarDate.year,
                                      _currentCalendarDate.month - 1,
                                    );
                                  });
      },
                              ),
                              Text(
                                '${_currentCalendarDate.year}년 ${_currentCalendarDate.month}월',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  setState(() {
                                    _currentCalendarDate = DateTime(
                                      _currentCalendarDate.year,
                                      _currentCalendarDate.month + 1,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 요일 헤더
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              Text('일', style: TextStyle(fontSize: 12, color: Colors.red)),
                              Text('월', style: TextStyle(fontSize: 12)),
                              Text('화', style: TextStyle(fontSize: 12)),
                              Text('수', style: TextStyle(fontSize: 12)),
                              Text('목', style: TextStyle(fontSize: 12)),
                              Text('금', style: TextStyle(fontSize: 12)),
                              Text('토', style: TextStyle(fontSize: 12, color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 날짜 그리드
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            itemCount: 42,
                            itemBuilder: (context, index) {
                              final days = _getCalendarDays(_currentCalendarDate.year, _currentCalendarDate.month);
                              final day = days[index];
                              final isSelected = _tempBirthday != null &&
                                  day.date.year == _tempBirthday!.year &&
                                  day.date.month == _tempBirthday!.month &&
                                  day.date.day == _tempBirthday!.day;
                              final isWeekend = day.date.weekday == DateTime.saturday || 
                                              day.date.weekday == DateTime.sunday;
                              
                              return TextButton(
                                onPressed: () {
                                  if (day.isCurrentMonth) {
                                    setState(() {
                                      _tempBirthday = day.date;
                                    });
                                  } else {
                                    setState(() {
                                      _currentCalendarDate = DateTime(day.date.year, day.date.month, 1);
                                    });
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  backgroundColor: isSelected 
                                    ? AppColors.primary.withOpacity(0.1)
                                    : day.isCurrentMonth ? null : AppColors.muted.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.date.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: !day.isCurrentMonth 
                                        ? AppColors.mutedForeground.withOpacity(0.5)
                                        : isSelected
                                          ? AppColors.primary
                                          : isWeekend
                                            ? day.date.weekday == DateTime.sunday ? Colors.red : Colors.blue
                                            : AppColors.foreground,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // 이모티콘 설정 모달
              if (_isEmojiDialogOpen)
                _buildEmojiDialog(context),
            ],
          ),
        );
      },
    );
  }

  // 카테고리 탭 위젯
  Widget _buildCategoryTab(Emotion emotion, String label, AppState appState) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedEmotion = emotion;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedEmotion == emotion 
            ? AppColors.primary 
            : AppColors.muted.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: _selectedEmotion == emotion 
                  ? Colors.white 
                  : AppColors.mutedForeground,
                fontWeight: _selectedEmotion == emotion 
                  ? FontWeight.bold 
                  : FontWeight.normal,
              ),
            ),

          ],
        ),
      ),
    );
  }

  // 이모티콘 아이템 위젯
  Widget _buildEmojiItem(String emoji) {
    final isSelected = _emojiCategories[_selectedEmotion]!.contains(emoji);
    
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _emojiCategories[_selectedEmotion]!.remove(emoji);
          } else {
            if (_emojiCategories[_selectedEmotion]!.length < 5) { // 최대 5개까지만 선택 가능
              _emojiCategories[_selectedEmotion]!.add(emoji);
            }
          }
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected 
            ? AppColors.primary.withOpacity(0.1) 
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
              ? AppColors.primary 
              : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}

// 행복 지수 게이지를 그리는 CustomPainter
class HappinessGaugePainter extends CustomPainter {
  final int happinessIndex;
  final double gaugeAngle;
  final Color happinessColor;
  final String happinessEmoji;

  HappinessGaugePainter({
    required this.happinessIndex,
    required this.gaugeAngle,
    required this.happinessColor,
    required this.happinessEmoji,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = 80.0;
    
    // Gradient colors for the gauge
    final gradient = LinearGradient(
      colors: [
        const Color(0xFFDC2626), // Red for unhappy
        const Color(0xFFEAB308), // Yellow for neutral
        const Color(0xFF22C55E), // Green for happy
      ],
    );
    
    // Draw gauge background (semicircle with gradient)
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Start from left (180 degrees)
      pi, // Draw half circle (180 degrees)
      false,
      paint..color = paint.color.withOpacity(0.6),
    );
    
    // Draw needle
    final needleAngle = gaugeAngle * pi / 180;
    final needleEnd = Offset(
      center.dx + 60 * cos(needleAngle),
      center.dy - 60 * sin(needleAngle),
    );
    
    final needlePaint = Paint()
      ..color = happinessColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(center, needleEnd, needlePaint);
    
    // Draw center dot
    final centerPaint = Paint()..color = happinessColor;
    canvas.drawCircle(center, 6, centerPaint);
    
    // Draw labels
    final textStyle = TextStyle(
      fontSize: 12,
      color: AppColors.mutedForeground,
    );
    
    final unhappyPainter = TextPainter(
      text: TextSpan(text: '불행', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    unhappyPainter.layout();
    unhappyPainter.paint(canvas, Offset(20, size.height - 10));
    
    final happyPainter = TextPainter(
      text: TextSpan(text: '행복', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    happyPainter.layout();
    happyPainter.paint(canvas, Offset(size.width - 40, size.height - 10));
    
    // Draw emoji on needle tip
    final emojiPainter = TextPainter(
      text: TextSpan(
        text: happinessEmoji,
        style: const TextStyle(fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    );
    emojiPainter.layout();
    emojiPainter.paint(
      canvas,
      Offset(
        center.dx + 70 * cos(needleAngle) - emojiPainter.width / 2,
        center.dy - 70 * sin(needleAngle) - emojiPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 

// 달력 날짜를 표현하는 클래스
class _CalendarDay {
  final DateTime date;
  final bool isCurrentMonth;

  _CalendarDay({
    required this.date,
    required this.isCurrentMonth,
  });
} 