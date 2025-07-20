from pydantic import BaseModel
from typing import Dict, List, Optional
from enum import Enum

class EmotionType(str, Enum):
    """감정 타입 열거형"""
    shape = "shape"
    fruit = "fruit"
    animal = "animal"
    weather = "weather"

class UserSettings(BaseModel):
    """사용자 설정 모델"""
    id: Optional[int] = None
    user_id: int
    emoticon_enabled: bool = True
    voice_enabled: bool = True
    voice_volume: int = 50
    emoticon_categories: Dict[str, List[str]] = {
        "shape": ["⭐", "🔶", "🔷", "⚫", "🔺"],
        "fruit": ["🍎", "🍊", "🍌", "🍇", "🍓"],
        "animal": ["🐶", "🐱", "🐰", "🐸", "🐼"],
        "weather": ["☀️", "🌧️", "⛈️", "🌈", "❄️"]
    }
    last_selected_emotion_category: str = "shape"  # 마지막 선택된 카테고리
    created_at: Optional[str] = None
    updated_at: Optional[str] = None

class UserSettingsUpdate(BaseModel):
    """사용자 설정 업데이트 모델"""
    emoticon_enabled: Optional[bool] = None
    voice_enabled: Optional[bool] = None
    voice_volume: Optional[int] = None
    emoticon_categories: Optional[Dict[str, List[str]]] = None
    last_selected_emotion_category: Optional[str] = None

class UserSettingsResponse(BaseModel):
    """사용자 설정 응답 모델"""
    success: bool
    message: str
    data: Optional[UserSettings] = None 