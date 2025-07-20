"""
MongoDB 연결 및 데이터베이스 작업 모듈
"""
import os
from pymongo import MongoClient, IndexModel, ASCENDING, DESCENDING
from typing import Optional, Dict, Any, List
from datetime import datetime
import uuid
from dotenv import load_dotenv

# 환경변수 로드
load_dotenv()

# MongoDB 설정
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "mini_project")

# 전역 변수
client: Optional[MongoClient] = None
db = None

def init_mongodb() -> bool:
    """MongoDB 연결 초기화"""
    global client, db
    
    try:
        print(f"MongoDB 연결 시도: {MONGODB_URL}")
        client = MongoClient(MONGODB_URL, serverSelectionTimeoutMS=5000)
        
        # 연결 테스트
        client.admin.command('ping')
        print("MongoDB 연결 성공!")
        
        # 데이터베이스 선택
        db = client[DATABASE_NAME]
        print(f"데이터베이스 선택: {DATABASE_NAME}")
        
        # 인덱스 설정
        setup_indexes()
        
        return True
        
    except Exception as e:
        print(f"MongoDB 연결 실패: {str(e)}")
        client = None
        db = None
        return False

def setup_indexes():
    """데이터베이스 인덱스 설정"""
    if db is None:
        print("[WARNING] 데이터베이스가 초기화되지 않았습니다")
        return
        
    try:
        posts_collection = db.posts
        
        # 기존 인덱스 확인
        existing_indexes = list(posts_collection.list_indexes())
        index_names = [index['name'] for index in existing_indexes]
        
        # 생성할 인덱스 목록
        indexes_to_create = []
        
        # 1. 최신 글 조회용 (캐시링 요소별)
        if "created_at_desc" not in index_names:
            indexes_to_create.append(IndexModel([("created_at", DESCENDING)], name="created_at_desc"))
            
        # 2. 글 상태별 조회용
        if "status_asc" not in index_names:
            indexes_to_create.append(IndexModel([("status", ASCENDING)], name="status_asc"))
            
        # 3. 상태 + 생성일시 복합 인덱스 (게시된 글 목록 조회용)
        if "status_created_at_compound" not in index_names:
            indexes_to_create.append(IndexModel([
                ("status", ASCENDING),
                ("created_at", DESCENDING)
            ], name="status_created_at_compound"))
        
        # 인덱스 생성
        if indexes_to_create:
            posts_collection.create_indexes(indexes_to_create)
            print(f"[OK] 인덱스 {len(indexes_to_create)}개 생성 완료")
        else:
            print("[OK] 모든 필요한 인덱스가 이미 존재합니다")
            
    except Exception as e:
        print(f"[WARNING] 인덱스 설정 중 오류 발생: {str(e)}")

def get_database():
    """데이터베이스 객체 반환"""
    return db

def get_posts_collection():
    """posts 컬렉션 반환"""
    if db is None:
        raise Exception("데이터베이스가 초기화되지 않았습니다")
    return db.posts

def create_post(post_data: dict) -> str:
    """새 글 생성 (id: post_N 자동 부여)"""
    global db
    if db is None:
        raise Exception("MongoDB가 초기화되지 않았습니다")
    posts_collection = db.posts
    # 현재 글 개수 확인
    count = posts_collection.count_documents({})
    new_id = f"post_{count + 1}"
    post_data["id"] = new_id
    result = posts_collection.insert_one(post_data)
    return new_id

def parse_datetime(val):
    if isinstance(val, datetime):
        return val
    if isinstance(val, str):
        try:
            return datetime.fromisoformat(val.replace("Z", "+00:00"))
        except Exception:
            return datetime.utcnow()
    return datetime.utcnow()

def get_posts(status: str = "published", skip: int = 0, limit: int = 10) -> List[Dict[str, Any]]:
    """글 목록 조회 (캐시링 순서)"""
    collection = get_posts_collection()
    
    # 쿼리 조건
    query = {"status": status}
    
    # 최신순 정렬로 조회
    cursor = collection.find(query).sort("created_at", DESCENDING).skip(skip).limit(limit)
    
    posts = []
    for doc in cursor:
        post_id = doc.get("id") or doc.get("post_id") or str(doc.get("_id", ""))
        created = parse_datetime(doc.get("created_at"))
        updated = parse_datetime(doc.get("updated_at")) or created
        post = {
            "id": post_id,
            "title": doc.get("title", ""),
            "status": doc.get("status", ""),
            "created_at": created,
            "updated_at": updated,
            "images": doc.get("images", [])
        }
        posts.append(post)
    
    return posts

def get_post_by_id(post_id: str) -> Optional[Dict[str, Any]]:
    """특정 글 조회"""
    collection = get_posts_collection()
    
    doc = collection.find_one({"$or": [{"id": post_id}, {"post_id": post_id}]})
    
    if doc:
        found_id = doc.get("id") or doc.get("post_id") or str(doc.get("_id", ""))
        created = parse_datetime(doc.get("created_at"))
        updated = parse_datetime(doc.get("updated_at")) or created
        return {
            "id": found_id,
            "title": doc.get("title", ""),
            "content": doc.get("content", ""),
            "status": doc.get("status", ""),
            "created_at": created,
            "updated_at": updated,
            "images": doc.get("images", [])
        }
    
    return None

def update_post(post_id: str, update_data: Dict[str, Any]) -> bool:
    """글 수정"""
    collection = get_posts_collection()
    
    # 수정 시간 추가
    update_data["updated_at"] = datetime.utcnow()
    
    # 데이터베이스 업데이트
    result = collection.update_one(
        {"$or": [{"id": post_id}, {"post_id": post_id}]},
        {"$set": update_data}
    )
    
    return result.modified_count > 0

def delete_post(post_id: str) -> bool:
    """글 삭제 (상태 변경)"""
    return update_post(post_id, {"status": "deleted"})

def close_connection():
    """MongoDB 연결 종료"""
    global client
    if client:
        client.close()
        print("MongoDB 연결이 종료되었습니다")

class MongoDBClient:
    """MongoDB 클라이언트 클래스"""
    
    def __init__(self):
        self.client = None
        self.db = None
        self._connect()
    
    def _connect(self):
        """MongoDB 연결"""
        try:
            print(f"MongoDB 연결 시도: {MONGODB_URL}")
            self.client = MongoClient(MONGODB_URL, serverSelectionTimeoutMS=5000)
            
            # 연결 테스트
            self.client.admin.command('ping')
            print("MongoDB 연결 성공!")
            
            # 데이터베이스 선택
            self.db = self.client[DATABASE_NAME]
            print(f"데이터베이스 선택: {DATABASE_NAME}")
            
            return True
            
        except Exception as e:
            print(f"MongoDB 연결 실패: {str(e)}")
            self.client = None
            self.db = None
            return False
    
    def check_connection(self) -> bool:
        """연결 상태 확인"""
        if self.client is None or self.db is None:
            return False
        try:
            self.client.admin.command('ping')
            return True
        except:
            return False
    
    def connect(self) -> bool:
        """연결 시도"""
        return self._connect()
    
    def get_posts_collection(self):
        """posts 컬렉션 반환"""
        if self.db is None:
            raise Exception("데이터베이스가 초기화되지 않았습니다")
        return self.db.posts

def get_mongodb() -> MongoDBClient:
    """MongoDB 클라이언트 인스턴스 반환"""
    return MongoDBClient() 