from fastapi import APIRouter, File, UploadFile, HTTPException
from transformers import pipeline
import tempfile

router = APIRouter()

# Whisper 모델 로드 (최초 1회만)
asr_pipeline = pipeline("automatic-speech-recognition", model="openai/whisper-medium")

@router.post("/asr/")
async def asr_recognize(file: UploadFile = File(...)):
    try:
        # 임시 파일로 저장
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            tmp.write(await file.read())
            tmp_path = tmp.name
        # 음성 인식
        result = asr_pipeline(tmp_path)
        text = result["text"] if isinstance(result, dict) else result
        return {"text": text}
    except Exception as e:
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