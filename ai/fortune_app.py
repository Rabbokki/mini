from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import os
from dotenv import load_dotenv
import httpx

# 환경 변수 로드
load_dotenv()

app = FastAPI(
    title="AI Fortune Service",
    description="OpenAI를 사용한 개인화된 운세 생성 서비스",
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
    raise ValueError("OPENAI_API_KEY 환경 변수가 설정되지 않았습니다.")

class FortuneResponse(BaseModel):
    fortune: str

def generate_fortune(birthday: str) -> str:
    """OpenAI GPT를 사용하여 개인화된 운세를 생성합니다."""
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
        
        if not (1900 <= year <= datetime.now().year and 1 <= month <= 12 and 1 <= day <= 31):
            raise HTTPException(status_code=400, detail="올바른 생년월일을 입력해주세요.")
            
        # AI로 운세 생성
        fortune_text = generate_fortune(birthday)
        
        return FortuneResponse(fortune=fortune_text)
        
    except ValueError:
        raise HTTPException(status_code=400, detail="올바른 생년월일을 입력해주세요.")

@app.get("/")
async def root():
    """루트 경로 - API 정보 반환"""
    return {
        "message": "AI Fortune Service에 오신 것을 환영합니다",
        "version": "1.0.0",
        "endpoints": {
            "fortune": "/fortune?birthday=YYYYMMDD",
            "docs": "/docs"
        }
    }

@app.get("/health")
async def health_check():
    """헬스 체크 엔드포인트"""
    return {
        "status": "healthy",
        "message": "AI Fortune Service가 정상적으로 동작 중입니다"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)