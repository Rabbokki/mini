from fastapi import FastAPI, File, UploadFile, Form, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel
from datetime import datetime
import os
import tempfile
import uuid
import logging
import httpx
from dotenv import load_dotenv
from gtts import gTTS

# 환경 변수 로드
load_dotenv()

app = FastAPI(
    title="Unified AI Service",
    description="STT, TTS, 운세 서비스를 통합한 AI 서비스",
    version="1.0.0"
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OpenAI API 설정
api_key = os.getenv('OPENAI_API_KEY')
if not api_key:
    print("⚠️  OPENAI_API_KEY가 설정되지 않았습니다. 운세 서비스는 사용할 수 없습니다.")

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 허용된 오디오 포맷
ALLOWED_EXTENSIONS = {'mp3', 'wav', 'm4a', 'ogg', 'flac', 'aac'}
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50MB

# TTS 출력 디렉토리
TTS_OUTPUT_DIR = "tts_outputs"
os.makedirs(TTS_OUTPUT_DIR, exist_ok=True)

# Pydantic 모델
class FortuneResponse(BaseModel):
    fortune: str

class DiaryEntry(BaseModel):
    date: str
    text: str

class ComfortResponse(BaseModel):
    message: str

class EmotionExtractionRequest(BaseModel):
    text: str

class EmotionExtractionResponse(BaseModel):
    emotion: str

def allowed_file(filename):
    """파일 확장자 검증"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def transcribe_audio(audio_file_path, language='ko'):
    """OpenAI Whisper API를 사용하여 오디오를 텍스트로 변환"""
    if not api_key:
        return {
            'success': False,
            'error': 'OpenAI API 키가 설정되지 않았습니다.'
        }
    
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
        if hasattr(e, 'response') and e.response is not None:
            logger.error(f"응답 상태 코드: {e.response.status_code}")
            logger.error(f"응답 내용: {e.response.text}")
        return {
            'success': False,
            'error': str(e)
        }

def generate_fortune(birthday: str) -> str:
    """OpenAI GPT를 사용하여 개인화된 운세를 생성합니다."""
    if not api_key:
        raise ValueError("OpenAI API 키가 설정되지 않았습니다.")
    
    try:
        current_date = datetime.now().strftime('%Y년 %m월 %d일')
        birth_year = birthday[:4]
        birth_month = birthday[4:6]
        birth_day = birthday[6:]

        # 운세 생성을 위한 프롬프트
        prompt = f"""
{birth_year}년 {birth_month}월 {birth_day}일생의 오늘({current_date})의 운세를 2줄로 작성해주세요.

간단명료하고 긍정적으로 작성해주세요.
"""

        # GPT API 호출
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "model": "gpt-3.5-turbo",
            "messages": [
                {"role": "system", "content": "당신은 전문적인 운세 상담가입니다. 사용자의 생년월일을 바탕으로 짧고 긍정적인 오늘의 운세를 제공합니다."},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.7,
            "max_tokens": 150
        }
        
        with httpx.Client() as client:
            response = client.post(
                "https://api.openai.com/v1/chat/completions",
                headers=headers,
                json=data,
                timeout=30.0
            )
            response.raise_for_status()
            result = response.json()

        # 응답 파싱
        fortune_text = result["choices"][0]["message"]["content"]
        if fortune_text is None:
            raise ValueError("운세 생성에 실패했습니다.")
            
        fortune_text = fortune_text.strip()
        return fortune_text

    except Exception as e:
        print(f"Error generating fortune: {str(e)}")
        raise HTTPException(status_code=500, detail=f"운세 생성 중 오류가 발생했습니다: {str(e)}")

def analyze_diary(entry: DiaryEntry) -> str:
    """일기 내용을 분석하고 위로의 메시지를 생성합니다."""
    if not api_key:
        raise ValueError("OpenAI API 키가 설정되지 않았습니다.")
    
    try:
        import re
        
        # 날짜 형식 검증
        if not entry.date or len(entry.date) != 10 or entry.date[4] != '-' or entry.date[7] != '-':
            raise ValueError("잘못된 날짜 형식입니다. YYYY-MM-DD 형식을 사용하세요")

        prompt = f"""
        사용자가 작성한 한국어 일기를 분석하고, 따뜻하고 위로가 되는 한국어 메시지를 작성해 주세요.
        일기 내용: {entry.text}
        메시지는 긍정적이고 공감적인 톤으로, 2-3문장으로 작성해 주세요.
        """

        logger.info(f"일기 분석 요청: {entry.date}")

        # GPT API 호출
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "model": "gpt-3.5-turbo",
            "messages": [
                {"role": "system", "content": "당신은 따뜻하고 공감적인 조언을 제공하는 AI입니다."},
                {"role": "user", "content": prompt}
            ],
            "max_tokens": 100,
            "temperature": 0.7
        }
        
        with httpx.Client() as client:
            response = client.post(
                "https://api.openai.com/v1/chat/completions",
                headers=headers,
                json=data,
                timeout=30.0
            )
            response.raise_for_status()
            result = response.json()

        if not result.get("choices") or not result["choices"][0].get("message", {}).get("content"):
            raise ValueError("OpenAI API에서 유효한 응답을 받지 못했습니다")

        comfort_message = result["choices"][0]["message"]["content"].strip()
        logger.info(f"일기 분석 완료: {comfort_message}")

        # 두 번째 마침표까지의 텍스트만 반환
        periods = [m.end() for m in re.finditer(r'\.', comfort_message)]
        if len(periods) >= 2:
            comfort_message = comfort_message[:periods[1]]
        elif len(periods) == 1:
            comfort_message = comfort_message[:periods[0]]
        # 마침표가 없으면 전체 반환

        return comfort_message

    except Exception as e:
        logger.error(f"일기 분석 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=f"일기 처리 중 오류 발생: {str(e)}")

def extract_emotion(text: str) -> str:
    """일기 내용에서 감정을 추출"""
    if not api_key:
        return "neutral"
    
    try:
        # 일기 내용을 기반으로 감정 추출
        prompt = f"""
다음은 사용자가 작성한 일기입니다. 이 일기에서 가장 강하게 드러나는 감정을 분석해주세요.

일기 내용:
{text}

다음 감정 중에서 가장 적합한 하나를 선택해서 영어로만 답변해주세요:
- happy (행복, 기쁨)
- sad (슬픔, 우울)
- angry (화남, 분노)
- excited (신남, 흥분)
- anxious (불안, 걱정)
- calm (평온, 차분)
- confident (자신감, 확신)
- confused (혼란, 당황)
- determined (결심, 의지)
- love (사랑, 애정)
- touched (감동, 감사)
- neutral (중립, 평범)

감정:
"""
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "model": "gpt-3.5-turbo",
            "messages": [
                {
                    "role": "system",
                    "content": "당신은 감정 분석 전문가입니다. 주어진 텍스트에서 가장 강하게 드러나는 감정을 정확히 분석합니다."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "max_tokens": 10,
            "temperature": 0.3
        }
        
        with httpx.Client() as client:
            response = client.post(
                "https://api.openai.com/v1/chat/completions",
                headers=headers,
                json=data,
                timeout=30.0
            )
            response.raise_for_status()
            result = response.json()

        if not result.get("choices") or not result["choices"][0].get("message", {}).get("content"):
            return "neutral"

        emotion = result["choices"][0]["message"]["content"].strip().lower()
        logger.info(f"감정 추출 완료: {emotion}")
        return emotion
            
    except Exception as e:
        logger.error(f"감정 추출 중 예외 발생: {str(e)}")
        return "neutral"

# STT 엔드포인트
@app.post("/stt/transcribe")
async def transcribe_audio_endpoint(
    audio: UploadFile = File(...),
    language: str = Form("ko")
):
    """오디오 파일을 텍스트로 변환하는 엔드포인트"""
    try:
        # 파일 검증
        if not audio.filename:
            raise HTTPException(status_code=400, detail="파일이 선택되지 않았습니다.")
        
        if not allowed_file(audio.filename):
            raise HTTPException(
                status_code=400, 
                detail=f"지원하지 않는 파일 형식입니다. 지원 형식: {', '.join(ALLOWED_EXTENSIONS)}"
            )
        
        # 파일 크기 검증
        file_size = 0
        content = await audio.read()
        file_size = len(content)
        
        logger.info(f"업로드된 파일 크기: {file_size} bytes")
        
        if file_size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=400, 
                detail=f"파일 크기가 너무 큽니다. 최대 {MAX_FILE_SIZE // (1024*1024)}MB까지 지원합니다."
            )
        
        if file_size < 100:
            raise HTTPException(status_code=400, detail="파일이 너무 작습니다. 최소 100 bytes 이상이어야 합니다.")
        
        # 임시 파일로 저장
        temp_dir = tempfile.gettempdir()
        temp_filename = f"stt_{uuid.uuid4()}_{audio.filename}"
        temp_path = os.path.join(temp_dir, temp_filename)
        
        try:
            with open(temp_path, 'wb') as f:
                f.write(content)
            
            logger.info(f"임시 파일 저장: {temp_path}")
            
            # STT 변환
            result = transcribe_audio(temp_path, language)
            
            if result['success']:
                return {
                    'success': True,
                    'text': result['text'],
                    'language': result['language'],
                    'duration': result['duration'],
                    'segments': result['segments'],
                    'timestamp': datetime.now().isoformat()
                }
            else:
                raise HTTPException(status_code=500, detail=result['error'])
                
        finally:
            # 임시 파일 삭제
            if os.path.exists(temp_path):
                os.remove(temp_path)
                logger.info(f"임시 파일 삭제: {temp_path}")
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"STT 엔드포인트 오류: {str(e)}")
        raise HTTPException(status_code=500, detail="서버 내부 오류가 발생했습니다.")

# TTS 엔드포인트
@app.get("/tts")
async def text_to_speech(
    text: str = Query(..., description="음성으로 변환할 텍스트"),
    volume: int = Query(50, description="음성 볼륨 (0-100)", ge=0, le=100)
):
    """텍스트를 음성으로 변환하는 엔드포인트"""
    try:
        logger.info(f"TTS 요청 받음: {text} (볼륨: {volume}%)")
        tts = gTTS(text, lang='ko', slow=False)
        filename = f"{uuid.uuid4()}.mp3"
        filepath = os.path.join(TTS_OUTPUT_DIR, filename)
        logger.info(f"파일 저장 경로: {filepath}")
        tts.save(filepath)
        
        # 파일이 실제로 생성되었는지 확인
        if os.path.exists(filepath):
            file_size = os.path.getsize(filepath)
            logger.info(f"파일 생성 완료: {filename}, 크기: {file_size} bytes")
        else:
            logger.error(f"파일 생성 실패: {filepath}")
            raise HTTPException(status_code=500, detail="음성 파일 생성에 실패했습니다.")
            
        return {"audio_url": f"/tts/audio/{filename}"}
    except Exception as e:
        logger.error(f"TTS 오류: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/tts/audio/{filename}")
async def get_audio(filename: str):
    """생성된 음성 파일을 반환하는 엔드포인트"""
    filepath = os.path.join(TTS_OUTPUT_DIR, filename)
    logger.info(f"오디오 파일 요청: {filename}")
    logger.info(f"파일 경로: {filepath}")
    if os.path.exists(filepath):
        file_size = os.path.getsize(filepath)
        logger.info(f"파일 존재, 크기: {file_size} bytes")
        return FileResponse(filepath, media_type="audio/mpeg")
    logger.error(f"파일 없음: {filepath}")
    raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다.")

# 운세 엔드포인트
@app.get("/fortune", response_model=FortuneResponse)
async def get_fortune(birthday: str = Query(..., description="생년월일 (YYYYMMDD 형식)")):
    """생년월일을 기반으로 개인화된 운세를 생성합니다."""
    
    # 입력 검증
    if not birthday or not birthday.isdigit() or len(birthday) != 8:
        raise HTTPException(status_code=400, detail="올바른 생년월일을 입력해주세요 (YYYYMMDD 형식)")
    
    try:
        # 생년월일 유효성 검사
        year = int(birthday[:4])
        month = int(birthday[4:6])
        day = int(birthday[6:])
        
        if year < 1900 or year > 2100:
            raise HTTPException(status_code=400, detail="올바른 연도를 입력해주세요 (1900-2100)")
        
        if month < 1 or month > 12:
            raise HTTPException(status_code=400, detail="올바른 월을 입력해주세요 (01-12)")
        
        if day < 1 or day > 31:
            raise HTTPException(status_code=400, detail="올바른 일을 입력해주세요 (01-31)")
        
        # 운세 생성
        fortune_text = generate_fortune(birthday)
        return FortuneResponse(fortune=fortune_text)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"운세 생성 오류: {str(e)}")
        raise HTTPException(status_code=500, detail="운세 생성 중 오류가 발생했습니다.")

# 일기 분석 엔드포인트
@app.post("/diary/analyze", response_model=ComfortResponse)
async def analyze_diary_endpoint(entry: DiaryEntry):
    """일기 내용을 분석하고 위로의 메시지를 생성합니다."""
    try:
        # 일기 분석
        comfort_message = analyze_diary(entry)
        return ComfortResponse(message=comfort_message)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"일기 분석 오류: {str(e)}")
        raise HTTPException(status_code=500, detail="일기 분석 중 오류가 발생했습니다.")

# 감정 추출 엔드포인트
@app.post("/diary/extract-emotion", response_model=EmotionExtractionResponse)
async def extract_emotion_endpoint(request: EmotionExtractionRequest):
    """일기 내용에서 감정을 추출하는 엔드포인트"""
    try:
        emotion = extract_emotion(request.text)
        return EmotionExtractionResponse(emotion=emotion)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"감정 추출 오류: {str(e)}")
        raise HTTPException(status_code=500, detail="감정 추출 중 오류가 발생했습니다.")

# 헬스 체크 엔드포인트
@app.get("/health")
async def health_check():
    """서비스 상태 확인"""
    return {
        "status": "healthy",
        "message": "통합 AI 서비스가 정상적으로 동작 중입니다",
        "services": {
            "stt": "available",
            "tts": "available",
            "fortune": "available" if api_key else "unavailable (API key not set)",
            "diary": "available" if api_key else "unavailable (API key not set)"
        },
        "timestamp": datetime.now().isoformat()
    }

@app.get("/")
async def root():
    """루트 엔드포인트"""
    return {
        "message": "Unified AI Service",
        "version": "1.0.0",
        "services": {
            "stt": "/stt/transcribe",
            "tts": "/tts",
            "fortune": "/fortune",
            "diary": "/diary/analyze",
            "health": "/health"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002) 