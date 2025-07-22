#!/usr/bin/env python3
"""
이모티콘 마이그레이션 스크립트
기존 사용자들의 이모티콘 데이터를 Firebase URL로 업데이트
"""

import asyncio
import motor.motor_asyncio
from datetime import datetime
import os
from dotenv import load_dotenv

# 환경 변수 로드
load_dotenv()

# MongoDB 연결 설정
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "diary_app")

# 새로운 Firebase 이모티콘 URL들
NEW_EMOTICON_CATEGORIES = {
    "shape": [
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfident_shape-removebg-preview.png?alt=media&token=8ab02bc8-8569-42ff-b78d-b9527f15d0af",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fdetermined_shape-removebg-preview.png?alt=media&token=69eb4cf0-ab61-4f5e-add3-b2148dc2a108"
    ],
    "fruit": [
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fhappy_fruit-removebg-preview.png?alt=media&token=d10a503b-fee7-4bc2-b141-fd4b33dae1f1",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fcalm_fruit-removebg-preview.png?alt=media&token=839efcad-0022-4cc9-ac38-90175d9026d2",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Flove_fruit-removebg-preview.png?alt=media&token=ba7857c6-5afd-48e0-addd-7b3f54583c15",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fexcited_fruit-removebg-preview.png?alt=media&token=0284bce2-aa88-4766-97fb-5d5d2248cf31"
    ],
    "animal": [
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fhappy_animal-removebg-preview.png?alt=media&token=66ff8e2d-d941-4fd7-9d7f-9766db03cbd5",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fcalm_animal-removebg-preview.png?alt=media&token=afd7bf65-5150-40e3-8b95-cd956dff113d",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Flove_animal-removebg-preview.png?alt=media&token=e0e2ccbd-b59a-4d09-968a-562208f90be1",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fexcited_animal-removebg-preview.png?alt=media&token=48442937-5504-4392-88a9-039aef405f14"
    ],
    "weather": [
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fhappy_weather-removebg-preview.png?alt=media&token=fd77e998-6f47-459a-bd1c-458e309fed41",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fcalm_weather-removebg-preview.png?alt=media&token=7703fd25-fe2b-4750-a415-5f86c4e7b058",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Flove_weather-removebg-preview.png?alt=media&token=2451105b-ab3e-482d-bf9f-12f0a6a69a53",
        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fexcited_weather-removebg-preview.png?alt=media&token=5de71f38-1178-4e3c-887e-af07547caba9"
    ]
}

async def migrate_emoticons():
    """이모티콘 데이터를 Firebase URL로 마이그레이션"""
    try:
        # MongoDB 연결
        client = motor.motor_asyncio.AsyncIOMotorClient(MONGODB_URL)
        db = client[DATABASE_NAME]
        user_settings_collection = db.user_settings
        
        print("🔧 이모티콘 마이그레이션 시작...")
        
        # 모든 사용자 설정 조회
        cursor = user_settings_collection.find({})
        updated_count = 0
        
        async for document in cursor:
            user_id = document.get('user_id')
            current_emoticons = document.get('emoticon_categories', {})
            
            print(f"사용자 {user_id}의 현재 이모티콘: {current_emoticons}")
            
            # 이모티콘 업데이트가 필요한지 확인
            needs_update = False
            for category, emoticons in current_emoticons.items():
                if category in NEW_EMOTICON_CATEGORIES:
                    print(f"  카테고리 {category} 확인 중...")
                    # 기존 이모티콘이 단순 이모지인지 확인
                    if emoticons and isinstance(emoticons, list):
                        for emoticon in emoticons:
                            if isinstance(emoticon, str) and not emoticon.startswith('http'):
                                print(f"    이모지 발견: {emoticon}")
                                needs_update = True
                                break
                        if needs_update:
                            break
            
            print(f"  업데이트 필요: {needs_update}")
            
            if needs_update:
                # 새로운 이모티콘으로 업데이트
                update_result = await user_settings_collection.update_one(
                    {'_id': document['_id']},
                    {
                        '$set': {
                            'emoticon_categories': NEW_EMOTICON_CATEGORIES,
                            'updated_at': datetime.utcnow().isoformat()
                        }
                    }
                )
                
                if update_result.modified_count > 0:
                    updated_count += 1
                    print(f"✅ 사용자 {user_id}의 이모티콘 업데이트 완료")
                else:
                    print(f"❌ 사용자 {user_id}의 이모티콘 업데이트 실패")
            else:
                print(f"⏭️ 사용자 {user_id}의 이모티콘은 이미 최신 상태")
        
        print(f"\n🎉 마이그레이션 완료! 총 {updated_count}명의 사용자 이모티콘 업데이트됨")
        
    except Exception as e:
        print(f"❌ 마이그레이션 중 오류 발생: {e}")
    finally:
        client.close()

if __name__ == "__main__":
    print("🚀 이모티콘 마이그레이션 스크립트 실행")
    print("⚠️ 이 작업은 되돌릴 수 없습니다. 계속하시겠습니까? (y/N): ", end="")
    
    response = input().strip().lower()
    if response in ['y', 'yes']:
        asyncio.run(migrate_emoticons())
    else:
        print("❌ 마이그레이션이 취소되었습니다.") 