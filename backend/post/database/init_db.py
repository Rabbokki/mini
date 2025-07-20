#!/usr/bin/env python3
"""
MongoDB 데이터베이스 초기화 스크립트

이 스크립트는 캘린더 일기장 데이터베이스와 posts 컬렉션을 생성하고 
필요한 인덱스를 설정합니다. (샘플 데이터는 생성하지 않음)

사용법:
    python init_db.py
"""

import sys
import os
from datetime import datetime

# 현재 디렉토리를 Python 경로에 추가
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from mongodb import MongoDB

# def create_sample_posts(mongodb: MongoDB):
#     """샘플 글 데이터 생성 - 일기장에서는 사용하지 않음"""
#     try:
#         collection = mongodb.get_posts_collection()
#         
#         # 기존 데이터 확인
#         existing_count = collection.count_documents({})
#         if existing_count > 0:
#             print(f"이미 {existing_count}개의 글이 존재합니다.")
#             return
#         
#         # 샘플 데이터
#         sample_posts = [
#             {
#                 "post_id": "sample-post-1",
#                 "title": "첫 번째 일기",
#                 "content": "오늘은 새로운 일기장을 시작하는 날입니다!",
#                 "status": "published",
#                 "created_at": datetime.now(),
#                 "updated_at": datetime.now()
#             },
#             {
#                 "post_id": "sample-post-2", 
#                 "title": "두 번째 일기",
#                 "content": "캘린더 형식의 일기장이 완성되었습니다.",
#                 "status": "published",
#                 "created_at": datetime.now(),
#                 "updated_at": datetime.now()
#             },
#             {
#                 "post_id": "sample-post-3",
#                 "title": "삭제될 일기",
#                 "content": "이 일기는 삭제된 상태로 표시됩니다.",
#                 "status": "deleted",
#                 "created_at": datetime.now(),
#                 "updated_at": datetime.now()
#             }
#         ]
#         
#         # 샘플 데이터 삽입
#         result = collection.insert_many(sample_posts)
#         print(f"[OK] {len(result.inserted_ids)}개의 샘플 글이 생성되었습니다.")
#         
#         # 삽입된 데이터 확인
#         for post in sample_posts:
#             print(f"   - {post['title']} (상태: {post['status']})")
#             
#     except Exception as e:
#         print(f"[ERROR] 샘플 데이터 생성 실패: {e}")

def verify_setup(mongodb: MongoDB):
    """설정 검증"""
    try:
        print("\n[INFO] 데이터베이스 설정 검증:")
        
        # 연결 상태 확인
        if mongodb.check_connection():
            print("[OK] MongoDB 연결: 정상")
        else:
            print("[ERROR] MongoDB 연결: 실패")
            return False
        
        # 데이터베이스 정보 조회
        db_info = mongodb.get_database_info()
        if "error" not in db_info:
            print(f"[OK] 데이터베이스: {db_info['database_name']}")
            print(f"[OK] 컬렉션: {db_info['collection_name']}")
            print(f"[OK] 문서 수: {db_info['document_count']}")
            print(f"[OK] 저장 크기: {db_info['storage_size']} bytes")
            
            # 인덱스 정보
            print("[OK] 인덱스 목록:")
            for index in db_info['indexes']:
                print(f"   - {index['name']}")
        else:
            print(f"[ERROR] 데이터베이스 정보 조회 실패: {db_info['error']}")
            return False
        
        return True
        
    except Exception as e:
        print(f"[ERROR] 설정 검증 실패: {e}")
        return False

def main():
    """메인 함수"""
    print("캘린더 일기장 데이터베이스 초기화를 시작합니다...\n")
    
    # MongoDB 인스턴스 생성
    mongodb = MongoDB()
    
    try:
        # 1. MongoDB 연결
        print("1. MongoDB 연결 중...")
        if not mongodb.connect():
            print("[ERROR] MongoDB 연결에 실패했습니다.")
            print("\n[INFO] 해결 방법:")
            print("   1. MongoDB가 설치되어 있는지 확인하세요")
            print("   2. MongoDB 서비스가 실행 중인지 확인하세요:")
            print("      - Windows: net start MongoDB")
            print("      - macOS/Linux: sudo systemctl start mongod")
            print("   3. 연결 URL이 올바른지 확인하세요: mongodb://localhost:27017")
            sys.exit(1)
        
        # 2. 컬렉션 및 인덱스 설정 (이미 connect()에서 수행됨)
        print("2. 컬렉션 및 인덱스 설정 완료")
        
        # 3. 데이터베이스 준비 완료 (샘플 데이터 생성 안함)
        print("3. 일기장 데이터베이스 준비 완료")
        
        # 4. 설정 검증
        print("4. 설정 검증 중...")
        if verify_setup(mongodb):
            print("\n[SUCCESS] 캘린더 일기장 데이터베이스 초기화가 완료되었습니다!")
            print("\n다음 단계:")
            print("   1. FastAPI 애플리케이션을 실행하세요: python app.py")
            print("   2. API 문서를 확인하세요: http://localhost:8000/docs")
            print("   3. 첫 번째 일기를 작성해보세요!")
        else:
            print("\n[ERROR] 설정 검증에 실패했습니다.")
            sys.exit(1)
        
    except KeyboardInterrupt:
        print("\n[INFO] 초기화가 중단되었습니다.")
    except Exception as e:
        print(f"\n[ERROR] 초기화 중 오류가 발생했습니다: {e}")
        sys.exit(1)
    finally:
        # MongoDB 연결 해제
        mongodb.disconnect()

if __name__ == "__main__":
    main() 