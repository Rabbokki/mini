from fastapi import APIRouter, File, UploadFile, HTTPException, Form
from transformers import pipeline
import tempfile
import os
import logging

router = APIRouter()

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Whisper 모델 로드 (최초 1회만)
try:
    logger.info("Whisper 모델 로딩 시작...")
    asr_pipeline = pipeline("automatic-speech-recognition", model="openai/whisper-medium")
    logger.info("Whisper 모델 로딩 완료")
except Exception as e:
    logger.error(f"Whisper 모델 로딩 실패: {e}")
    asr_pipeline = None

@router.post("/asr/")
async def asr_recognize(file: UploadFile = File(..., alias="audio"), language: str = Form("ko")):
    try:
        logger.info(f"ASR 요청 받음: 파일명={file.filename}, 언어={language}")
        
        if asr_pipeline is None:
            raise HTTPException(status_code=500, detail="ASR 모델이 로드되지 않았습니다")
        
        # 파일 확장자 확인 및 임시 파일 생성
        file_extension = ".m4a"
        if file.filename:
            file_extension = os.path.splitext(file.filename)[1].lower()
            if file_extension not in ['.wav', '.m4a', '.mp3', '.flac']:
                file_extension = ".m4a"
        
        logger.info(f"파일 확장자: {file_extension}")
        
        # 임시 파일로 저장
        with tempfile.NamedTemporaryFile(delete=False, suffix=file_extension) as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name
        
        logger.info(f"임시 파일 생성: {tmp_path}, 크기: {len(content)} bytes")
        
        # 음성 인식
        logger.info("음성 인식 시작...")
        result = asr_pipeline(tmp_path)
        text = result["text"] if isinstance(result, dict) else result
        logger.info(f"음성 인식 완료: {text}")
        
        # 임시 파일 삭제
        os.unlink(tmp_path)
        logger.info("임시 파일 삭제 완료")
        
        return {
            "success": True,
            "text": text,
            "language": "ko",
            "duration": 0.0,
            "segments": [],
            "timestamp": ""
        }
    except Exception as e:
        logger.error(f"ASR 처리 오류: {str(e)}", exc_info=True)
        # 임시 파일 정리
        if 'tmp_path' in locals() and os.path.exists(tmp_path):
            os.unlink(tmp_path)
            logger.info("오류 발생 시 임시 파일 정리 완료")
        raise HTTPException(status_code=500, detail=f"ASR 처리 오류: {str(e)}")

@router.get("/asr/supported-languages")
async def get_supported_languages():
    """지원하는 언어 목록 반환"""
    return {
        "languages": {
            "ko": "한국어",
            "en": "English",
            "ja": "日本語",
            "zh": "中文",
            "es": "Español",
            "fr": "Français",
            "de": "Deutsch",
            "it": "Italiano",
            "pt": "Português",
            "ru": "Русский"
        }
    } 