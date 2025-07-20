from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routes.auth import router as auth_router
from routes.user_settings import router as user_settings_router
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
app.include_router(user_settings_router, prefix="/api/user-settings", tags=["user-settings"])
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
        import httpx
        import logging
        
        # 로깅 설정
        logger = logging.getLogger(__name__)
        logger.info(f"ASR 요청 받음: 파일명={file.filename}, 크기={file.size if hasattr(file, 'size') else 'unknown'}")
        
        # STT 서비스로 파일 전송
        async with httpx.AsyncClient() as client:
            file_content = await file.read()
            logger.info(f"파일 내용 읽음: {len(file_content)} bytes")
            
            files = {"audio": (file.filename or "audio.m4a", file_content, file.content_type or "audio/m4a")}
            logger.info(f"STT 서비스로 전송: http://localhost:5002/stt/transcribe")
            
            response = await client.post("http://localhost:5002/stt/transcribe", files=files)
            logger.info(f"STT 서비스 응답: 상태코드={response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                logger.info(f"STT 성공: 텍스트 길이={len(result.get('text', ''))}")
                return result
            else:
                logger.error(f"STT 서비스 오류: {response.status_code} - {response.text}")
                raise HTTPException(status_code=response.status_code, detail=f"STT 서비스 오류: {response.text}")
    except Exception as e:
        logger.error(f"ASR 처리 오류: {str(e)}", exc_info=True)
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



