from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from datetime import datetime
import json
from typing import Dict, List

from database import user_settings, get_next_setting_id
from models.user_settings import UserSettings, UserSettingsUpdate, UserSettingsResponse
from auth_utils import verify_token, get_user_id_from_token

router = APIRouter()
security = HTTPBearer()

def get_current_user_id(credentials: HTTPAuthorizationCredentials = Depends(security)) -> int:
    """현재 사용자 ID를 가져옵니다."""
    try:
        token = credentials.credentials
        user_id = get_user_id_from_token(token)
        if user_id is None:
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다")
        return user_id
    except Exception as e:
        raise HTTPException(status_code=401, detail="인증에 실패했습니다")

@router.get("/", response_model=UserSettingsResponse)
async def get_user_settings(user_id: int = Depends(get_current_user_id)):
    """사용자 설정을 가져옵니다."""
    try:
        # 사용자 설정 조회
        setting = user_settings.find_one({"user_id": user_id})
        
        if not setting:
            # 설정이 없으면 기본 설정 생성
            default_settings = {
                "id": get_next_setting_id(),
                "user_id": user_id,
                "emoticon_enabled": True,
                "voice_enabled": True,
                "voice_volume": 50,
                "emoticon_categories": {
                    "shape": [
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfident_shape-removebg-preview.png?alt=media&token=8ab02bc8-8569-42ff-b78d-b9527f15d0af",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fdetermined_shape-removebg-preview.png?alt=media&token=69eb4cf0-ab61-4f5e-add3-b2148dc2a108",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fhappy_shape-removebg-preview.png?alt=media&token=5a8aa9dd-6ea5-4132-95af-385340846076",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fcalm_shape-removebg-preview.png?alt=media&token=cdc2fa85-10b7-46f6-881c-dd874c38b3ea",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Flove_shape-removebg-preview.png?alt=media&token=1a7ec74f-4297-42a4-aeb8-97aee1e9ff6c",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fsad_shape-removebg-preview.png?alt=media&token=acbc7284-1126-4428-a3b2-f8b6e7932b98",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Ftouched_shape-removebg-preview.png?alt=media&token=bbb50a1c-90d6-43fd-be40-4be4f51bc1d0",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fanxious_shape-removebg-preview.png?alt=media&token=7859ebac-cd9d-43a3-a42c-aec651d37e6e",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfused_shape-removebg-preview.png?alt=media&token=4794d127-9b61-4c68-86de-8478c4da8fb9"
                    ],
                    "fruit": [
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fhappy_fruit-removebg-preview.png?alt=media&token=d10a503b-fee7-4bc2-b141-fd4b33dae1f1",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fcalm_fruit-removebg-preview.png?alt=media&token=839efcad-0022-4cc9-ac38-90175d9026d2",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Flove_fruit-removebg-preview.png?alt=media&token=ba7857c6-5afd-48e0-addd-7b3f54583c15",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fexcited_fruit-removebg-preview.png?alt=media&token=0284bce2-aa88-4766-97fb-5d5d2248cf31",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fangry_fruit-removebg-preview.png?alt=media&token=679778b9-5a1b-469a-8e86-b01585cb1ee2",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fconfident_fruit-removebg-preview.png?alt=media&token=6edcc903-8d78-4dd9-bcdd-1c6b26645044",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fdetermined_fruit-removebg-preview.png?alt=media&token=ed288879-86c4-4d6d-946e-477f2aafc3ce",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fsad_fruit-removebg-preview.png?alt=media&token=e9e0b0f7-6590-4209-a7d1-26377eb33c05",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Ftouched_fruit-removebg-preview.png?alt=media&token=c69dee6d-7d53-4af7-a884-2f751aecbe42",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fanxious_fruit-removebg-preview.png?alt=media&token=be8f8279-2b08-47bf-9856-c39daf5eac40",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fconfused_fruit-removebg-preview.png?alt=media&token=7adfcf22-af7a-4eb1-a225-34875b6540cf"
                    ],
                    "animal": [
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fhappy_animal-removebg-preview.png?alt=media&token=66ff8e2d-d941-4fd7-9d7f-9766db03cbd5",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fcalm_animal-removebg-preview.png?alt=media&token=afd7bf65-5150-40e3-8b95-cd956dff113d",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Flove_animal-removebg-preview.png?alt=media&token=e0e2ccbd-b59a-4d09-968a-562208f90be1",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fexcited_animal-removebg-preview.png?alt=media&token=48442937-5504-4392-88a9-039aef405f14",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fangry_animal-removebg-preview.png?alt=media&token=9bde31db-8801-4af0-9368-e6ce4a35fbac",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fconfident__animal-removebg-preview.png?alt=media&token=2983b323-a2a6-40aa-9b6c-a381d944dd27",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fdetermined_animal-removebg-preview.png?alt=media&token=abf05981-4ab3-49b3-ba37-096ab8c22478",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fsad_animal-removebg-preview.png?alt=media&token=04c99bd8-8ad4-43de-91cd-3b7354780677",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Ftouched_animal-removebg-preview.png?alt=media&token=629be9ec-be17-407f-beb0-6b67f09b7036",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fanxious_animal-removebg-preview.png?alt=media&token=bd25e31d-629b-4e79-b95e-019f8c76dac2",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fconfused__animal-removebg-preview.png?alt=media&token=74192a1e-86a7-4eb6-b690-154984c427dc"
                    ],
                    "weather": [
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fhappy_weather-removebg-preview.png?alt=media&token=fd77e998-6f47-459a-bd1c-458e309fed41",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fcalm_weather-removebg-preview.png?alt=media&token=7703fd25-fe2b-4750-a415-5f86c4e7b058",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Flove_weather-removebg-preview.png?alt=media&token=2451105b-ab3e-482d-bf9f-12f0a6a69a53",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fexcited_weather-removebg-preview.png?alt=media&token=5de71f38-1178-4e3c-887e-af07547caba9",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fangry_weather-removebg-preview.png?alt=media&token=2f4c6212-697d-49b7-9d5e-ae1f2b1fa84e",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fconfident_weather-removebg-preview.png?alt=media&token=ea30d002-312b-4ae5-ad85-933bbc009dc6",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fdetermined_weather-removebg-preview.png?alt=media&token=0eb8fb3d-22dd-4b4f-8e12-7d830f32be6d",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fsad_weather-removebg-preview.png?alt=media&token=aa972b9a-8952-4dc7-abe7-692ec7be0d16",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Ftouched_weather-removebg-preview.png?alt=media&token=5e224042-72ae-45a4-891a-8e6abdb5285c",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fanxious_weather-removebg-preview.png?alt=media&token=fc718a17-8d8e-4ed1-a78a-891fa9a149d0",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fconfused_weather-removebg-preview.png?alt=media&token=afdfb6bf-2c69-4ef2-97a1-2e5aa67e6fdb"
                    ]
                },
                "last_selected_emotion_category": "shape",
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            }
            
            user_settings.insert_one(default_settings)
            setting = default_settings
        
        # ObjectId를 문자열로 변환
        if "_id" in setting:
            del setting["_id"]
        
        return UserSettingsResponse(
            success=True,
            message="사용자 설정을 성공적으로 가져왔습니다",
            data=UserSettings(**setting)
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"설정 조회 중 오류가 발생했습니다: {str(e)}")

@router.put("/", response_model=UserSettingsResponse)
async def update_user_settings(
    settings_update: UserSettingsUpdate,
    user_id: int = Depends(get_current_user_id)
):
    """사용자 설정을 업데이트합니다."""
    try:
        # 현재 설정 조회
        current_setting = user_settings.find_one({"user_id": user_id})
        
        if not current_setting:
            # 설정이 없으면 새로 생성
            new_setting = {
                "id": get_next_setting_id(),
                "user_id": user_id,
                "emoticon_enabled": settings_update.emoticon_enabled if settings_update.emoticon_enabled is not None else True,
                "voice_enabled": settings_update.voice_enabled if settings_update.voice_enabled is not None else True,
                "voice_volume": settings_update.voice_volume if settings_update.voice_volume is not None else 50,
                "emoticon_categories": settings_update.emoticon_categories if settings_update.emoticon_categories else {
                    "shape": [
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfident_shape-removebg-preview.png?alt=media&token=8ab02bc8-8569-42ff-b78d-b9527f15d0af",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fdetermined_shape-removebg-preview.png?alt=media&token=69eb4cf0-ab61-4f5e-add3-b2148dc2a108",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fhappy_shape-removebg-preview.png?alt=media&token=5a8aa9dd-6ea5-4132-95af-385340846076",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fcalm_shape-removebg-preview.png?alt=media&token=cdc2fa85-10b7-46f6-881c-dd874c38b3ea",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Flove_shape-removebg-preview.png?alt=media&token=1a7ec74f-4297-42a4-aeb8-97aee1e9ff6c",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fsad_shape-removebg-preview.png?alt=media&token=acbc7284-1126-4428-a3b2-f8b6e7932b98",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Ftouched_shape-removebg-preview.png?alt=media&token=bbb50a1c-90d6-43fd-be40-4be4f51bc1d0",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fanxious_shape-removebg-preview.png?alt=media&token=7859ebac-cd9d-43a3-a42c-aec651d37e6e",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfused_shape-removebg-preview.png?alt=media&token=4794d127-9b61-4c68-86de-8478c4da8fb9"
                    ],
                    "fruit": [
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fhappy_fruit-removebg-preview.png?alt=media&token=d10a503b-fee7-4bc2-b141-fd4b33dae1f1",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fcalm_fruit-removebg-preview.png?alt=media&token=839efcad-0022-4cc9-ac38-90175d9026d2",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Flove_fruit-removebg-preview.png?alt=media&token=ba7857c6-5afd-48e0-addd-7b3f54583c15",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fexcited_fruit-removebg-preview.png?alt=media&token=0284bce2-aa88-4766-97fb-5d5d2248cf31",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fangry_fruit-removebg-preview.png?alt=media&token=679778b9-5a1b-469a-8e86-b01585cb1ee2",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fconfident_fruit-removebg-preview.png?alt=media&token=6edcc903-8d78-4dd9-bcdd-1c6b26645044",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fdetermined_fruit-removebg-preview.png?alt=media&token=ed288879-86c4-4d6d-946e-477f2aafc3ce",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fsad_fruit-removebg-preview.png?alt=media&token=e9e0b0f7-6590-4209-a7d1-26377eb33c05",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Ftouched_fruit-removebg-preview.png?alt=media&token=c69dee6d-7d53-4af7-a884-2f751aecbe42",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fanxious_fruit-removebg-preview.png?alt=media&token=be8f8279-2b08-47bf-9856-c39daf5eac40",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fconfused_fruit-removebg-preview.png?alt=media&token=7adfcf22-af7a-4eb1-a225-34875b6540cf"
                    ],
                    "animal": [
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fhappy_animal-removebg-preview.png?alt=media&token=66ff8e2d-d941-4fd7-9d7f-9766db03cbd5",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fcalm_animal-removebg-preview.png?alt=media&token=afd7bf65-5150-40e3-8b95-cd956dff113d",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Flove_animal-removebg-preview.png?alt=media&token=e0e2ccbd-b59a-4d09-968a-562208f90be1",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fexcited_animal-removebg-preview.png?alt=media&token=48442937-5504-4392-88a9-039aef405f14",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fangry_animal-removebg-preview.png?alt=media&token=9bde31db-8801-4af0-9368-e6ce4a35fbac",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fconfident__animal-removebg-preview.png?alt=media&token=2983b323-a2a6-40aa-9b6c-a381d944dd27",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fdetermined_animal-removebg-preview.png?alt=media&token=abf05981-4ab3-49b3-ba37-096ab8c22478",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fsad_animal-removebg-preview.png?alt=media&token=04c99bd8-8ad4-43de-91cd-3b7354780677",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Ftouched_animal-removebg-preview.png?alt=media&token=629be9ec-be17-407f-beb0-6b67f09b7036",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fanxious_animal-removebg-preview.png?alt=media&token=bd25e31d-629b-4e79-b95e-019f8c76dac2",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fconfused__animal-removebg-preview.png?alt=media&token=74192a1e-86a7-4eb6-b690-154984c427dc"
                    ],
                    "weather": [
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fhappy_weather-removebg-preview.png?alt=media&token=fd77e998-6f47-459a-bd1c-458e309fed41",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fcalm_weather-removebg-preview.png?alt=media&token=7703fd25-fe2b-4750-a415-5f86c4e7b058",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Flove_weather-removebg-preview.png?alt=media&token=2451105b-ab3e-482d-bf9f-12f0a6a69a53",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fexcited_weather-removebg-preview.png?alt=media&token=5de71f38-1178-4e3c-887e-af07547caba9",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fangry_weather-removebg-preview.png?alt=media&token=2f4c6212-697d-49b7-9d5e-ae1f2b1fa84e",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fconfident_weather-removebg-preview.png?alt=media&token=ea30d002-312b-4ae5-ad85-933bbc009dc6",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fdetermined_weather-removebg-preview.png?alt=media&token=0eb8fb3d-22dd-4b4f-8e12-7d830f32be6d",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fsad_weather-removebg-preview.png?alt=media&token=aa972b9a-8952-4dc7-abe7-692ec7be0d16",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Ftouched_weather-removebg-preview.png?alt=media&token=5e224042-72ae-45a4-891a-8e6abdb5285c",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fanxious_weather-removebg-preview.png?alt=media&token=fc718a17-8d8e-4ed1-a78a-891fa9a149d0",
                        "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fconfused_weather-removebg-preview.png?alt=media&token=afdfb6bf-2c69-4ef2-97a1-2e5aa67e6fdb"
                    ]
                },
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            }
            
            user_settings.insert_one(new_setting)
            del new_setting["_id"]
            
            return UserSettingsResponse(
                success=True,
                message="사용자 설정이 성공적으로 생성되었습니다",
                data=UserSettings(**new_setting)
            )
        
        # 기존 설정 업데이트
        update_data = {"updated_at": datetime.now().isoformat()}
        
        if settings_update.emoticon_enabled is not None:
            update_data["emoticon_enabled"] = settings_update.emoticon_enabled
        
        if settings_update.voice_enabled is not None:
            update_data["voice_enabled"] = settings_update.voice_enabled
        
        if settings_update.voice_volume is not None:
            update_data["voice_volume"] = settings_update.voice_volume
        
        if settings_update.emoticon_categories is not None:
            update_data["emoticon_categories"] = settings_update.emoticon_categories
        
        if settings_update.last_selected_emotion_category is not None:
            update_data["last_selected_emotion_category"] = settings_update.last_selected_emotion_category
        
        # 설정 업데이트
        user_settings.update_one(
            {"user_id": user_id},
            {"$set": update_data}
        )
        
        # 업데이트된 설정 조회
        updated_setting = user_settings.find_one({"user_id": user_id})
        del updated_setting["_id"]
        
        return UserSettingsResponse(
            success=True,
            message="사용자 설정이 성공적으로 업데이트되었습니다",
            data=UserSettings(**updated_setting)
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"설정 업데이트 중 오류가 발생했습니다: {str(e)}")

@router.put("/emoticon-categories", response_model=UserSettingsResponse)
async def update_emoticon_categories(
    categories: Dict[str, List[str]],
    user_id: int = Depends(get_current_user_id)
):
    """이모티콘 카테고리를 업데이트합니다."""
    try:
        # 카테고리 유효성 검사
        valid_categories = ["shape", "fruit", "animal", "weather"]
        for category in categories.keys():
            if category not in valid_categories:
                raise HTTPException(status_code=400, detail=f"유효하지 않은 카테고리입니다: {category}")
            
            # 각 카테고리당 최대 5개 이모티콘 제한
            if len(categories[category]) > 5:
                raise HTTPException(status_code=400, detail=f"{category} 카테고리는 최대 5개의 이모티콘만 설정할 수 있습니다")
        
        # 현재 설정 조회
        current_setting = user_settings.find_one({"user_id": user_id})
        
        if not current_setting:
            # 설정이 없으면 새로 생성
            new_setting = {
                "id": get_next_setting_id(),
                "user_id": user_id,
                "emoticon_enabled": True,
                "voice_enabled": True,
                "voice_volume": 50,
                "emoticon_categories": categories,
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat()
            }
            
            user_settings.insert_one(new_setting)
            del new_setting["_id"]
            
            return UserSettingsResponse(
                success=True,
                message="이모티콘 카테고리가 성공적으로 생성되었습니다",
                data=UserSettings(**new_setting)
            )
        
        # 기존 설정 업데이트
        user_settings.update_one(
            {"user_id": user_id},
            {
                "$set": {
                    "emoticon_categories": categories,
                    "updated_at": datetime.now().isoformat()
                }
            }
        )
        
        # 업데이트된 설정 조회
        updated_setting = user_settings.find_one({"user_id": user_id})
        del updated_setting["_id"]
        
        return UserSettingsResponse(
            success=True,
            message="이모티콘 카테고리가 성공적으로 업데이트되었습니다",
            data=UserSettings(**updated_setting)
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"이모티콘 카테고리 업데이트 중 오류가 발생했습니다: {str(e)}")

@router.delete("/", response_model=UserSettingsResponse)
async def reset_user_settings(user_id: int = Depends(get_current_user_id)):
    """사용자 설정을 기본값으로 초기화합니다."""
    try:
        # 기본 설정으로 업데이트
        default_settings = {
            "emoticon_enabled": True,
            "voice_enabled": True,
            "voice_volume": 50,
            "emoticon_categories": {
                "shape": [
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfident_shape-removebg-preview.png?alt=media&token=8ab02bc8-8569-42ff-b78d-b9527f15d0af",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fdetermined_shape-removebg-preview.png?alt=media&token=69eb4cf0-ab61-4f5e-add3-b2148dc2a108",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fhappy_shape-removebg-preview.png?alt=media&token=5a8aa9dd-6ea5-4132-95af-385340846076",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fcalm_shape-removebg-preview.png?alt=media&token=cdc2fa85-10b7-46f6-881c-dd874c38b3ea",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Flove_shape-removebg-preview.png?alt=media&token=1a7ec74f-4297-42a4-aeb8-97aee1e9ff6c",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fsad_shape-removebg-preview.png?alt=media&token=acbc7284-1126-4428-a3b2-f8b6e7932b98",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Ftouched_shape-removebg-preview.png?alt=media&token=bbb50a1c-90d6-43fd-be40-4be4f51bc1d0",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fanxious_shape-removebg-preview.png?alt=media&token=7859ebac-cd9d-43a3-a42c-aec651d37e6e",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfused_shape-removebg-preview.png?alt=media&token=4794d127-9b61-4c68-86de-8478c4da8fb9"
                ],
                "fruit": [
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fhappy_fruit-removebg-preview.png?alt=media&token=d10a503b-fee7-4bc2-b141-fd4b33dae1f1",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fcalm_fruit-removebg-preview.png?alt=media&token=839efcad-0022-4cc9-ac38-90175d9026d2",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Flove_fruit-removebg-preview.png?alt=media&token=ba7857c6-5afd-48e0-addd-7b3f54583c15",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fexcited_fruit-removebg-preview.png?alt=media&token=0284bce2-aa88-4766-97fb-5d5d2248cf31",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fangry_fruit-removebg-preview.png?alt=media&token=679778b9-5a1b-469a-8e86-b01585cb1ee2",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fconfident_fruit-removebg-preview.png?alt=media&token=6edcc903-8d78-4dd9-bcdd-1c6b26645044",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fdetermined_fruit-removebg-preview.png?alt=media&token=ed288879-86c4-4d6d-946e-477f2aafc3ce",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fsad_fruit-removebg-preview.png?alt=media&token=e9e0b0f7-6590-4209-a7d1-26377eb33c05",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Ftouched_fruit-removebg-preview.png?alt=media&token=c69dee6d-7d53-4af7-a884-2f751aecbe42",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fanxious_fruit-removebg-preview.png?alt=media&token=be8f8279-2b08-47bf-9856-c39daf5eac40",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fconfused_fruit-removebg-preview.png?alt=media&token=7adfcf22-af7a-4eb1-a225-34875b6540cf"
                ],
                "animal": [
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fhappy_animal-removebg-preview.png?alt=media&token=66ff8e2d-d941-4fd7-9d7f-9766db03cbd5",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fcalm_animal-removebg-preview.png?alt=media&token=afd7bf65-5150-40e3-8b95-cd956dff113d",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Flove_animal-removebg-preview.png?alt=media&token=e0e2ccbd-b59a-4d09-968a-562208f90be1",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fexcited_animal-removebg-preview.png?alt=media&token=48442937-5504-4392-88a9-039aef405f14",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fangry_animal-removebg-preview.png?alt=media&token=9bde31db-8801-4af0-9368-e6ce4a35fbac",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fconfident__animal-removebg-preview.png?alt=media&token=2983b323-a2a6-40aa-9b6c-a381d944dd27",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fdetermined_animal-removebg-preview.png?alt=media&token=abf05981-4ab3-49b3-ba37-096ab8c22478",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fsad_animal-removebg-preview.png?alt=media&token=04c99bd8-8ad4-43de-91cd-3b7354780677",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Ftouched_animal-removebg-preview.png?alt=media&token=629be9ec-be17-407f-beb0-6b67f09b7036",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fanxious_animal-removebg-preview.png?alt=media&token=bd25e31d-629b-4e79-b95e-019f8c76dac2",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fconfused__animal-removebg-preview.png?alt=media&token=74192a1e-86a7-4eb6-b690-154984c427dc"
                ],
                "weather": [
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fhappy_weather-removebg-preview.png?alt=media&token=fd77e998-6f47-459a-bd1c-458e309fed41",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fcalm_weather-removebg-preview.png?alt=media&token=7703fd25-fe2b-4750-a415-5f86c4e7b058",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Flove_weather-removebg-preview.png?alt=media&token=2451105b-ab3e-482d-bf9f-12f0a6a69a53",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fexcited_weather-removebg-preview.png?alt=media&token=5de71f38-1178-4e3c-887e-af07547caba9",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fangry_weather-removebg-preview.png?alt=media&token=2f4c6212-697d-49b7-9d5e-ae1f2b1fa84e",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fconfident_weather-removebg-preview.png?alt=media&token=ea30d002-312b-4ae5-ad85-933bbc009dc6",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fdetermined_weather-removebg-preview.png?alt=media&token=0eb8fb3d-22dd-4b4f-8e12-7d830f32be6d",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fsad_weather-removebg-preview.png?alt=media&token=aa972b9a-8952-4dc7-abe7-692ec7be0d16",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Ftouched_weather-removebg-preview.png?alt=media&token=5e224042-72ae-45a4-891a-8e6abdb5285c",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fanxious_weather-removebg-preview.png?alt=media&token=fc718a17-8d8e-4ed1-a78a-891fa9a149d0",
                    "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fconfused_weather-removebg-preview.png?alt=media&token=afdfb6bf-2c69-4ef2-97a1-2e5aa67e6fdb"
                ]
            },
            "updated_at": datetime.now().isoformat()
        }
        
        user_settings.update_one(
            {"user_id": user_id},
            {"$set": default_settings},
            upsert=True
        )
        
        # 업데이트된 설정 조회
        updated_setting = user_settings.find_one({"user_id": user_id})
        del updated_setting["_id"]
        
        return UserSettingsResponse(
            success=True,
            message="사용자 설정이 기본값으로 초기화되었습니다",
            data=UserSettings(**updated_setting)
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"설정 초기화 중 오류가 발생했습니다: {str(e)}") 