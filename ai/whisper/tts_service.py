from fastapi import FastAPI, Query
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from gtts import gTTS
import os
import uuid

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

TTS_OUTPUT_DIR = "tts_outputs"
os.makedirs(TTS_OUTPUT_DIR, exist_ok=True)

@app.get("/tts")
def tts(text: str = Query(..., description="음성으로 변환할 텍스트")):
    try:
        print(f"TTS 요청 받음: {text}")
        tts = gTTS(text, lang='ko', slow=False)
        filename = f"{uuid.uuid4()}.mp3"
        filepath = os.path.join(TTS_OUTPUT_DIR, filename)
        print(f"파일 저장 경로: {filepath}")
        tts.save(filepath)
        
        # 파일이 실제로 생성되었는지 확인
        if os.path.exists(filepath):
            file_size = os.path.getsize(filepath)
            print(f"파일 생성 완료: {filename}, 크기: {file_size} bytes")
        else:
            print(f"파일 생성 실패: {filepath}")
            
        return {"audio_url": f"/tts/audio/{filename}"}
    except Exception as e:
        print(f"TTS 오류: {str(e)}")
        return JSONResponse(status_code=500, content={"error": str(e)})

@app.get("/tts/audio/{filename}")
def get_audio(filename: str):
    filepath = os.path.join(TTS_OUTPUT_DIR, filename)
    print(f"오디오 파일 요청: {filename}")
    print(f"파일 경로: {filepath}")
    if os.path.exists(filepath):
        file_size = os.path.getsize(filepath)
        print(f"파일 존재, 크기: {file_size} bytes")
        return FileResponse(filepath, media_type="audio/mpeg")
    print(f"파일 없음: {filepath}")
    return JSONResponse(status_code=404, content={"error": "파일을 찾을 수 없습니다."})

@app.get("/")
def root():
    return {"message": "TTS API"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5050) 