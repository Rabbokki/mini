import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; // 명시적으로 kIsWeb 임포트
import '../models/app_state.dart';
import '../theme.dart';
import '../ui/card.dart';
import '../ui/button.dart';
import 'dart:math';
import '../services/diary_service.dart';
import '../services/stt_service.dart';
import '../services/openai_service.dart';
import '../services/tts_service.dart';
import '../services/audio_recorder.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_settings/app_settings.dart';

typedef SaveDiaryCallback = void Function(String entry, Emotion emotion, List<String>? images);

class EmotionChainItem {
  final String emoji;
  final Emotion type;

  EmotionChainItem({required this.emoji, required this.type});
}

class DiaryEntry extends StatefulWidget {
  final String selectedDate;
  final VoidCallback onBack;
  final SaveDiaryCallback onSave;
  final EmotionData? existingEntry;

  const DiaryEntry({
    super.key,
    required this.selectedDate,
    required this.onBack,
    required this.onSave,
    this.existingEntry,
  });

  @override
  State<DiaryEntry> createState() => _DiaryEntryState();
}

class _DiaryEntryState extends State<DiaryEntry> with TickerProviderStateMixin {
  late TextEditingController _entryController;
  bool _isAnalyzing = false;
  bool _isSaved = false;
  String _aiMessage = '';
  String _currentEmoji = '';
  List<Map<String, dynamic>> _uploadedImages = [];
  bool _isRecording = false;
  int _recordingTime = 0;
  String _recognizedText = '';
  bool _hasText = false;
  bool _isTranscribing = false; // STT 변환 중 상태
  String _partialText = ''; // 부분 인식 텍스트
  String _status = ''; // 녹음 상태 메시지
  bool _isEditMode = false; // 수정 모드 여부
  String? _currentPostId; // 현재 일기의 post_id

  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  final _diaryService = DiaryService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _recordingTimer;
  Timer? _statusTimer;

  final List<EmotionChainItem> emotionChain = [
    EmotionChainItem(emoji: '🍎', type: Emotion.fruit),
    EmotionChainItem(emoji: '🐶', type: Emotion.animal),
    EmotionChainItem(emoji: '⭐', type: Emotion.shape),
    EmotionChainItem(emoji: '☀️', type: Emotion.weather),
    EmotionChainItem(emoji: '🍇', type: Emotion.fruit),
    EmotionChainItem(emoji: '🐱', type: Emotion.animal),
  ];

  // 감정에 따른 이모티콘 매핑 (Firebase URL)
  final Map<Emotion, String> emotionEmojis = {
    Emotion.fruit: 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39',
    Emotion.animal: 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f',
    Emotion.shape: 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5',
    Emotion.weather: 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f',
  };

  String? _ttsAudioUrl;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isTtsLoading = false;
  bool _isMuted = false;
  bool _isTtsPlaying = false;

  // 감정+카테고리별 이모티콘 URL 반환 함수 추가
  String getCategoryEmoji(Emotion emotion, Emotion selectedCategory) {
    switch (emotion) {
      case Emotion.excited:
        switch (selectedCategory) {
          case Emotion.shape:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96';
          case Emotion.fruit:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fexcited_fruit-removebg-preview.png?alt=media&token=0284bce2-aa88-4766-97fb-5d5d2248cf31';
          case Emotion.animal:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fexcited_animal-removebg-preview.png?alt=media&token=48442937-5504-4392-88a9-039aef405f14';
          case Emotion.weather:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fexcited_weather-removebg-preview.png?alt=media&token=5de71f38-1178-4e3c-887e-af07547caba9';
          default:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96';
        }
      case Emotion.happy:
        switch (selectedCategory) {
          case Emotion.shape:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/shape%2Fhappy_shape-removebg-preview.png?alt=media&token=5a8aa9dd-6ea5-4132-95af-385340846076';
          case Emotion.fruit:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/fruit%2Fhappy_fruit-removebg-preview.png?alt=media&token=d10a503b-fee7-4bc2-b141-fd4b33dae1f1';
          case Emotion.animal:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/animal%2Fhappy_animal-removebg-preview.png?alt=media&token=66ff8e2d-d941-4fd7-9d7f-9766db03cbd5';
          case Emotion.weather:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/wheather%2Fhappy_weather-removebg-preview.png?alt=media&token=fd77e998-6f47-459a-bd1c-458e309fed41';
          default:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/shape%2Fhappy_shape-removebg-preview.png?alt=media&token=5a8aa9dd-6ea5-4132-95af-385340846076';
        }
      case Emotion.sad:
        switch (selectedCategory) {
          case Emotion.shape:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/shape%2Fsad_shape-removebg-preview.png?alt=media&token=acbc7284-1126-4428-a3b2-f8b6e7932b98';
          case Emotion.fruit:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/fruit%2Fsad_fruit-removebg-preview.png?alt=media&token=e9e0b0f7-6590-4209-a7d1-26377eb33c05';
          case Emotion.animal:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/animal%2Fsad_animal-removebg-preview.png?alt=media&token=04c99bd8-8ad4-43de-91cd-3b7354780677';
          case Emotion.weather:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/wheather%2Fsad_weather-removebg-preview.png?alt=media&token=aa972b9a-8952-4dc7-abe7-692ec7be0d16';
          default:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/shape%2Fsad_shape-removebg-preview.png?alt=media&token=acbc7284-1126-4428-a3b2-f8b6e7932b98';
        }
      case Emotion.angry:
        switch (selectedCategory) {
          case Emotion.shape:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa';
          case Emotion.fruit:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/fruit%2Fangry_fruit-removebg-preview.png?alt=media&token=679778b9-5a1b-469a-8e86-b01585cb1ee2';
          case Emotion.animal:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/animal%2Fangry_animal-removebg-preview.png?alt=media&token=9bde31db-8801-4af0-9368-e6ce4a35fbac';
          case Emotion.weather:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/wheather%2Fangry_weather-removebg-preview.png?alt=media&token=2f4c6212-697d-49b7-9d5e-ae1f2b1fa84e';
          default:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa';
        }
      case Emotion.neutral:
      default:
        switch (selectedCategory) {
          case Emotion.shape:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5';
          case Emotion.fruit:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39';
          case Emotion.animal:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f';
          case Emotion.weather:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f';
          default:
            return 'https://firebasestorage.googleapis.com/v0/b/diary-3bbf7/firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5';
        }
    }
  }

  // 사용자 설정 카테고리에서 이모지 가져오기
  String _getUserEmoticon(Emotion emotion) {
    final appState = Provider.of<AppState>(context, listen: false);
    final selectedCategory = appState.selectedEmoticonCategory;
    
    // 사용자가 선택한 카테고리와 다른 감정인 경우, 선택된 카테고리의 기본 이모지 사용
    if (emotion != selectedCategory) {
      switch (selectedCategory) {
        case Emotion.fruit:
          return emotionEmojis[Emotion.fruit]!;
        case Emotion.animal:
          return emotionEmojis[Emotion.animal]!;
        case Emotion.shape:
          return emotionEmojis[Emotion.shape]!;
        case Emotion.weather:
          return emotionEmojis[Emotion.weather]!;
        default:
          return emotionEmojis[Emotion.shape]!;
      }
    }
    
    // 선택된 카테고리와 같은 감정인 경우 원래 이모지 사용
    return emotionEmojis[emotion] ?? emotionEmojis[Emotion.shape]!;
  }

  /// STT 서비스 연결 테스트
  Future<void> _testSTTConnection() async {
    try {
      print('STT 서비스 연결 테스트 시작...');
      final health = await STTService.healthCheck();
      print('STT 서비스 연결 성공: $health');
    } catch (e) {
      print('STT 서비스 연결 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('STT 서비스에 연결할 수 없습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _entryController = TextEditingController();
    _isSaved = false;
    _currentEmoji = '';
    _uploadedImages = [];
    _hasText = false;
    _isEditMode = true; // 기본적으로 새 일기 모드

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    // STT 서비스 연결 테스트
    _testSTTConnection();

    // 위젯이 빌드된 후 AppState를 사용하여 기본 이모티콘 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentEmoji.isEmpty) {
        final appState = Provider.of<AppState>(context, listen: false);
        setState(() {
          _currentEmoji = _getUserEmoticon(Emotion.neutral);
        });
      }
    });

    // 일기 데이터 로드
    _loadDiaryData();
  }

  Future<void> _loadDiaryData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isAuthenticated) {
      return;
    }

    try {
      final diaryData = await _diaryService.getDiaryByDate(widget.selectedDate);
      print('==== [DEBUG] diaryData 전체:');
      print(diaryData);
      if (diaryData != null) {
        print('==== [DEBUG] diaryData["images"]:');
        print(diaryData['images']);
        print('==== [DEBUG] diaryData["images"] 타입:');
        print(diaryData['images']?.runtimeType);
        if (!mounted) return;
        setState(() {
          _entryController.text = diaryData['content'] ?? '';
          _uploadedImages = (diaryData['images'] as List?)?.map((e) {
            print('==== [DEBUG] images 요소 타입:');
            print(e.runtimeType);
            print('==== [DEBUG] images 요소 값:');
            print(e);
            if (e is String) {
              // file_path에서 filename만 추출
              final filename = e.split('/').last;
              return {"filename": filename, "url": 'http://10.0.2.2:8000/api/images/$filename', "isNew": false}; // 기존 이미지
            } else if (e is Map<String, dynamic>) {
              // ImageInfo 객체에서 filename 추출
              final filename = e["filename"] ?? '';
              return {"filename": filename, "url": 'http://10.0.2.2:8000/api/images/$filename', "isNew": false}; // 기존 이미지
            } else {
              return {"filename": '', "url": '', "isNew": false};
            }
          }).toList() ?? [];
          _isSaved = true;
          _isEditMode = false; // 기존 일기가 있으면 수정 모드
          _hasText = _entryController.text.trim().isNotEmpty;
          _currentEmoji = diaryData['emoji'] ?? _getUserEmoticon(Emotion.neutral);
          // post_id 저장
          _currentPostId = diaryData['post_id'] ?? diaryData['id'];
        });
        await _fetchAIMessage(diaryData['content']);
      }
    } catch (e) {
      print('일기 데이터 로드 중 오류 발생: $e');
      if (e.toString().contains('로그인이 필요합니다') || e.toString().contains('인증이 만료되었습니다')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('로그인이 필요합니다'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: '로그인',
                onPressed: () {
                  appState.setAuthenticated(false);
                },
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _fetchAIMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      print('Fetching AI message for text: $text');
      
      // OpenAI 서비스 사용
      final aiMessage = await OpenAIService.analyzeDiary(widget.selectedDate, text);
      
      if (aiMessage != null) {
        if (!mounted) return;
        setState(() {
          _aiMessage = aiMessage;
          _fadeAnimationController.forward();
        });
        // 오늘의 한마디가 갱신되면 자동으로 TTS 재생
        if (_aiMessage.isNotEmpty) {
          await _playTTS();
        }
      } else {
        throw Exception('AI 메시지를 받지 못했습니다.');
      }
    } catch (e) {
      print('AI 메시지 요청 중 오류: $e');
      if (!mounted) return;
      setState(() {
        _aiMessage = 'AI 메시지를 가져오지 못했습니다. 다시 시도해주세요.';
      });
      _fadeAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _fadeAnimationController.dispose();
    _recordingTimer?.cancel();
    _statusTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  bool _isSpeechRecognitionSupported() {
    return true;
  }

  // STT: 녹음 시작/중지 및 변환
  Future<void> _startRecording() async {
    setState(() { _status = '마이크 권한 확인 중...'; });
    final success = await _audioRecorder.startRecording();
    if (success) {
      setState(() {
        _isRecording = true;
        _recordingTime = 0;
        _partialText = '';
        _status = '마이크 녹음 중...';
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isRecording) {
          setState(() { _recordingTime++; });
        }
      });
    }
  }
  Future<void> _stopRecording() async {
    setState(() { _status = '마이크 녹음 중지 중...'; });
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final audioPath = await _audioRecorder.stopRecording();
    setState(() {
      _isRecording = false;
      _recordingTime = 0;
      _status = '음성 인식(STT) 변환 중...';
    });
    if (audioPath != null) {
      await _transcribeAudio(File(audioPath));
    }
  }
  Future<void> _transcribeAudio(File audioFile) async {
    setState(() { _isTranscribing = true; });
    try {
      final result = await STTService.transcribeAudio(audioFile);
      if (result.success && result.text.isNotEmpty) {
        setState(() {
          _recognizedText = result.text;
          if (_entryController.text.isNotEmpty) {
            _entryController.text += ' ' + result.text;
          } else {
            _entryController.text = result.text;
          }
          _hasText = _entryController.text.trim().isNotEmpty;
          _partialText = '';
          _status = '음성 인식 완료!';
        });
        _clearStatusAfterDelay();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('실제 마이크 음성이 텍스트로 변환되었습니다')),
        );
      } else {
        setState(() { _status = '음성 인식 실패'; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('실제 마이크 음성을 인식할 수 없습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      setState(() { _status = '음성 변환 오류'; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실제 마이크 음성 변환에 실패했습니다: ${e.toString()}')),
      );
    } finally {
      setState(() { _isTranscribing = false; });
    }
  }
  void _clearStatusAfterDelay() {
    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() { _status = ''; });
      }
    });
  }
  void _handleRecordingToggle() {
    if (!_isEditMode) return;
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // TTS: AI 메시지 음성 재생
  Future<String?> fetchTTS(String text) async {
    try {
      final audioUrl = await TTSService.textToSpeech(text);
      return audioUrl;
    } catch (e) {
      print('TTS 요청 중 오류: $e');
      return null;
    }
  }
  Future<void> _playTTS() async {
    if (_aiMessage.isEmpty) return;
    setState(() { _isTtsLoading = true; });
    final url = await fetchTTS(_aiMessage);
    setState(() { _isTtsLoading = false; });
    if (url != null) {
      setState(() {
        _ttsAudioUrl = url;
        _isTtsPlaying = true;
        _isMuted = false;
      });
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(UrlSource(url));
      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() { _isTtsPlaying = false; });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TTS 음성 생성에 실패했습니다.')),
      );
    }
  }
  Future<void> _toggleMute() async {
    if (_isTtsLoading) return;
    if (!_isTtsPlaying) {
      await _playTTS();
    } else {
      if (_isMuted) {
        await _audioPlayer.setVolume(1.0);
      } else {
        await _audioPlayer.setVolume(0.0);
      }
      setState(() { _isMuted = !_isMuted; });
    }
  }

  // OpenAI: 일기 저장 시 AI 메시지 생성
  Future<void> _handleSave() async {
    if (_entryController.text.trim().isEmpty) return;
    setState(() { _isAnalyzing = true; });
    try {
      final emotion = Emotion.shape;
      // 새로 추가된 이미지만 필터링 (기존 이미지는 제외)
      final newImages = _uploadedImages
          .where((img) => img['isNew'] == true) // 새로 추가된 이미지만
          .map((img) => img["filename"] ?? '')
          .whereType<String>()
          .toList();
      
      if (_currentPostId != null) {
        // 수정 모드: updateDiary 호출
        final postId = _currentPostId!;
        // 기존 이미지와 새 이미지 모두 합치기
        final existingImages = _uploadedImages
            .where((img) => img['isNew'] != true)
            .map((img) => img["filename"] ?? '')
            .whereType<String>();
        final newImages = _uploadedImages
            .where((img) => img['isNew'] == true)
            .map((img) => img["filename"] ?? '')
            .whereType<String>();
        final allImages = [...existingImages, ...newImages];
        final success = await DiaryService().updateDiary(
          postId: postId,
          content: _entryController.text,
          emotion: emotion,
          images: allImages.isNotEmpty ? allImages : null,
        );
        if (success) {
          await _fetchAIMessage(_entryController.text);
          setState(() {
            _isAnalyzing = false;
            _isSaved = true;
            _isEditMode = false;
            // 새로 추가된 이미지들을 기존 이미지로 변경
            _uploadedImages = _uploadedImages.map((img) {
              if (img['isNew'] == true) {
                return {...img, 'isNew': false};
              }
              return img;
            }).toList();
          });
          widget.onSave(_entryController.text, emotion, null);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('일기가 수정되었습니다')),
            );
          }
        } else {
          setState(() { _isAnalyzing = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('일기 수정에 실패했습니다')),
          );
        }
      } else {
        // 새 일기: createDiary 호출
        final newImages = _uploadedImages
            .where((img) => img['isNew'] == true)
            .map((img) => img["filename"] ?? '')
            .whereType<String>()
            .toList();
        await DiaryService().createDiary(
          content: _entryController.text,
          emotion: emotion,
          images: newImages.isNotEmpty ? newImages : null,
          date: "${widget.selectedDate}T00:00:00", // ISO8601 datetime 포맷으로 전달
        );
        await _fetchAIMessage(_entryController.text);
        setState(() {
          _isAnalyzing = false;
          _isSaved = true;
          _isEditMode = false;
          // 새로 추가된 이미지들을 기존 이미지로 변경
          _uploadedImages = _uploadedImages.map((img) {
            if (img['isNew'] == true) {
              return {...img, 'isNew': false};
            }
            return img;
          }).toList();
        });
        widget.onSave(_entryController.text, emotion, null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('일기가 저장되었습니다')),
          );
        }
      }
    } catch (e) {
      setState(() { _isAnalyzing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일기 저장/수정에 실패했습니다: ${e.toString()}')),
      );
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final month = date.month;
    final day = date.day;
    final dayNames = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    final dayName = dayNames[date.weekday % 7];

    return '${month}월 ${day}일\n$dayName';
  }

  Widget _buildImageWidget(String imageUrl) {
    Widget errorWidget = Container(
      color: AppColors.muted,
      child: Icon(
        Icons.image,
        color: AppColors.mutedForeground,
      ),
    );

    print('_buildImageWidget 호출: $imageUrl');
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => errorWidget,
    );
  }

  Future<void> _handleImageUpload() async {
    if (!_isEditMode) return;
    if (_uploadedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지는 최대 3개까지만 업로드할 수 있습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isAnalyzing = true;
        });

        // 이미지 업로드
        final filename = await _diaryService.uploadImage(File(image.path));
        final url = 'http://10.0.2.2:8000/api/images/$filename';
        setState(() {
          _uploadedImages.add({"filename": filename, "url": url, "isNew": true}); // 새 이미지 표시
          // 항상 map 변환 강제
          _uploadedImages = _uploadedImages.map((e) {
            if (e is String) {
              return {"filename": e, "url": 'http://10.0.2.2:8000/api/images/$e', "isNew": true};
            } else if (e is Map<String, dynamic>) {
              return {"filename": e["filename"] ?? '', "url": 'http://10.0.2.2:8000/api/images/${e["filename"] ?? ''}', "isNew": e["isNew"] ?? false};
            } else {
              return {"filename": '', "url": '', "isNew": false};
            }
          }).toList();
          _isAnalyzing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미지가 업로드되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 업로드에 실패했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleImageDelete(int index) async {
    if (!_isEditMode) return; // 수정모드가 아닐 때는 삭제 불가
    try {
      final img = _uploadedImages[index];
      String filename = '';
      bool isNewImage = false;
      
      if (img is Map<String, dynamic>) {
        filename = img["filename"] ?? '';
        isNewImage = img["isNew"] == true;
      } else if (img is String) {
        filename = img as String;
        isNewImage = false; // String 타입은 기존 이미지로 간주
      } else {
        throw Exception('이미지 정보를 가져올 수 없습니다');
      }
      
      // 새로 추가된 이미지인 경우에만 서버에서 파일 삭제
      if (isNewImage) {
        final success = await _diaryService.deleteImage(filename);
        if (!success) {
          throw Exception('서버에서 이미지 삭제에 실패했습니다');
        }
      }
      
      // UI에서 이미지 제거
      setState(() {
        _uploadedImages.removeAt(index);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNewImage ? '이미지가 삭제되었습니다' : '이미지가 제거되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 삭제 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Widget _buildNotebookLines() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final lineHeight = 32.0;
            final availableHeight = constraints.maxHeight - 32;
            final lineCount = (availableHeight / lineHeight).floor();

            return Column(
              children: List.generate(
                lineCount,
                (index) => Container(
                  height: lineHeight,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 오늘의 한마디가 갱신될 때 자동으로 TTS 재생
  @override
  void didUpdateWidget(covariant DiaryEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isSaved && _aiMessage.isNotEmpty && !_isTtsPlaying && !_isTtsLoading) {
      _playTTS();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (!appState.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 896),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16, top: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton(
                        onPressed: widget.onBack,
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
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: AppCard(
                        backgroundColor: AppColors.calendarBg,
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 64,
                              color: AppColors.mutedForeground,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '로그인이 필요합니다',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.foreground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '일기를 작성하고 저장하려면\n로그인해주세요',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.mutedForeground,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            AppButton(
                              onPressed: () {
                                appState.setAuthenticated(false);
                              },
                              variant: ButtonVariant.primary,
                              size: ButtonSize.large,
                              child: const Text('로그인하기'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 896),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16, top: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton(
                        onPressed: widget.onBack,
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
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 448,
                      ),
                      child: AppCard(
                        backgroundColor: AppColors.calendarBg,
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 수정모드 토글 버튼 + 상태 표시
                            if (_isSaved) // 저장된 일기에만 수정모드 토글 버튼 표시
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _isEditMode ? '수정모드 ON' : '수정모드 OFF',
                                  style: TextStyle(
                                    color: _isEditMode ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditMode = !_isEditMode;
                                    });
                                  },
                                  variant: ButtonVariant.ghost,
                                  size: ButtonSize.small,
                                  child: Icon(
                                    _isEditMode ? Icons.toggle_on : Icons.toggle_off,
                                    color: _isEditMode ? Colors.green : Colors.grey,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (_isSaved)
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.emotionCalm,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Center(
                                          child: _currentEmoji.startsWith('http')
                                              ? Image.network(
                                                  _currentEmoji,
                                                  width: 24,
                                                  height: 24,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Text(
                                                      '😊',
                                                      style: TextStyle(fontSize: 24),
                                                    );
                                                  },
                                                )
                                              : Text(
                                                  _currentEmoji,
                                                  style: const TextStyle(fontSize: 24),
                                                ),
                                        ),
                                      ),
                                    if (_isSaved)
                                      const SizedBox(width: 16),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Text(
                                            _formatDate(widget.selectedDate),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.foreground,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (_isRecording) ...[
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          '${_recordingTime ~/ 60}:${(_recordingTime % 60).toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                    AppButton(
                                      onPressed: _isEditMode ? _handleRecordingToggle : null,
                                      variant: ButtonVariant.ghost,
                                      size: ButtonSize.icon,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: _isRecording
                                              ? Colors.red
                                              : Colors.red.withOpacity(0.1),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.2),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.mic,
                                            size: 20,
                                            color: _isRecording ? Colors.white : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_uploadedImages.length < 3)
                                      AppButton(
                                        onPressed: _isEditMode ? _handleImageUpload : null,
                                        variant: ButtonVariant.ghost,
                                        size: ButtonSize.icon,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            color: AppColors.primary.withOpacity(0.1),
                                            border: Border.all(
                                              color: AppColors.primary.withOpacity(0.2),
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.upload,
                                            size: 20,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_uploadedImages.isNotEmpty) ...[
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1,
                                ),
                                itemCount: _uploadedImages.length,
                                itemBuilder: (context, index) {
                                  final img = _uploadedImages[index];
                                  String imgUrl = '';
                                  if (img is Map<String, dynamic>) {
                                    imgUrl = 'http://10.0.2.2:8000/api/images/${img["filename"] ?? ''}';
                                  } else if (img is String) {
                                    imgUrl = 'http://10.0.2.2:8000/api/images/$img';
                                  } else {
                                    print('itemBuilder: img 타입 이상, Container 반환');
                                    return Container(); // 타입 에러 방지
                                  }
                                  print('itemBuilder imgUrl: $imgUrl');
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: 128,
                                          decoration: BoxDecoration(
                                            color: AppColors.muted,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: _buildImageWidget(imgUrl),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _handleImageDelete(index),
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            SizedBox(
                              height: 300, // 원하는 높이로 조정
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.calendarBg,
                                ),
                                child: Stack(
                                  children: [
                                    _buildNotebookLines(),
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: TextField(
                                          controller: _entryController,
                                          maxLines: 10,
                                          expands: false,
                                          textAlignVertical: TextAlignVertical.top,
                                          enabled: _isEditMode, // 수정모드에서만 입력 가능
                                          style: TextStyle(
                                            color: AppColors.foreground,
                                            height: 2.0,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: _isSaved
                                                ? "일기를 수정해보세요..."
                                                : "오늘의 이야기를 작성해보세요...",
                                            hintStyle: TextStyle(
                                              color: AppColors.mutedForeground.withOpacity(0.7),
                                            ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            filled: false,
                                          ),
                                          onChanged: (text) {
                                            setState(() {
                                              _hasText = text.trim().isNotEmpty;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // 녹음 상태 표시 (저장 전만 노출)
                            if (!_isSaved && (_isRecording || _isTranscribing || _status.isNotEmpty)) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.calendarBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.calendarDateHover),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isRecording) ...[
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '녹음 중... ${_formatDuration(_recordingTime)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (_isTranscribing) ...[
                                      if (_isRecording) const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '음성 변환 중...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (_status.isNotEmpty) ...[
                                      if (_isRecording || _isTranscribing) const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _status,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            // 수정모드가 아닐 때만 '수정하기' 버튼 노출
                            if (_isSaved && !_isEditMode)
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isEditMode = true;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.edit, size: 16, color: AppColors.primaryForeground),
                                              const SizedBox(width: 8),
                                              Text('수정하기', style: TextStyle(color: AppColors.primaryForeground, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // 수정모드일 때만 저장 버튼 노출
                            if (!_isSaved || _isEditMode)
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _hasText && !_isAnalyzing
                                        ? AppColors.primary
                                        : AppColors.primary.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _hasText && !_isAnalyzing ? _handleSave : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Center(
                                          child: _isAnalyzing
                                              ? Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                          AppColors.primaryForeground,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _isSaved ? '일기 수정 중...' : '감정 분석 중...',
                                                      style: TextStyle(
                                                        color: AppColors.primaryForeground,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.send,
                                                      size: 16,
                                                      color: _hasText && !_isAnalyzing
                                                          ? AppColors.primaryForeground
                                                          : AppColors.primaryForeground.withOpacity(0.7),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _isSaved ? '일기 수정하기' : '일기 저장하기',
                                                      style: TextStyle(
                                                        color: _hasText && !_isAnalyzing
                                                            ? AppColors.primaryForeground
                                                            : AppColors.primaryForeground.withOpacity(0.7),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (_isSaved && _aiMessage.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 16),
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: AppColors.primary.withOpacity(0.2),
                                          ),
                                        ),
                                        constraints: const BoxConstraints(minHeight: 120),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '🤖',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        color: AppColors.primaryForeground,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '오늘의 한마디',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                    Text(
                                                      'AI 친구가 전하는 메시지',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.mutedForeground,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                IconButton(
                                                  onPressed: (!Provider.of<AppState>(context).voiceEnabled) ? null : _toggleMute,
                                                  icon: _isTtsLoading
                                                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                                      : Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 28, color: AppColors.primary),
                                                  tooltip: _isMuted ? '음소거 해제' : '음성 듣기',
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _aiMessage,
                                              style: TextStyle(
                                                color: AppColors.foreground,
                                                height: 1.5,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
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
      ),
    );
  }
}