import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_settings_service.dart';
import '../services/diary_service.dart';

enum Emotion { 
  // 기본 감정들
  angry, anxious, calm, confident, confused, determined, 
  excited, happy, love, neutral, sad, touched,
  // 카테고리들
  shape, fruit, animal, weather
}

class EmotionData {
  final Emotion emotion;
  final String emoji;
  final String? entry;
  final List<String>? images;

  EmotionData({
    required this.emotion,
    required this.emoji,
    this.entry,
    this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion.name,
      'emoji': emoji,
      'entry': entry,
      'images': images,
    };
  }

  factory EmotionData.fromJson(Map<String, dynamic> json) {
    // images 처리: List<Map>에서 filename만 추출하여 List<String>으로 변환
    List<String>? images;
    final imagesRaw = json['images'];
    if (imagesRaw is List) {
      images = imagesRaw
          .map((e) => e is Map && e['filename'] != null ? e['filename'] as String : null)
          .whereType<String>()
          .toList();
    }
    
    return EmotionData(
      emotion: Emotion.values.firstWhere((e) => e.name == json['emotion']),
      emoji: json['emoji'],
      entry: json['entry'],
      images: images,
    );
  }
}

enum CurrentView { calendar, entry, mypage }

enum UserSubscription { normal, premium }

class AppState extends ChangeNotifier {
  bool _isAuthenticated = false;
  CurrentView _currentView = CurrentView.calendar;
  String _selectedDate = '';
  UserSubscription _userSubscription = UserSubscription.normal;
  DateTime? _userBirthday;
  bool _emoticonEnabled = true;
  bool _voiceEnabled = true;
  int _voiceVolume = 50;
  String _userName = '사용자';
  String _userEmail = '';
  String _accessToken = '';
  Emotion _selectedEmoticonCategory = Emotion.neutral;
  String _lastSelectedEmotionCategory = 'shape';
  
  Map<String, List<String>> _emoticonCategories = {
    'shape': [
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fhappy_shape-removebg-preview.png?alt=media&token=5a8aa9dd-6ea5-4132-95af-385340846076',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fsad_shape-removebg-preview.png?alt=media&token=acbc7284-1126-4428-a3b2-f8b6e7932b98',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa',
    ],
    'fruit': [
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fhappy_fruit-removebg-preview.png?alt=media&token=d10a503b-fee7-4bc2-b141-fd4b33dae1f1',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fsad_fruit-removebg-preview.png?alt=media&token=e9e0b0f7-6590-4209-a7d1-26377eb33c05',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fexcited_fruit-removebg-preview.png?alt=media&token=0284bce2-aa88-4766-97fb-5d5d2248cf31',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fangry_fruit-removebg-preview.png?alt=media&token=679778b9-5a1b-469a-8e86-b01585cb1ee2',
    ],
    'animal': [
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fhappy_animal-removebg-preview.png?alt=media&token=66ff8e2d-d941-4fd7-9d7f-9766db03cbd5',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fsad_animal-removebg-preview.png?alt=media&token=04c99bd8-8ad4-43de-91cd-3b7354780677',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fexcited_animal-removebg-preview.png?alt=media&token=48442937-5504-4392-88a9-039aef405f14',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fangry_animal-removebg-preview.png?alt=media&token=9bde31db-8801-4af0-9368-e6ce4a35fbac',
    ],
    'weather': [
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fhappy_weather-removebg-preview.png?alt=media&token=fd77e998-6f47-459a-bd1c-458e309fed41',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fsad_weather-removebg-preview.png?alt=media&token=aa972b9a-8952-4dc7-abe7-692ec7be0d16',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fexcited_weather-removebg-preview.png?alt=media&token=5de71f38-1178-4e3c-887e-af07547caba9',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fangry_weather-removebg-preview.png?alt=media&token=2f4c6212-697d-49b7-9d5e-ae1f2b1fa84e',
    ]
  };
  
  final Map<String, EmotionData> _emotionData = {};

  static const Map<Emotion, String> emotionEmojis = {
    Emotion.angry: '😠',
    Emotion.anxious: '😰',
    Emotion.calm: '😌',
    Emotion.confident: '😎',
    Emotion.confused: '😕',
    Emotion.determined: '😤',
    Emotion.excited: '🤩',
    Emotion.happy: '😊',
    Emotion.love: '🥰',
    Emotion.neutral: '😐',
    Emotion.sad: '😢',
    Emotion.touched: '🥺',
  };

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  CurrentView get currentView => _currentView;
  String get selectedDate => _selectedDate;
  UserSubscription get userSubscription => _userSubscription;
  DateTime? get userBirthday => _userBirthday;
  bool get emoticonEnabled => _emoticonEnabled;
  bool get voiceEnabled => _voiceEnabled;
  int get voiceVolume => _voiceVolume;
  Map<String, EmotionData> get emotionData => Map.unmodifiable(_emotionData);
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get accessToken => _accessToken;
  Emotion get selectedEmoticonCategory => _selectedEmoticonCategory;
  Map<String, List<String>> get emoticonCategories => Map.unmodifiable(_emoticonCategories);
  String get lastSelectedEmotionCategory => _lastSelectedEmotionCategory;

  AppState() {
    _loadEmoticonSetting();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    // 임시로 항상 인증 상태로 설정 (테스트용)
    setAuthenticated(true);
    print('AppState: 인증 상태를 true로 설정했습니다.');
    
    // 원래 코드는 주석 처리
    /*
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      // 토큰이 있으면 인증 상태로 설정하되, 실제 API 호출 시 오류가 발생하면 로그아웃 처리
      setAuthenticated(true);
      try {
        await _loadUserSettings();
      } catch (e) {
        print('토큰이 있지만 인증 실패: $e');
        // 인증 실패 시 로그아웃 처리
        await handleLogout();
      }
    }
    */
  }

  void _loadEmoticonSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _emoticonEnabled = prefs.getBool('emoticonEnabled') ?? true;
    notifyListeners();
  }

  // 사용자 설정 로드
  Future<void> _loadUserSettings() async {
    try {
      final settings = await UserSettingsService.getUserSettings();
      _emoticonEnabled = settings['emoticon_enabled'] ?? true;
      _voiceEnabled = settings['voice_enabled'] ?? true;
      _voiceVolume = settings['voice_volume'] ?? 50;
      _emoticonCategories = Map<String, List<String>>.from(
        settings['emoticon_categories'] ?? UserSettingsService.defaultSettings['emoticon_categories']
      );
      _lastSelectedEmotionCategory = settings['last_selected_emotion_category'] ?? 'shape';
      notifyListeners();
    } catch (e) {
      print('사용자 설정 로드 실패: $e');
    }
  }

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    if (value) {
      _loadUserSettings().then((_) {
        loadDiaryData().then((_) {
          notifyListeners();
        });
      });
    } else {
      notifyListeners();
    }
  }

  void setCurrentView(CurrentView view) {
    _currentView = view;
    notifyListeners();
  }

  void setSelectedDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setUserSubscription(UserSubscription subscription) {
    _userSubscription = subscription;
    notifyListeners();
  }

  void setUserBirthday(DateTime? birthday) {
    _userBirthday = birthday;
    notifyListeners();
  }

  void setEmoticonEnabled(bool enabled) async {
    _emoticonEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emoticonEnabled', enabled);
    
    try {
      await UserSettingsService.updateUserSettings(emoticonEnabled: enabled);
    } catch (e) {
      print('이모티콘 설정 업데이트 실패: $e');
    }
    
    notifyListeners();
  }

  // 음성 설정 업데이트
  Future<void> setVoiceEnabled(bool enabled) async {
    _voiceEnabled = enabled;
    try {
      await UserSettingsService.updateUserSettings(voiceEnabled: enabled);
    } catch (e) {
      print('음성 설정 업데이트 실패: $e');
    }
    notifyListeners();
  }

  // 음성 볼륨 설정 업데이트
  Future<void> setVoiceVolume(int volume) async {
    _voiceVolume = volume;
    try {
      await UserSettingsService.updateUserSettings(voiceVolume: volume);
    } catch (e) {
      print('음성 볼륨 설정 업데이트 실패: $e');
    }
    notifyListeners();
  }

  // 이모티콘 카테고리 설정
  Future<void> setEmoticonCategories(Map<String, List<String>> categories) async {
    _emoticonCategories = Map<String, List<String>>.from(categories);
    try {
      await UserSettingsService.updateUserSettings(emoticonCategories: categories);
    } catch (e) {
      print('이모티콘 카테고리 설정 업데이트 실패: $e');
    }
    notifyListeners();
  }

  // 마지막 선택된 이모티콘 카테고리 설정
  Future<void> setLastSelectedEmotionCategory(String category) async {
    _lastSelectedEmotionCategory = category;
    try {
      await UserSettingsService.updateUserSettings(lastSelectedEmotionCategory: category);
    } catch (e) {
      print('마지막 선택된 이모티콘 카테고리 설정 업데이트 실패: $e');
    }
    notifyListeners();
  }

  // 서버 저장 없이 설정 업데이트 (마이페이지에서 사용)
  void updateSettingsFromServer({
    bool? voiceEnabled,
    int? voiceVolume,
    Map<String, List<String>>? emoticonCategories,
    String? lastSelectedEmotionCategory,
  }) {
    if (voiceEnabled != null) _voiceEnabled = voiceEnabled;
    if (voiceVolume != null) _voiceVolume = voiceVolume;
    if (emoticonCategories != null) _emoticonCategories = Map<String, List<String>>.from(emoticonCategories);
    if (lastSelectedEmotionCategory != null) _lastSelectedEmotionCategory = lastSelectedEmotionCategory;
    notifyListeners();
  }

  // 이모티콘 카테고리 초기화
  Future<void> resetEmoticonCategories() async {
    _emoticonCategories = {
      'shape': ['⭐', '🔶', '🔷', '⚫', '🔺'],
      'fruit': ['🍎', '🍊', '🍌', '🍇', '🍓'],
      'animal': ['🐶', '🐱', '🐰', '🐸', '🐼'],
      'weather': ['☀️', '🌧️', '⛈️', '🌈', '❄️']
    };
    try {
      await UserSettingsService.updateUserSettings(emoticonCategories: _emoticonCategories);
    } catch (e) {
      print('이모티콘 카테고리 초기화 실패: $e');
    }
    notifyListeners();
  }

  // 일기 데이터 로드
  Future<void> loadDiaryData() async {
    try {
      final diaryData = await DiaryService.getDiaryEntries();
      // 기존 데이터 초기화
      _emotionData.clear();
      
      // 일기 데이터를 _emotionData에 병합
      for (final entry in diaryData) {
        final date = entry['date'] as String;
        final emotion = Emotion.values.firstWhere(
          (e) => e.name == entry['emotion'],
          orElse: () => Emotion.neutral,
        );
        // 백엔드에서 가져온 이모지 URL 사용 (Firebase URL)
        final emoji = entry['emoji'] as String? ?? emotionEmojis[emotion]!;
        final diaryEntry = entry['entry'] as String?;
        
        // images 처리: List<Map>에서 filename만 추출하여 List<String>으로 변환
        List<String>? images;
        final imagesRaw = entry['images'];
        if (imagesRaw is List) {
          images = imagesRaw
              .map((e) => e is Map && e['filename'] != null ? e['filename'] as String : null)
              .whereType<String>()
              .toList();
        }
        
        _emotionData[date] = EmotionData(
          emotion: emotion,
          emoji: emoji,
          entry: diaryEntry,
          images: images,
        );
      }
      notifyListeners();
    } catch (e) {
      print('일기 데이터 로드 실패: $e');
    }
  }

  void saveDiary(String entry, Emotion emotion, List<String>? images) {
    // 사용자 설정에서 선택된 카테고리의 이모지 URL 가져오기
    final selectedCategory = _lastSelectedEmotionCategory;
    final categoryEmojis = _emoticonCategories[selectedCategory] ?? [];
    final emojiUrl = categoryEmojis.isNotEmpty ? categoryEmojis[0] : 
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5';
    
    _emotionData[_selectedDate] = EmotionData(
      emotion: emotion,
      emoji: emojiUrl,
      entry: entry,
      images: images,
    );
    notifyListeners();
  }

  void handleDateSelect(String date) {
    print('AppState.handleDateSelect called: $date');
    setSelectedDate(date);
    print('Selected date set to: $date');
    setCurrentView(CurrentView.entry);
    print('Current view set to: entry');
  }

  void handleBackToCalendar() {
    setCurrentView(CurrentView.calendar);
  }

  void handleSettingsClick() {
    setCurrentView(CurrentView.mypage);
  }

  void setUserInfo(String name, String email, String token, {String? birthday}) {
    print('AppState.setUserInfo 호출됨: name=$name, email=$email, birthday=$birthday');
    print('이전 사용자명: $_userName');
    _userName = name;
    _userEmail = email;
    _accessToken = token;
    if (birthday != null) {
      try {
        _userBirthday = DateTime.parse(birthday);
      } catch (e) {
        print('생일 파싱 오류: $e');
        _userBirthday = null;
      }
    }
    print('설정된 사용자명: $_userName');
    notifyListeners();
  }

  void setSelectedEmoticonCategory(Emotion category) {
    _selectedEmoticonCategory = category;
    notifyListeners();
  }

  void handleLogin() {
    setAuthenticated(true);
  }

  Future<void> handleLogout() async {
    // 토큰 및 사용자 정보 정리
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('birthday');
    
    setAuthenticated(false);
    setCurrentView(CurrentView.calendar);
    _userName = '사용자';
    _userEmail = '';
    _accessToken = '';
    notifyListeners();
  }
} 