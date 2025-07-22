from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
from openai import OpenAI
import os
from dotenv import load_dotenv
from fastapi.middleware.cors import CORSMiddleware
import logging
import re

logging.basicConfig(level=logging.INFO, encoding='utf-8')
logger = logging.getLogger(__name__)

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    http_client=None
)

class DiaryEntry(BaseModel):
    date: str
    text: str

class ComfortResponse(BaseModel):
    message: str

def truncate_to_complete_sentences(text: str, max_sentences: int = 3) -> str:
    """
    텍스트를 마침표(.), 느낌표(!), 물음표(?)로 끝나는 완전한 문장으로 자르고,
    최대 max_sentences 문장까지만 반환.
    """
    # 문장 끝을 나타내는 정규 표현식
    sentences = re.split(r'(?<=[.!?])\s+', text.strip())
    # 최대 max_sentences 문장까지만 선택
    complete_sentences = [s for s in sentences if s.endswith(('.', '!', '?'))][:max_sentences]
    # 문장이 없거나 불완전하면 기본 메시지 반환
    if not complete_sentences:
        return "오늘의 기분이 담긴 따뜻한 하루였어요. 내일도 좋은 순간들이 가득하길 바랍니다!"
    return ' '.join(complete_sentences)

@app.post("/api/analyze-diary", response_model=ComfortResponse)
async def analyze_diary(entry: DiaryEntry):
    try:
        if not entry.date or len(entry.date) != 10 or entry.date[4] != '-' or entry.date[7] != '-':
            raise HTTPException(status_code=400, detail="잘못된 날짜 형식입니다. YYYY-MM-DD 형식을 사용하세요")

        prompt = f"""
        사용자가 작성한 한국어 일기를 분석하고, 따뜻하고 위로가 되는 한국어 메시지를 작성해 주세요.
        일기 내용: {entry.text}
        메시지는 긍정적이고 공감적인 톤으로, 2-3개의 완전한 문장으로 작성해 주세요.
        각 문장은 반드시 마침표(.), 느낌표(!), 또는 물음표(?)로 끝나야 합니다.
        """

        logger.info(f"Calling OpenAI API with prompt: {prompt[:100].encode('utf-8').decode('utf-8')}...")

        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "당신은 따뜻하고 공감적인 조언을 제공하는 AI입니다."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=150,  # 토큰 수 증가
            temperature=0.7
        )

        if not response.choices or not response.choices[0].message.content:
            logger.error("OpenAI API returned empty response or no content")
            raise HTTPException(status_code=500, detail="OpenAI API에서 유효한 응답을 받지 못했습니다")

        comfort_message = response.choices[0].message.content.strip()
        # 완전한 문장까지만 반환
        truncated_message = truncate_to_complete_sentences(comfort_message)
        logger.info(f"Received response: {truncated_message.encode('utf-8').decode('utf-8')}")

        return ComfortResponse(message=truncated_message)

    except Exception as e:
        logger.error(f"Error processing diary: {str(e)}")
        raise HTTPException(status_code=500, detail=f"일기 처리 중 오류 발생: {str(e)}")

@app.get("/health")
async def health_check():
    return {"status": "API가 실행 중입니다"}