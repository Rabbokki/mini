import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../ui/card.dart';
import '../ui/button.dart';
import '../services/user_service.dart';
import '../services/user_settings_service.dart';
import 'dart:math' as math;

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
  
  // Emoji categories state (Firebase URL로 표시)
  Map<Emotion, List<String>> _emojiCategories = {
    Emotion.shape: ['https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5'],
    Emotion.fruit: ['https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39'],
    Emotion.animal: ['https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f'],
    Emotion.weather: ['https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f']
  };
  
  Emotion _selectedEmotion = Emotion.shape;

  final Map<Emotion, String> _emotionLabels = {
    Emotion.neutral: '기본',
    Emotion.happy: '행복',
    Emotion.sad: '슬픔',
    Emotion.excited: '신남',
    Emotion.angry: '화남',
    Emotion.love: '사랑',
    // 카테고리들
    Emotion.shape: '도형',
    Emotion.fruit: '과일',
    Emotion.animal: '동물',
    Emotion.weather: '날씨'
  };

  final Map<Emotion, int> _emotionScores = {
    Emotion.neutral: 70,
    Emotion.happy: 80,
    Emotion.sad: 85,
    Emotion.excited: 75,
    Emotion.angry: 60,
    Emotion.love: 90,
    // 카테고리들은 기본 점수 설정
    Emotion.shape: 70,
    Emotion.fruit: 70,
    Emotion.animal: 70,
    Emotion.weather: 70
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

  // 카테고리별 사용 가능한 Firebase 이미지 URL 맵
  final Map<Emotion, List<String>> _availableEmoticonsByCategory = {
    Emotion.shape: [
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfident_shape-removebg-preview.png?alt=media&token=8ab02bc8-8569-42ff-b78d-b9527f15d0af',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fdetermined_shape-removebg-preview.png?alt=media&token=69eb4cf0-ab61-4f5e-add3-b2148dc2a108',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fhappy_shape-removebg-preview.png?alt=media&token=5a8aa9dd-6ea5-4132-95af-385340846076',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fcalm_shape-removebg-preview.png?alt=media&token=cdc2fa85-10b7-46f6-881c-dd874c38b3ea',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Flove_shape-removebg-preview.png?alt=media&token=1a7ec74f-4297-42a4-aeb8-97aee1e9ff6c',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fsad_shape-removebg-preview.png?alt=media&token=acbc7284-1126-4428-a3b2-f8b6e7932b98',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Ftouched_shape-removebg-preview.png?alt=media&token=bbb50a1c-90d6-43fd-be40-4be4f51bc1d0',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fanxious_shape-removebg-preview.png?alt=media&token=7859ebac-cd9d-43a3-a42c-aec651d37e6e',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfused_shape-removebg-preview.png?alt=media&token=4794d127-9b61-4c68-86de-8478c4da8fb9'
    ],
    Emotion.fruit: [
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fhappy_fruit-removebg-preview.png?alt=media&token=d10a503b-fee7-4bc2-b141-fd4b33dae1f1',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fcalm_fruit-removebg-preview.png?alt=media&token=839efcad-0022-4cc9-ac38-90175d9026d2',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Flove_fruit-removebg-preview.png?alt=media&token=ba7857c6-5afd-48e0-addd-7b3f54583c15',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fexcited_fruit-removebg-preview.png?alt=media&token=0284bce2-aa88-4766-97fb-5d5d2248cf31',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fangry_fruit-removebg-preview.png?alt=media&token=679778b9-5a1b-469a-8e86-b01585cb1ee2',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fconfident_fruit-removebg-preview.png?alt=media&token=6edcc903-8d78-4dd9-bcdd-1c6b26645044',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fdetermined_fruit-removebg-preview.png?alt=media&token=ed288879-86c4-4d6d-946e-477f2aafc3ce',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fsad_fruit-removebg-preview.png?alt=media&token=e9e0b0f7-6590-4209-a7d1-26377eb33c05',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Ftouched_fruit-removebg-preview.png?alt=media&token=c69dee6d-7d53-4af7-a884-2f751aecbe42',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fanxious_fruit-removebg-preview.png?alt=media&token=be8f8279-2b08-47bf-9856-c39daf5eac40',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fconfused_fruit-removebg-preview.png?alt=media&token=7adfcf22-af7a-4eb1-a225-34875b6540cf'
    ],
    Emotion.animal: [
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fhappy_animal-removebg-preview.png?alt=media&token=66ff8e2d-d941-4fd7-9d7f-9766db03cbd5',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fcalm_animal-removebg-preview.png?alt=media&token=afd7bf65-5150-40e3-8b95-cd956dff113d',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Flove_animal-removebg-preview.png?alt=media&token=e0e2ccbd-b59a-4d09-968a-562208f90be1',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fexcited_animal-removebg-preview.png?alt=media&token=48442937-5504-4392-88a9-039aef405f14',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fangry_animal-removebg-preview.png?alt=media&token=9bde31db-8801-4af0-9368-e6ce4a35fbac',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fconfident__animal-removebg-preview.png?alt=media&token=2983b323-a2a6-40aa-9b6c-a381d944dd27',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fdetermined_animal-removebg-preview.png?alt=media&token=abf05981-4ab3-49b3-ba37-096ab8c22478',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fsad_animal-removebg-preview.png?alt=media&token=04c99bd8-8ad4-43de-91cd-3b7354780677',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Ftouched_animal-removebg-preview.png?alt=media&token=629be9ec-be17-407f-beb0-6b67f09b7036',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fanxious_animal-removebg-preview.png?alt=media&token=bd25e31d-629b-4e79-b95e-019f8c76dac2',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fconfused__animal-removebg-preview.png?alt=media&token=74192a1e-86a7-4eb6-b690-154984c427dc'
    ],
    Emotion.weather: [
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fhappy_weather-removebg-preview.png?alt=media&token=fd77e998-6f47-459a-bd1c-458e309fed41',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fcalm_weather-removebg-preview.png?alt=media&token=7703fd25-fe2b-4750-a415-5f86c4e7b058',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Flove_weather-removebg-preview.png?alt=media&token=2451105b-ab3e-482d-bf9f-12f0a6a69a53',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fexcited_weather-removebg-preview.png?alt=media&token=5de71f38-1178-4e3c-887e-af07547caba9',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fangry_weather-removebg-preview.png?alt=media&token=2f4c6212-697d-49b7-9d5e-ae1f2b1fa84e',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fconfident_weather-removebg-preview.png?alt=media&token=ea30d002-312b-4ae5-ad85-933bbc009dc6',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fdetermined_weather-removebg-preview.png?alt=media&token=0eb8fb3d-22dd-4b4f-8e12-7d830f32be6d',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fsad_weather-removebg-preview.png?alt=media&token=aa972b9a-8952-4dc7-abe7-692ec7be0d16',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Ftouched_weather-removebg-preview.png?alt=media&token=5e224042-72ae-45a4-891a-8e6abdb5285c',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fanxious_weather-removebg-preview.png?alt=media&token=fc718a17-8d8e-4ed1-a78a-891fa9a149d0',
      'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fconfused_weather-removebg-preview.png?alt=media&token=afdfb6bf-2c69-4ef2-97a1-2e5aa67e6fdb'
    ],
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
            _tempBirthday = birthday; // 임시 생일 변수에도 설정
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
      
      // emoticon_categories 타입 변환 수정
      final emoticonCategoriesData = settings['emoticon_categories'] ?? appState.emoticonCategories;
      print('emoticon_categories 데이터: $emoticonCategoriesData'); // 디버깅용
      
      setState(() {
        _voiceEnabled = settings['voice_enabled'] ?? appState.voiceEnabled;
        _voiceVolume = (settings['voice_volume'] ?? appState.voiceVolume).toDouble();
        
        // 안전한 변환을 위한 null 체크 추가
        if (emoticonCategoriesData != null) {
        _emojiCategories = Map<Emotion, List<String>>.from(
          emoticonCategoriesData.map((key, value) {
            // List<dynamic>을 List<String>으로 변환
            final List<String> stringList = (value as List).map((item) => item.toString()).toList();
              print('카테고리 $key의 이모티콘 개수: ${stringList.length}'); // 디버깅용
              print('카테고리 $key의 첫 번째 이모티콘: ${stringList.isNotEmpty ? stringList[0] : "없음"}'); // 디버깅용
            return MapEntry(Emotion.values.firstWhere((e) => e.name == key), stringList);
          })
        );
        }
        
        // 마지막 선택된 카테고리 불러오기
        final lastCategory = settings['last_selected_emotion_category'] ?? appState.lastSelectedEmotionCategory;
        print('마지막 선택된 카테고리: $lastCategory'); // 디버깅용
        print('설정 전 _selectedEmotion: ${_selectedEmotion.name}'); // 디버깅용
        _selectedEmotion = Emotion.values.firstWhere(
          (e) => e.name == lastCategory,
          orElse: () => Emotion.shape
        );
        print('설정 후 _selectedEmotion: ${_selectedEmotion.name}'); // 디버깅용
        print('선택된 카테고리의 이모티콘 개수: ${_emojiCategories[_selectedEmotion]?.length ?? 0}'); // 디버깅용
      });
      
      // AppState도 업데이트 (서버 저장 없이)
      if (emoticonCategoriesData != null) {
      final emoticonCategoriesForAppState = _emojiCategories.map((key, value) => MapEntry(key.name, value));
      appState.updateSettingsFromServer(
        voiceEnabled: _voiceEnabled,
        voiceVolume: _voiceVolume.toInt(),
        emoticonCategories: emoticonCategoriesForAppState,
        lastSelectedEmotionCategory: _selectedEmotion.name,
      );
      }
      
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
      // 백엔드에 프로필 정보 업데이트 (이름은 업데이트하지 않음)
      final birthdayStr = _tempBirthday != null 
          ? UserService.formatBirthday(_tempBirthday)
          : null;
      
      await UserService.updateUserProfile(
        name: _userName, // 기존 이름 유지
        birthday: _tempBirthday,
      );
      
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
            content: Text('생일이 성공적으로 저장되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('생일 저장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleCancelProfile(AppState appState) {
    setState(() {
      _tempBirthday = appState.userBirthday;
      _isProfileDialogOpen = false;
    });
  }

  // 이모티콘 개별 선택 기능 제거 - 카테고리만 선택 가능

  void _handleCategorySelect(Emotion emotion, AppState appState) async {
    setState(() {
      _selectedEmotion = emotion;
      // 선택된 카테고리의 모든 이모티콘을 자동으로 설정
      _emojiCategories[emotion] = List<String>.from(_availableEmoticonsByCategory[emotion] ?? []);
    });
    // AppState에 선택된 카테고리 저장
    appState.setSelectedEmoticonCategory(emotion);
    // AppState에 마지막 선택된 카테고리 저장
    await context.read<AppState>().setLastSelectedEmotionCategory(emotion.name);
  }

  Future<void> _resetToDefault() async {
    try {
      final appState = context.read<AppState>();
      
      // 기본값으로 설정
      final defaultCategories = {
        'shape': ['https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5'],
        'fruit': ['https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39'],
        'animal': ['https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f'],
        'weather': ['https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f']
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
    
    // 사용자가 선택한 카테고리 가져오기 (현재 선택된 카테고리 우선)
    final selectedCategory = appState.selectedEmoticonCategory;
    
    if (totalDays == 0) {
      // 기본값은 선택된 카테고리의 neutral 이미지
      String defaultEmojiUrl;
      switch (selectedCategory) {
        case Emotion.shape:
          defaultEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5';
          break;
        case Emotion.fruit:
          defaultEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39';
          break;
        case Emotion.animal:
          defaultEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f';
          break;
        case Emotion.weather:
          defaultEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f';
          break;
        default:
          defaultEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5';
          break;
      }
      
      return {
        'totalDays': 0,
        'happinessIndex': 50,
        'happinessEmoji': defaultEmojiUrl,
        'happinessColor': const Color(0xFFEAB308),
        'gaugeAngle': 90.0
      };
    }
    
    final averageScore = currentMonthData.fold(0, (sum, entry) => 
        sum + (_emotionScores[entry.value.emotion] ?? 70)) / totalDays;
    
    final happinessIndex = averageScore.round();
    final gaugeAngle = 180 - (happinessIndex / 100) * 180; // 180 to 0 degrees
    
    // 사용자가 선택한 카테고리에 따른 Firebase 이미지 URL 결정
    String happinessEmojiUrl;
    if (happinessIndex >= 80) {
      // 매우 행복한 경우 - excited 이미지
      switch (selectedCategory) {
        case Emotion.shape:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96';
          break;
        case Emotion.fruit:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fexcited_fruit-removebg-preview.png?alt=media&token=0284bce2-aa88-4766-97fb-5d5d2248cf31';
          break;
        case Emotion.animal:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fexcited_animal-removebg-preview.png?alt=media&token=48442937-5504-4392-88a9-039aef405f14';
          break;
        case Emotion.weather:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fexcited_weather-removebg-preview.png?alt=media&token=5de71f38-1178-4e3c-887e-af07547caba9';
          break;
        default:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96';
          break;
      }
    } else if (happinessIndex >= 60) {
      // 행복한 경우 - happy 이미지
      switch (selectedCategory) {
        case Emotion.shape:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fhappy_shape-removebg-preview.png?alt=media&token=5a8aa9dd-6ea5-4132-95af-385340846076';
          break;
        case Emotion.fruit:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fhappy_fruit-removebg-preview.png?alt=media&token=d10a503b-fee7-4bc2-b141-fd4b33dae1f1';
          break;
        case Emotion.animal:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fhappy_animal-removebg-preview.png?alt=media&token=66ff8e2d-d941-4fd7-9d7f-9766db03cbd5';
          break;
        case Emotion.weather:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fhappy_weather-removebg-preview.png?alt=media&token=fd77e998-6f47-459a-bd1c-458e309fed41';
          break;
        default:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fhappy_shape-removebg-preview.png?alt=media&token=5a8aa9dd-6ea5-4132-95af-385340846076';
          break;
      }
    } else if (happinessIndex >= 40) {
      // 보통인 경우 - neutral 이미지
      switch (selectedCategory) {
        case Emotion.shape:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5';
          break;
        case Emotion.fruit:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39';
          break;
        case Emotion.animal:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f';
          break;
        case Emotion.weather:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f';
          break;
        default:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5';
          break;
      }
    } else if (happinessIndex >= 20) {
      // 슬픈 경우 - sad 이미지
      switch (selectedCategory) {
        case Emotion.shape:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fsad_shape-removebg-preview.png?alt=media&token=acbc7284-1126-4428-a3b2-f8b6e7932b98';
          break;
        case Emotion.fruit:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fsad_fruit-removebg-preview.png?alt=media&token=e9e0b0f7-6590-4209-a7d1-26377eb33c05';
          break;
        case Emotion.animal:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fsad_animal-removebg-preview.png?alt=media&token=04c99bd8-8ad4-43de-91cd-3b7354780677';
          break;
        case Emotion.weather:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fsad_weather-removebg-preview.png?alt=media&token=aa972b9a-8952-4dc7-abe7-692ec7be0d16';
          break;
        default:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fsad_shape-removebg-preview.png?alt=media&token=acbc7284-1126-4428-a3b2-f8b6e7932b98';
          break;
      }
    } else {
      // 매우 슬픈 경우 - angry 이미지
      switch (selectedCategory) {
        case Emotion.shape:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa';
          break;
        case Emotion.fruit:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fangry_fruit-removebg-preview.png?alt=media&token=679778b9-5a1b-469a-8e86-b01585cb1ee2';
          break;
        case Emotion.animal:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fangry_animal-removebg-preview.png?alt=media&token=9bde31db-8801-4af0-9368-e6ce4a35fbac';
          break;
        case Emotion.weather:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fangry_weather-removebg-preview.png?alt=media&token=2f4c6212-697d-49b7-9d5e-ae1f2b1fa84e';
          break;
        default:
          happinessEmojiUrl = 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa';
          break;
      }
    }
    
    // 행복 색상 계산 (빨강에서 초록으로)
    final red = math.max(0, 255 - (happinessIndex * 2.55));
    final green = math.min(255, happinessIndex * 2.55);
    final happinessColor = Color.fromARGB(255, red.round(), green.round(), 0);
    
    return {
      'totalDays': totalDays,
      'happinessIndex': happinessIndex,
      'happinessEmoji': happinessEmojiUrl,
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

    Widget _buildEmojiDialog(BuildContext context, AppState appState) {
    return Dialog(
      backgroundColor: const Color(0xFFF5EFE6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 448,  // 모달 너비 고정
        height: MediaQuery.of(context).size.height * 0.8, // 화면 높이의 80%로 제한
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '카테고리 선택',
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
            
            // 카테고리 버튼들 - 가로 스크롤
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
              children: [
                  const SizedBox(width: 8), // 왼쪽 여백
                  _buildCategoryButton(Emotion.shape, appState),
                  const SizedBox(width: 8),
                  _buildCategoryButton(Emotion.fruit, appState),
                  const SizedBox(width: 8),
                  _buildCategoryButton(Emotion.animal, appState),
                  const SizedBox(width: 8),
                  _buildCategoryButton(Emotion.weather, appState),
                  const SizedBox(width: 8), // 오른쪽 여백
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 선택된 카테고리 제목
            Row(
              children: [
                Text(
                  '${_emotionLabels[_selectedEmotion]} 카테고리 (${_availableEmoticonsByCategory[_selectedEmotion]?.length ?? 0}개)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 선택된 Firebase 이미지들
            Expanded(
              child: Container(
              padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                      for (var imageUrl in _availableEmoticonsByCategory[_selectedEmotion] ?? [])
                        Container(
                          width: 56,
                          height: 56,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.muted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('다이얼로그 이미지 로딩 실패: $error');
                              return Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.muted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.error,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                              );
                            },
                      ),
                    ),
                ],
              ),
            ),
              ),
            ),
            
            const SizedBox(height: 16),

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
  Widget _buildCategoryButton(Emotion emotion, AppState appState) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80), // 최소 너비 설정
      child: TextButton(
        onPressed: () => _handleCategorySelect(emotion, appState),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(
          _selectedEmotion == emotion 
            ? const Color(0xFFB68D6B)
            : Colors.transparent,
        ),
        padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // 패딩 조정
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
        child: Column( // Row를 Column으로 변경
          mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _emotionLabels[emotion]!,
            style: TextStyle(
              color: _selectedEmotion == emotion ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
                fontSize: 13, // 폰트 크기 조정
            ),
          ),
        ],
        ),
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
                                        child: const Icon(Icons.info_outline, size: 20),
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
                                      Stack(
                                        alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 200,
                                        height: 120,
                                        child: CustomPaint(
                                          painter: HappinessGaugePainter(
                                            happinessIndex: happinessData['happinessIndex'],
                                            gaugeAngle: happinessData['gaugeAngle'],
                                            happinessColor: happinessData['happinessColor'],
                                                happinessEmoji: '', // 이모티콘은 별도로 표시
                                              ),
                                            ),
                                          ),
                                          // 바늘 끝에 이모티콘 표시
                                          Positioned(
                                            left: 100 + 60 * math.cos(happinessData['gaugeAngle'] * math.pi / 180) - 12,
                                            top: 100 - 60 * math.sin(happinessData['gaugeAngle'] * math.pi / 180) - 12,
                                            child: happinessData['happinessEmoji'].toString().startsWith('http')
                                                ? Image.network(
                                                    happinessData['happinessEmoji'],
                                                    width: 24,
                                                    height: 24,
                                                    fit: BoxFit.contain,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration: BoxDecoration(
                                                          color: AppColors.muted,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: const Center(
                                                          child: SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      print('이미지 로딩 실패: $error');
                                                      return Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration: BoxDecoration(
                                                          color: AppColors.muted,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: const Center(
                                                          child: Text(
                                                            '😊',
                                                            style: TextStyle(fontSize: 16),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Text(
                                                    happinessData['happinessEmoji'],
                                                    style: const TextStyle(fontSize: 24),
                                                  ),
                                          ),
                                        ],
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
                                        // 성공 메시지 표시
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(value ? 'AI 음성 기능이 활성화되었습니다.' : 'AI 음성 기능이 비활성화되었습니다.'),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
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
                                      // 성공 메시지 표시
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('음성 볼륨이 ${value.round()}%로 설정되었습니다.'),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      }
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
                                                ...((_emojiCategories[_selectedEmotion] ?? []).take(3).map((emoji) => 
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 4),
                                                    child: Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(
                                                          color: AppColors.border,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(3),
                                                        child: emoji.startsWith('http')
                                                            ? Image.network(
                                                                emoji,
                                                                width: 18,
                                                                height: 18,
                                                                fit: BoxFit.contain,
                                                                loadingBuilder: (context, child, loadingProgress) {
                                                                  if (loadingProgress == null) return child;
                                                                  return Container(
                                                                    width: 18,
                                                                    height: 18,
                                                                    decoration: BoxDecoration(
                                                                      color: AppColors.muted,
                                                                      borderRadius: BorderRadius.circular(3),
                                                                    ),
                                                                    child: const Center(
                                                                      child: SizedBox(
                                                                        width: 12,
                                                                        height: 12,
                                                                        child: CircularProgressIndicator(
                                                                          strokeWidth: 1,
                                                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                errorBuilder: (context, error, stackTrace) {
                                                                  print('미리보기 이미지 로딩 실패: $error');
                                                                  return Container(
                                                                    width: 18,
                                                                    height: 18,
                                                                    decoration: BoxDecoration(
                                                                      color: AppColors.muted,
                                                                      borderRadius: BorderRadius.circular(3),
                                                                    ),
                                                                    child: const Center(
                                                                      child: Text(
                                                                        '😊',
                                                                        style: TextStyle(fontSize: 12),
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                              )
                                                            : Text(emoji, style: const TextStyle(fontSize: 14)),
                                                      ),
                                                    ),
                                                  )
                                                )),
                                                if ((_emojiCategories[_selectedEmotion] ?? []).length > 3)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.muted.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                    '+${(_emojiCategories[_selectedEmotion] ?? []).length - 3}',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                      color: AppColors.mutedForeground,
                                                        fontWeight: FontWeight.w500,
                                                      ),
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
                                '프로필 정보',
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
                              // 이름 표시 (수정 불가)
                              const Text(
                                '이름',
                                style: TextStyle(
                                  fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  color: AppColors.muted.withOpacity(0.1),
                                ),
                                child: Text(
                                  _userName,
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 생일 표시 (수정 불가)
                              const Text(
                                '생일',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(8),
                                  color: AppColors.muted.withOpacity(0.1),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _tempBirthday != null 
                                          ? '${_tempBirthday!.year}년 ${_tempBirthday!.month}월 ${_tempBirthday!.day}일'
                                        : '생일 미설정',
                                        style: TextStyle(
                                        color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // 닫기 버튼만 표시
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AppButton(
                                    onPressed: () => setState(() {
                                      _isProfileDialogOpen = false;
                                    }),
                                    variant: ButtonVariant.primary,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: const Text('닫기'),
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

              // 이모티콘 설정 모달
              if (_isEmojiDialogOpen)
                _buildEmojiDialog(context, appState),
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
      math.pi, // Start from left (180 degrees)
      math.pi, // Draw half circle (180 degrees)
      false,
      paint..color = paint.color.withOpacity(0.6),
    );
    
    // Draw needle
    final needleAngle = gaugeAngle * math.pi / 180;
    final needleEnd = Offset(
      center.dx + 60 * math.cos(needleAngle),
      center.dy - 60 * math.sin(needleAngle),
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
    
    // 이모티콘은 별도로 표시하므로 여기서는 그리지 않음
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