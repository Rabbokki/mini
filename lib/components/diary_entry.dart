import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../ui/card.dart';
import '../ui/button.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../services/diary_service.dart';
// dart:html은 웹에서만 사용 가능하므로 조건부 import

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
  List<String> _uploadedImages = [];
  bool _isRecording = false;
  int _recordingTime = 0;
  String _recognizedText = '';
  bool _hasText = false; // 텍스트 입력 여부를 추적하는 변수 추가
  
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  final _diaryService = DiaryService();

  // ImagePicker는 실제 앱에서 image_picker 패키지로 구현

  // 감정 체인 데이터
  final List<EmotionChainItem> emotionChain = [
    EmotionChainItem(emoji: '🍎', type: Emotion.fruit),
    EmotionChainItem(emoji: '🐶', type: Emotion.animal),
    EmotionChainItem(emoji: '⭐', type: Emotion.shape),
    EmotionChainItem(emoji: '☀️', type: Emotion.weather),
    EmotionChainItem(emoji: '🍇', type: Emotion.fruit),
    EmotionChainItem(emoji: '🐱', type: Emotion.animal),
  ];

  // 감정에 따른 이모티콘 매핑
  final Map<Emotion, String> emotionEmojis = {
    Emotion.fruit: '🍎',
    Emotion.animal: '🐶',
    Emotion.shape: '⭐',
    Emotion.weather: '☀️',
  };

  @override
  void initState() {
    super.initState();
    _loadDiaryData();
    _entryController = TextEditingController(text: widget.existingEntry?.entry ?? '');
    _isSaved = widget.existingEntry?.entry != null;
    _currentEmoji = widget.existingEntry?.emoji ?? '';
    _uploadedImages = List.from(widget.existingEntry?.images ?? []);
    _hasText = _entryController.text.trim().isNotEmpty; // 초기 텍스트 상태 설정

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    );

    // Generate AI message for existing entry when component mounts
    if (widget.existingEntry?.entry != null && _aiMessage.isEmpty) {
      final emotion = _analyzeEmotion(widget.existingEntry!.entry!);
      final comfortMessage = _generateComfortMessage(emotion, widget.existingEntry!.entry!);
      setState(() {
        _aiMessage = comfortMessage;
      });
      _fadeAnimationController.forward();
    }
  }

  Future<void> _loadDiaryData() async {
    // 인증 상태 확인
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isAuthenticated) {
      return; // 인증되지 않은 경우 일기 데이터 로드하지 않음
    }
    
    try {
      final diaryData = await _diaryService.getDiaryByDate(widget.selectedDate);
      if (diaryData != null) {
        setState(() {
          _entryController.text = diaryData['content'];
          _uploadedImages = List<String>.from(diaryData['images']);
          _isSaved = true;
          _hasText = true;
          
          // 감정 분석 및 메시지 생성
          final emotion = _analyzeEmotion(diaryData['content']);
          _aiMessage = _generateComfortMessage(emotion, diaryData['content']);
          _currentEmoji = emotionEmojis[emotion] ?? '';
          _fadeAnimationController.forward();
        });
      }
    } catch (e) {
      print('일기 데이터 로드 중 오류 발생: $e');
      // 인증 에러인 경우 로그인 페이지로 이동
      if (e.toString().contains('로그인이 필요합니다') || e.toString().contains('인증이 만료되었습니다')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인이 필요합니다'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: '로그인',
                onPressed: () {
                  appState.setAuthenticated(false); // 로그인 페이지로 이동
                },
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  // 음성 인식 지원 확인 (웹에서만 사용 가능)
  bool _isSpeechRecognitionSupported() {
    // Flutter에서는 speech_to_text 패키지를 사용
    // 여기서는 시뮬레이션
    return true;
  }

  Emotion _analyzeEmotion(String text) {
    // Simple emotion analysis based on keywords
    final fruitWords = ['과일', '사과', '바나나', '딸기', '포도', '맛있', '달콤', '상큼'];
    final animalWords = ['동물', '강아지', '고양이', '새', '토끼', '귀여', '애완동물', '반려동물'];
    final shapeWords = ['모양', '원', '사각형', '삼각형', '별', '도형', '그림', '디자인'];
    final weatherWords = ['날씨', '맑은', '비', '눈', '구름', '햇빛', '바람', '기온'];

    final lowerText = text.toLowerCase();
    
    if (fruitWords.any((word) => lowerText.contains(word))) return Emotion.fruit;
    if (animalWords.any((word) => lowerText.contains(word))) return Emotion.animal;
    if (shapeWords.any((word) => lowerText.contains(word))) return Emotion.shape;
    if (weatherWords.any((word) => lowerText.contains(word))) return Emotion.weather;
    
    return Emotion.fruit; // default to fruit
  }

  String _generateComfortMessage(Emotion emotion, String entryText) {
    final messages = {
      Emotion.fruit: [
        "오늘은 과일처럼 상큼하고 달콤한 하루였나 봐요! 자연의 맛과 향을 만끽하는 순간들이 소중해요 🍎",
        "신선하고 건강한 에너지가 느껴져요! 과일의 생명력처럼 활기찬 하루를 보내셨네요 🍓",
        "달콤하고 맛있는 순간들이 가득했군요! 이런 즐거운 경험들이 더 많이 이어지길 바라요 🍊"
      ],
      Emotion.animal: [
        "동물들과 함께한 특별한 하루였나 봐요! 작은 생명들과의 교감은 정말 소중한 경험이에요 🐶",
        "귀여운 동물들처럼 순수하고 따뜻한 마음이 느껴져요! 이런 순간들이 마음을 치유해죠 🐱",
        "자연과 생명에 대한 사랑이 전해져요! 동물들과의 만남이 특별한 의미를 준 하루였군요 🐸"
      ],
      Emotion.shape: [
        "창의적이고 아름다운 모양들을 발견한 하루였나 봐요! 예술적 감성이 풍부하게 느껴져요 ⭐",
        "기하학적이고 조화로운 패턴들처럼, 오늘 하루도 균형 잡힌 모습이었군요 🔶",
        "다양한 형태와 색깔들이 어우러진 특별한 하루였네요! 디자인적 영감이 가득한 시간이었어요 🔷"
      ],
      Emotion.weather: [
        "날씨만큼이나 변화무쌍하고 아름다운 하루였나 봐요! 자연의 힘을 느끼는 순간들이 소중해요 ☀️",
        "맑은 하늘처럼 깨끗하고 상쾌한 기분이 드는 하루였군요! 좋은 날씨가 마음도 밝게 해줬나 봐요 🌈",
        "계절의 변화를 온몸으로 느끼며 보낸 의미 있는 하루였네요! 자연과 하나 되는 기분이었어요 🌧️"
      ]
    };

    final emotionMessages = messages[emotion] ?? messages[Emotion.fruit]!;
    final random = Random();
    return emotionMessages[random.nextInt(emotionMessages.length)];
  }

  Future<void> _handleSave() async {
    if (_entryController.text.trim().isEmpty) {
      return;
    }
    
    // 인증 상태 확인
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일기를 저장하려면 로그인이 필요합니다'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: '로그인',
            onPressed: () {
              appState.setAuthenticated(false); // 로그인 페이지로 이동
            },
          ),
        ),
      );
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      // 감정 분석
      final emotion = _analyzeEmotion(_entryController.text);
      
      // 일기 저장 API 호출
      final postId = await _diaryService.createDiary(
        content: _entryController.text,
        emotion: emotion,
        images: _uploadedImages.isNotEmpty ? _uploadedImages : null,
      );
      
      // 위로의 메시지 생성
      final comfortMessage = _generateComfortMessage(emotion, _entryController.text);
      
      setState(() {
        _aiMessage = comfortMessage;
        _currentEmoji = emotionEmojis[emotion]!;
        _isAnalyzing = false;
        _isSaved = true;
      });
      
      _fadeAnimationController.forward();
      
      // 일기 데이터 저장 콜백 호출
      widget.onSave(_entryController.text, emotion, _uploadedImages.isNotEmpty ? _uploadedImages : null);

      // 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일기가 저장되었습니다'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      // 에러 처리
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일기 저장에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Widget _buildImageWidget(String imagePath) {
    Widget errorWidget = Container(
      color: AppColors.muted,
      child: Icon(
        Icons.image,
        color: AppColors.mutedForeground,
      ),
    );

    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => errorWidget,
    );
  }

  Future<void> _handleImageUpload() async {
    if (_uploadedImages.length >= 3) return;

    // 웹에서만 동작하므로 조건부 처리
    if (kIsWeb) {
      // 웹에서는 dart:html을 사용할 수 없으므로 이미지 업로드 기능을 비활성화
      // 실제 구현에서는 image_picker 패키지를 사용해야 함
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 기능은 모바일에서만 사용 가능합니다.')),
      );
    } else {
      // 모바일에서는 image_picker 패키지 사용
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 업로드 기능을 구현하려면 image_picker 패키지를 추가하세요.')),
      );
    }
  }

  void _handleImageDelete(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
  }

  Future<void> _startRecording() async {
    // Flutter에서는 speech_to_text 패키지를 사용
    // 여기서는 시뮬레이션
    setState(() {
      _isRecording = true;
      _recordingTime = 0;
    });

    // 시뮬레이션: 1초마다 녹음 시간 증가
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording) {
        setState(() {
          _recordingTime++;
        });
      }
    }
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
      _recordingTime = 0;
    });
  }

  void _handleRecordingToggle() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Widget _buildNotebookLines() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 사용 가능한 높이를 라인 높이로 나누어 라인 개수 계산
            final lineHeight = 32.0;
            final availableHeight = constraints.maxHeight - 32; // 패딩 고려
            final lineCount = (availableHeight / lineHeight).floor();
            
            return Column(
              children: List.generate(lineCount, (index) => 
                Container(
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // 인증되지 않은 사용자를 위한 안내 화면
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
                  // Back Button
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
                  
                  // 로그인 안내 메시지
                  Expanded(
                    child: Center(
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
                                  appState.setAuthenticated(false); // 로그인 페이지로 이동
                                },
                                variant: ButtonVariant.primary,
                                size: ButtonSize.large,
                                child: Text('로그인하기'),
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
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl
            child: Column(
              children: [
                // Back Button
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
                
                // Main Content
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 448, // max-w-md
                        maxHeight: 800, // 세로 길이 제한 추가
                      ),
                      child: AppCard(
                        backgroundColor: AppColors.calendarBg,
                        borderRadius: BorderRadius.circular(24),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Display with Voice Recording & Photo Upload Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Date Display
                                Row(
                                  children: [
                                    if (_isSaved || widget.existingEntry?.entry != null)
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.emotionCalm,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _currentEmoji,
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),
                                    if (_isSaved || widget.existingEntry?.entry != null)
                                      const SizedBox(width: 16),
                                    // 날짜/요일에 여백 추가
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0), // 왼쪽 여백 추가
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 8),
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

                                // Voice Recording & Photo Upload Buttons
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 타이머 (녹음 중일 때만)
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
                                    // 마이크 버튼
                                    AppButton(
                                      onPressed: _handleRecordingToggle,
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
                                    // 업로드 버튼
                                    if (_uploadedImages.length < 3)
                                      AppButton(
                                        onPressed: _handleImageUpload,
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

                            // Uploaded Images Preview
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
                                          child: _buildImageWidget(_uploadedImages[index]),
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

                            // Diary Content
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.calendarBg,
                                ),
                                child: Stack(
                                  children: [
                                    // Notebook lines
                                    _buildNotebookLines(),
                                    
                                    // Writing Area
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: TextField(
                                          controller: _entryController,
                                          maxLines: null,
                                          expands: true,
                                          textAlignVertical: TextAlignVertical.top,
                                          style: TextStyle(
                                            color: AppColors.foreground,
                                            height: 2.0,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: widget.existingEntry?.entry != null 
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
                            
                            // Save Button with improved disabled style
                            if (!_isSaved)
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
                                                      '감정 분석 중...',
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
                                                      widget.existingEntry?.entry != null 
                                                          ? '일기 수정하기' 
                                                          : '일기 저장하기',
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

                            // AI Message - Bottom of card
                            if ((_isSaved || widget.existingEntry?.entry != null) && _aiMessage.isNotEmpty)
                              FadeTransition(
                                opacity: _fadeAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0), // 왼쪽 여백 추가
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
} 