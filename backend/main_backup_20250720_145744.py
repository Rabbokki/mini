from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routes.auth import router as auth_router
from post.routes.posts import router as posts_router
from post.database.mongodb import init_mongodb
import os
# from routes.asr import router as asr_router  # ASR 라우터 제거
from routes.images import router as images_router

app = FastAPI(
    title="AI Mini Implementation - 통합 API",
    description="인증 시스템과 포스트 시스템을 통합한 FastAPI 애플리케이션",
    version="1.0.0"
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 실제 운영환경에서는 구체적인 도메인을 지정해야 합니다
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 정적 파일 서빙 설정
if os.path.exists("uploads"):
    app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
    app.mount("/images", StaticFiles(directory="uploads/images"), name="images")
    app.mount("/temp", StaticFiles(directory="uploads/temp"), name="temp")

# 라우터 등록
app.include_router(auth_router, prefix="/api/auth", tags=["auth"])
app.include_router(posts_router, prefix="/api/posts", tags=["posts"])
app.include_router(images_router, prefix="/api/images", tags=["images"])

# 애플리케이션 시작 시 실행
@app.on_event("startup")
async def startup_event():
    """애플리케이션 시작 시 초기화"""
    print("애플리케이션이 시작됩니다...")
    
    # 업로드 디렉토리 생성
    upload_dirs = ["uploads/images", "uploads/temp"]
    for directory in upload_dirs:
        os.makedirs(directory, exist_ok=True)
        print(f"[OK] 업로드 디렉토리 생성: {directory}")
    
    # MongoDB 초기화
    success = init_mongodb()
    if success:
        print("[OK] MongoDB 연결 성공")
    else:
        print("[WARNING] MongoDB 연결 실패 - 일부 기능이 제한될 수 있습니다")

# 루트 경로
@app.get("/")
async def root():
    """루트 경로 - API 정보 반환"""
    return {
        "message": "AI Mini Implementation API에 오신 것을 환영합니다",
        "version": "1.0.0",
        "features": ["인증 시스템", "포스트 시스템", "이미지 업로드"],
        "docs": "/docs",
        "redoc": "/redoc"
    }

# ASR 엔드포인트
@app.post("/api/asr/")
async def asr_recognize(file: UploadFile = File(..., alias="audio"), language: str = Form("ko")):
    """음성-텍스트 변환"""
    try:
        from transformers import pipeline
        import tempfile
        import os
        
        # Whisper 모델 로드 (최초 1회만)
        asr_pipeline = pipeline("automatic-speech-recognition", model="openai/whisper-medium")
        
        # 파일 확장자 확인 (filename이 None일 수 있음)
        file_extension = ".m4a"  # 기본값
        if file.filename:
            file_extension = os.path.splitext(file.filename)[1].lower()
            if file_extension not in ['.wav', '.m4a', '.mp3', '.flac']:
                file_extension = ".m4a"  # 기본값으로 설정
        
        # 임시 파일로 저장
        with tempfile.NamedTemporaryFile(delete=False, suffix=file_extension) as tmp:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name
        
        try:
            # 음성 인식
            result = asr_pipeline(tmp_path)
            text = result["text"] if isinstance(result, dict) else result
            
            # 임시 파일 삭제
            os.unlink(tmp_path)
            
            return {
                "success": True,
                "text": text,
                "language": "ko",
                "duration": 0.0,
                "segments": [],
                "timestamp": ""
            }
        except Exception as e:
            # 임시 파일 삭제
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
            raise e
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"ASR 처리 오류: {str(e)}")

@app.get("/api/asr/supported-languages")
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

# 헬스 체크 엔드포인트
@app.get("/health")
async def health_check():
    """애플리케이션 상태 확인"""
    return {
        "status": "healthy", 
        "message": "API가 정상적으로 동작 중입니다",
        "services": {
            "auth": "available",
            "posts": "available",
            "asr": "available"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)



