import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';

class AudioRecorder {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _recordingPath;
  bool _isRecording = false;
  Timer? _chunkTimer;
  int _chunkCounter = 0;

  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;

  /// 마이크 권한 요청
  Future<bool> requestPermission() async {
    try {
      // 현재 권한 상태 확인
      PermissionStatus status = await Permission.microphone.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        // 권한 요청
        status = await Permission.microphone.request();
        return status.isGranted;
      }
      
      if (status.isPermanentlyDenied) {
        // 사용자가 "다시 묻지 않음"을 선택한 경우
        print('마이크 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
        return false;
      }
      
      return false;
    } catch (e) {
      print('권한 요청 중 오류: $e');
      return false;
    }
  }

  /// 녹음 시작 (실시간 STT 포함)
  Future<bool> startRecording() async {
    try {
      print('마이크 권한 확인 중...');
      if (!await requestPermission()) {
        throw Exception('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
      }
      
      print('FlutterSoundRecorder 초기화 중...');
      await _recorder.openRecorder();
      
      if (_isRecording) {
        await stopRecording();
      }
      
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${tempDir.path}/recording_$timestamp.m4a';
      
      print('녹음 시작: $_recordingPath');
      await _recorder.startRecorder(
        toFile: _recordingPath!,
        codec: Codec.aacMP4, // AAC MP4 유지
        bitRate: 128000, // 더 높은 비트레이트로 변경
        sampleRate: 44100, // 표준 샘플레이트로 변경
        numChannels: 1, // 모노 채널
      );
      
      _isRecording = true;
      _chunkCounter = 0;
      print('녹음이 시작되었습니다.');
      
      // 1초마다 청크 생성 타이머 시작
      _startChunkTimer();
      
      return true;
    } catch (e) {
      print('녹음 시작 오류: $e');
      _isRecording = false;
      return false;
    }
  }

  /// 1초마다 청크 생성 타이머 시작
  void _startChunkTimer() {
    _chunkTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isRecording) {
        _chunkCounter++;
        print('청크 생성 중... (${_chunkCounter * 3}초)');
        await _createChunkForSTT();
      } else {
        timer.cancel();
      }
    });
  }

  /// STT용 청크 파일 생성
  Future<String?> _createChunkForSTT() async {
    try {
      if (!_isRecording || _recordingPath == null) return null;
      
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final chunkPath = '${tempDir.path}/chunk_${_chunkCounter}_$timestamp.m4a';
      
      // 현재 녹음 파일을 청크로 복사
      final originalFile = File(_recordingPath!);
      if (await originalFile.exists()) {
        final fileSize = await originalFile.length();
        // 파일이 최소 1KB 이상일 때만 처리 (너무 작은 파일은 STT API에서 거부됨)
        if (fileSize > 1024) {
          await originalFile.copy(chunkPath);
          print('청크 파일 생성됨: $chunkPath (크기: ${fileSize} bytes)');
          return chunkPath;
        } else {
          print('청크 파일이 너무 작음: ${fileSize} bytes (최소 1KB 필요)');
        }
      }
      return null;
    } catch (e) {
      print('청크 생성 오류: $e');
      return null;
    }
  }

  /// 녹음 중지
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      
      // 청크 타이머 정지
      _chunkTimer?.cancel();
      _chunkTimer = null;
      
      print('녹음 중지 중...');
      final path = await _recorder.stopRecorder();
      _isRecording = false;
      
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists() && await file.length() > 100) {
          _recordingPath = path;
          print('녹음 파일 저장됨: $path');
          return path;
        } else {
          print('녹음 파일이 너무 작거나 존재하지 않음');
          await file.delete();
        }
      }
      return null;
    } catch (e) {
      print('녹음 중지 오류: $e');
      _isRecording = false;
      return null;
    }
  }

  /// 청크 파일 생성 (실시간 STT용) - 기존 메서드 유지
  Future<String?> createChunk() async {
    try {
      if (!_isRecording || _recordingPath == null) return null;
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final chunkPath = '${tempDir.path}/chunk_$timestamp.m4a';
      final originalFile = File(_recordingPath!);
      if (await originalFile.exists()) {
        await originalFile.copy(chunkPath);
        return chunkPath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> dispose() async {
    try {
      _chunkTimer?.cancel();
      if (_isRecording) {
        await _recorder.stopRecorder();
      }
      await _recorder.closeRecorder();
    } catch (_) {}
  }
} 