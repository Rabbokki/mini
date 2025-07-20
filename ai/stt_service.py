from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from dotenv import load_dotenv
import httpx
import tempfile
import uuid
from datetime import datetime
import logging

# 환경 변수 로드
load_dotenv()

app = Flask(__name__)
CORS(app)

# OpenAI API 설정
api_key = os.getenv('OPENAI_API_KEY')
if not api_key:
    raise ValueError("OPENAI_API_KEY 환경 변수가 설정되지 않았습니다.")

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 허용된 오디오 포맷
ALLOWED_EXTENSIONS = {'mp3', 'wav', 'm4a', 'ogg', 'flac', 'aac'}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB (AAC 파일용으로 증가)

def allowed_file(filename):
    """파일 확장자 검증"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def transcribe_audio(audio_file_path, language='ko'):
    """OpenAI Whisper API를 사용하여 오디오를 텍스트로 변환"""
    try:
        # 오디오 파일 길이 확인 (WAV/MP3 파일)
        if audio_file_path.lower().endswith('.wav'):
            import wave
            try:
                with wave.open(audio_file_path, 'rb') as wav_file:
                    frames = wav_file.getnframes()
                    rate = wav_file.getframerate()
                    duration = frames / float(rate)
                    
                logger.info(f"WAV 파일 길이: {duration:.2f}초")
                
                # 최소 길이 체크 (0.1초)
                if duration < 0.1:
                    logger.warning(f"오디오 파일이 너무 짧음: {duration:.2f}초 (최소 0.1초 필요)")
                    return {
                        'success': False,
                        'error': f'오디오 파일이 너무 짧습니다. 최소 0.1초 이상 녹음해주세요. (현재: {duration:.2f}초)'
                    }
            except Exception as e:
                logger.warning(f"WAV 파일 길이 확인 실패: {str(e)}")
        elif audio_file_path.lower().endswith('.mp3'):
            logger.info(f"MP3 파일 형식: {audio_file_path}")
            # MP3 파일은 길이 확인을 건너뛰고 OpenAI에 전송
        elif audio_file_path.lower().endswith('.m4a'):
            logger.info(f"M4A 파일 형식: {audio_file_path}")
            # M4A 파일은 길이 확인을 건너뛰고 OpenAI에 전송
        else:
            logger.info(f"지원되지 않는 파일 형식: {audio_file_path}")
        
        headers = {
            "Authorization": f"Bearer {api_key}"
        }
        
        with open(audio_file_path, 'rb') as audio_file:
            files = {
                'file': audio_file,
                'model': (None, 'whisper-1'),
                'language': (None, language),
                'response_format': (None, 'verbose_json')
            }
            
            with httpx.Client() as client:
                response = client.post(
                    "https://api.openai.com/v1/audio/transcriptions",
                    headers=headers,
                    files=files,
                    timeout=60.0
                )
                response.raise_for_status()
                result = response.json()
                
        return {
            'success': True,
            'text': result.get('text', ''),
            'language': result.get('language', language),
            'duration': result.get('duration', 0),
            'segments': result.get('segments', [])
        }
        
    except Exception as e:
        logger.error(f"STT 변환 중 오류: {str(e)}")
        # 더 자세한 에러 정보 로깅
        if hasattr(e, 'response') and e.response is not None:
            logger.error(f"응답 상태 코드: {e.response.status_code}")
            logger.error(f"응답 내용: {e.response.text}")
        return {
            'success': False,
            'error': str(e)
        }

@app.route('/stt/transcribe', methods=['POST'])
def transcribe():
    """오디오 파일을 텍스트로 변환하는 엔드포인트"""
    try:
        # 파일 검증
        if 'audio' not in request.files:
            return jsonify({'error': '오디오 파일이 없습니다.'}), 400
        
        file = request.files['audio']
        if file.filename == '':
            return jsonify({'error': '파일이 선택되지 않았습니다.'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': f'지원하지 않는 파일 형식입니다. 지원 형식: {", ".join(ALLOWED_EXTENSIONS)}'}), 400
        
        # 파일 크기 검증 (더 관대하게)
        file.seek(0, 2)  # 파일 끝으로 이동
        file_size = file.tell()
        file.seek(0)  # 파일 시작으로 복귀
        
        logger.info(f"업로드된 파일 크기: {file_size} bytes")
        
        if file_size > MAX_FILE_SIZE:
            return jsonify({'error': f'파일 크기가 너무 큽니다. 최대 {MAX_FILE_SIZE // (1024*1024)}MB까지 지원합니다.'}), 400
        
        if file_size < 100:  # 최소 크기 체크
            return jsonify({'error': '파일이 너무 작습니다. 최소 100 bytes 이상이어야 합니다.'}), 400
        
        # 언어 설정 (기본값: 한국어)
        language = request.form.get('language', 'ko')
        
        # 임시 파일로 저장
        temp_dir = tempfile.gettempdir()
        temp_filename = f"stt_{uuid.uuid4()}_{file.filename}"
        temp_path = os.path.join(temp_dir, temp_filename)
        
        try:
            file.save(temp_path)
            logger.info(f"임시 파일 저장: {temp_path}")
            
            # STT 변환
            result = transcribe_audio(temp_path, language)
            
            if result['success']:
                return jsonify({
                    'success': True,
                    'text': result['text'],
                    'language': result['language'],
                    'duration': result['duration'],
                    'segments': result['segments'],
                    'timestamp': datetime.now().isoformat()
                })
            else:
                return jsonify({'error': result['error']}), 500
                
        finally:
            # 임시 파일 삭제
            if os.path.exists(temp_path):
                os.remove(temp_path)
                logger.info(f"임시 파일 삭제: {temp_path}")
    
    except Exception as e:
        logger.error(f"STT 엔드포인트 오류: {str(e)}")
        return jsonify({'error': '서버 내부 오류가 발생했습니다.'}), 500

@app.route('/stt/transcribe-chunk', methods=['POST'])
def transcribe_chunk():
    """오디오 청크를 텍스트로 변환하는 엔드포인트 (실시간용)"""
    try:
        # 파일 검증
        if 'audio' not in request.files:
            return jsonify({'error': '오디오 파일이 없습니다.'}), 400
        
        file = request.files['audio']
        if file.filename == '':
            return jsonify({'error': '파일이 선택되지 않았습니다.'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': f'지원하지 않는 파일 형식입니다. 지원 형식: {", ".join(ALLOWED_EXTENSIONS)}'}), 400
        
        # 파일 크기 검증 (청크용 - 더 관대하게)
        file.seek(0, 2)
        file_size = file.tell()
        file.seek(0)
        
        logger.info(f"청크 파일 크기: {file_size} bytes, 파일명: {file.filename}")
        
        if file_size > MAX_FILE_SIZE:
            return jsonify({'error': f'파일 크기가 너무 큽니다. 최대 {MAX_FILE_SIZE // (1024*1024)}MB까지 지원합니다.'}), 400
        
        # 청크 파일은 최소 크기를 더 작게 설정 (1KB)
        if file_size < 1024:
            logger.warning(f"청크 파일이 너무 작음: {file_size} bytes")
            return jsonify({'error': '청크 파일이 너무 작습니다. 최소 1KB 이상이어야 합니다.'}), 400
        
        # 언어 설정 (기본값: 한국어)
        language = request.form.get('language', 'ko')
        
        # 임시 파일로 저장
        temp_dir = tempfile.gettempdir()
        temp_filename = f"chunk_{uuid.uuid4()}_{file.filename}"
        temp_path = os.path.join(temp_dir, temp_filename)
        
        try:
            file.save(temp_path)
            logger.info(f"청크 임시 파일 저장: {temp_path}")
            
            # STT 변환
            result = transcribe_audio(temp_path, language)
            
            if result['success']:
                logger.info(f"청크 STT 성공: '{result['text']}'")
                return jsonify({
                    'success': True,
                    'text': result['text'],
                    'language': result['language'],
                    'duration': result['duration'],
                    'segments': result['segments'],
                    'timestamp': datetime.now().isoformat()
                })
            else:
                logger.error(f"청크 STT 실패: {result['error']}")
                return jsonify({'error': result['error']}), 500
                
        finally:
            # 임시 파일 삭제
            if os.path.exists(temp_path):
                os.remove(temp_path)
                logger.info(f"청크 임시 파일 삭제: {temp_path}")
    
    except Exception as e:
        logger.error(f"청크 STT 엔드포인트 오류: {str(e)}")
        return jsonify({'error': '서버 내부 오류가 발생했습니다.'}), 500

@app.route('/stt/health', methods=['GET'])
def health_check():
    """서비스 상태 확인"""
    return jsonify({
        'status': 'healthy',
        'service': 'STT Service',
        'timestamp': datetime.now().isoformat(),
        'supported_formats': list(ALLOWED_EXTENSIONS),
        'max_file_size_mb': MAX_FILE_SIZE // (1024*1024)
    })

@app.route('/stt/supported-languages', methods=['GET'])
def supported_languages():
    """지원하는 언어 목록"""
    return jsonify({
        'languages': {
            'ko': '한국어',
            'en': 'English',
            'ja': '日本語',
            'zh': '中文',
            'es': 'Español',
            'fr': 'Français',
            'de': 'Deutsch',
            'it': 'Italiano',
            'pt': 'Português',
            'ru': 'Русский'
        }
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5002) 