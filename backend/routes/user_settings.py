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
                    "shape": ["⭐", "🔶", "🔷", "⚫", "🔺"],
                    "fruit": ["🍎", "🍊", "🍌", "🍇", "🍓"],
                    "animal": ["🐶", "🐱", "🐰", "🐸", "🐼"],
                    "weather": ["☀️", "🌧️", "⛈️", "🌈", "❄️"]
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
                    "shape": ["⭐", "🔶", "🔷", "⚫", "🔺"],
                    "fruit": ["🍎", "🍊", "🍌", "🍇", "🍓"],
                    "animal": ["🐶", "🐱", "🐰", "🐸", "🐼"],
                    "weather": ["☀️", "🌧️", "⛈️", "🌈", "❄️"]
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
                "shape": ["⭐", "🔶", "🔷", "⚫", "🔺"],
                "fruit": ["🍎", "🍊", "🍌", "🍇", "🍓"],
                "animal": ["🐶", "🐱", "🐰", "🐸", "🐼"],
                "weather": ["☀️", "🌧️", "⛈️", "🌈", "❄️"]
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