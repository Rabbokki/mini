from pymongo import MongoClient
from dotenv import load_dotenv
import os

# .env 파일에서 환경변수 로드
load_dotenv()

# MongoDB 연결
client = MongoClient(os.getenv('MONGODB_URI', 'mongodb://localhost:27017/'))
db = client['mini_project']  # 데이터베이스 이름

# 컬렉션 정의
users = db['users']  # 사용자 컬렉션
counters = db['counters']  # ID 카운터 컬렉션
user_settings = db['user_settings']  # 사용자 설정 컬렉션
posts = db['posts']  # 일기 컬렉션 추가

def get_next_user_id():
    """다음 사용자 ID를 생성합니다 (1, 2, 3, ...)"""
    result = counters.find_one_and_update(
        {"_id": "user_id"},
        {"$inc": {"sequence_value": 1}},
        upsert=True,
        return_document=True
    )
    return result["sequence_value"]

def get_next_setting_id():
    """다음 설정 ID를 생성합니다 (1, 2, 3, ...)"""
    result = counters.find_one_and_update(
        {"_id": "setting_id"},
        {"$inc": {"sequence_value": 1}},
        upsert=True,
        return_document=True
    )
    return result["sequence_value"]

def get_next_post_id():
    """다음 일기 ID를 생성합니다 (1, 2, 3, ...)"""
    result = counters.find_one_and_update(
        {"_id": "post_id"},
        {"$inc": {"sequence_value": 1}},
        upsert=True,
        return_document=True
    )
    return result["sequence_value"]



