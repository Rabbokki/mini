from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from database import users, get_next_user_id
from auth_utils import get_password_hash, verify_password, create_access_token, verify_token
from datetime import datetime
from bson import ObjectId
from typing import Optional

router = APIRouter()
security = HTTPBearer()

class UserCreate(BaseModel):
    username: str
    password: str
    email: str
    birthday: str  # 생일 추가 (YYYY-MM-DD 형식)

class UserLogin(BaseModel):
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user_info: dict

class UserUpdate(BaseModel):
    username: Optional[str] = None
    password: Optional[str] = None
    email: Optional[str] = None
    birthday: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    birthday: str
    created_at: datetime

@router.post("/register")
async def register(user: UserCreate):
    # 사용자 중복 체크 (username과 email 모두 확인)
    if users.find_one({"username": user.username}):
        raise HTTPException(status_code=400, detail="이미 존재하는 사용자입니다")
    if users.find_one({"email": user.email}):
        raise HTTPException(status_code=400, detail="이미 존재하는 이메일입니다")
    
    # 패스워드 해싱
    hashed_password = get_password_hash(user.password)
    
    # 다음 단순 ID 생성
    simple_id = get_next_user_id()
    
    # 새로운 사용자 데이터 생성
    new_user = {
        "id": simple_id,  # 단순 숫자 ID (1, 2, 3, ...)
        "username": user.username,
        "password": hashed_password,  # 해싱된 패스워드 저장
        "email": user.email,
        "birthday": user.birthday,  # 생일 추가
        "created_at": datetime.utcnow()
    }
    
    # DB에 사용자 추가
    result = users.insert_one(new_user)
    
    # 사용자 설정 자동 생성 (Firebase URL로)
    from models.user_settings import UserSettings
    
    default_settings = UserSettings(
        user_id=simple_id,
        emoticon_enabled=True,
        voice_enabled=True,
        voice_volume=50,
        emoticon_categories={
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
        last_selected_emotion_category="shape",
        created_at=datetime.utcnow().isoformat(),
        updated_at=datetime.utcnow().isoformat()
    )
    
    # 사용자 설정을 DB에 저장
    from database import user_settings
    user_settings.insert_one(default_settings.dict())
    
    return {"message": "회원가입이 완료되었습니다", "user_id": simple_id}

@router.post("/login", response_model=Token)
async def login(user_credentials: UserLogin):
    # 사용자 조회 (email로 검색)
    user = users.find_one({"email": user_credentials.email})
    if not user:
        raise HTTPException(
            status_code=400, 
            detail="이메일 또는 패스워드가 잘못되었습니다"
        )
    
    # 패스워드 검증
    if not verify_password(user_credentials.password, user["password"]):
        raise HTTPException(
            status_code=400, 
            detail="이메일 또는 패스워드가 잘못되었습니다"
        )
    
    # JWT 토큰 생성 (user_id와 email 포함)
    access_token = create_access_token(data={
        "sub": user["email"],
        "user_id": user["id"]
    })
    
    # 사용자 정보 (패스워드 제외)
    user_info = {
        "id": user.get("id", str(user["_id"])),  # 단순 ID 또는 기존 ObjectId
        "username": user["username"],
        "email": user["email"],
        "created_at": user["created_at"],
        "birthday": user.get("birthday")  # 생일 정보 추가
    }
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_info": user_info
    }

@router.get("/users")
async def get_all_users():
    """모든 사용자 조회"""
    all_users = list(users.find({}, {"password": 0}))  # 패스워드 제외하고 조회
    user_list = []
    
    for user in all_users:
        user_data = {
            "id": user.get("id", str(user["_id"])),  # 단순 ID 우선, 없으면 ObjectId
            "username": user["username"],
            "email": user["email"],
            "birthday": user.get("birthday", ""),  # 생일 추가
            "created_at": user["created_at"]
        }
        user_list.append(user_data)
    
    return {"users": user_list, "total_count": len(user_list)}

@router.get("/users/{user_id}")
async def get_user_by_id(user_id: str):
    """특정 사용자 조회 (ID로)"""
    try:
        # 단순 숫자 ID로 먼저 검색
        try:
            simple_id = int(user_id)
            user = users.find_one({"id": simple_id})
        except ValueError:
            # 숫자가 아니면 ObjectId로 검색
            if ObjectId.is_valid(user_id):
                user = users.find_one({"_id": ObjectId(user_id)})
            else:
                user = None
        
        if not user:
            raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
        
        return {
            "id": user.get("id", str(user["_id"])),
            "username": user["username"],
            "email": user["email"],
            "birthday": user.get("birthday", ""),  # 생일 추가
            "created_at": user["created_at"]
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@router.get("/users/username/{username}")
async def get_user_by_username(username: str):
    """특정 사용자 조회 (username으로)"""
    user = users.find_one({"username": username})
    
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    return {
        "id": str(user["_id"]),
        "username": user["username"],
        "email": user["email"],
        "birthday": user.get("birthday", ""),  # 생일 추가
        "created_at": user["created_at"]
    }

@router.put("/users/{user_id}")
async def update_user(user_id: str, user_update: UserUpdate):
    """사용자 정보 수정"""
    try:
        # ObjectId 형식 확인
        if not ObjectId.is_valid(user_id):
            raise HTTPException(status_code=400, detail="잘못된 사용자 ID 형식입니다")
        
        # 기존 사용자 확인
        existing_user = users.find_one({"_id": ObjectId(user_id)})
        if not existing_user:
            raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
        
        # 업데이트할 데이터 준비 (None이 아닌 값만)
        update_data = {}
        if user_update.username is not None:
            # username 중복 체크 (다른 사용자와)
            duplicate_user = users.find_one({
                "username": user_update.username,
                "_id": {"$ne": ObjectId(user_id)}
            })
            if duplicate_user:
                raise HTTPException(status_code=400, detail="이미 존재하는 사용자명입니다")
            update_data["username"] = user_update.username
            
        if user_update.password is not None:
            update_data["password"] = user_update.password
            
        if user_update.email is not None:
            update_data["email"] = user_update.email
            
        if user_update.birthday is not None:
            update_data["birthday"] = user_update.birthday
        
        if not update_data:
            raise HTTPException(status_code=400, detail="수정할 데이터가 없습니다")
        
        # 수정일시 추가
        update_data["updated_at"] = datetime.utcnow()
        
        # 사용자 정보 업데이트
        result = users.update_one(
            {"_id": ObjectId(user_id)},
            {"$set": update_data}
        )
        
        if result.modified_count == 0:
            raise HTTPException(status_code=400, detail="사용자 정보 수정에 실패했습니다")
        
        # 업데이트된 사용자 정보 반환
        updated_user = users.find_one({"_id": ObjectId(user_id)})
        return {
            "message": "사용자 정보가 수정되었습니다",
            "user": {
                "id": str(updated_user["_id"]) if updated_user and "_id" in updated_user else None,
                "username": updated_user["username"] if updated_user and "username" in updated_user else None,
                "email": updated_user["email"] if updated_user and "email" in updated_user else None,
                "birthday": updated_user.get("birthday", "") if updated_user else None,
                "created_at": updated_user["created_at"] if updated_user and "created_at" in updated_user else None,
                "updated_at": updated_user.get("updated_at") if updated_user else None
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@router.delete("/users/{user_id}")
async def delete_user(user_id: str):
    """사용자 삭제"""
    try:
        # ObjectId 형식 확인
        if not ObjectId.is_valid(user_id):
            raise HTTPException(status_code=400, detail="잘못된 사용자 ID 형식입니다")
        
        # 기존 사용자 확인
        existing_user = users.find_one({"_id": ObjectId(user_id)})
        if not existing_user:
            raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
        
        # 사용자 삭제
        result = users.delete_one({"_id": ObjectId(user_id)})
        
        if result.deleted_count == 0:
            raise HTTPException(status_code=400, detail="사용자 삭제에 실패했습니다")
        
        return {
            "message": "사용자가 삭제되었습니다",
            "deleted_user": {
                "id": str(existing_user["_id"]),
                "username": existing_user["username"],
                "email": existing_user["email"]
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@router.delete("/users/username/{username}")
async def delete_user_by_username(username: str):
    """사용자 삭제 (username으로)"""
    # 기존 사용자 확인
    existing_user = users.find_one({"username": username})
    if not existing_user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
    
    # 사용자 삭제
    result = users.delete_one({"username": username})
    
    if result.deleted_count == 0:
        raise HTTPException(status_code=400, detail="사용자 삭제에 실패했습니다")
    
    return {
        "message": "사용자가 삭제되었습니다",
        "deleted_user": {
            "id": str(existing_user["_id"]),
            "username": existing_user["username"],
            "email": existing_user["email"]
        }
    }

@router.get("/user/profile")
async def get_user_profile(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """현재 로그인한 사용자의 프로필 정보 조회"""
    try:
        # JWT 토큰 검증
        payload = verify_token(credentials.credentials)
        user_email = payload.get("sub")
        
        if not user_email:
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다")
        
        # 사용자 정보 조회
        user = users.find_one({"email": user_email})
        if not user:
            raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
        
        return {
            "id": user.get("id", str(user["_id"])),
            "username": user["username"],
            "email": user["email"],
            "birthday": user.get("birthday", ""),
            "created_at": user["created_at"]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

@router.put("/user/profile")
async def update_user_profile(
    user_update: UserUpdate,
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    """현재 로그인한 사용자의 프로필 정보 수정"""
    try:
        # JWT 토큰 검증
        payload = verify_token(credentials.credentials)
        user_email = payload.get("sub")
        
        if not user_email:
            raise HTTPException(status_code=401, detail="유효하지 않은 토큰입니다")
        
        # 사용자 정보 조회
        user = users.find_one({"email": user_email})
        if not user:
            raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다")
        
        # 업데이트할 데이터 준비 (None이 아닌 값만)
        update_data = {}
        if user_update.username is not None:
            # username 중복 체크 (다른 사용자와)
            duplicate_user = users.find_one({
                "username": user_update.username,
                "email": {"$ne": user_email}
            })
            if duplicate_user:
                raise HTTPException(status_code=400, detail="이미 존재하는 사용자명입니다")
            update_data["username"] = user_update.username
            
        if user_update.password is not None:
            # 패스워드 해싱
            update_data["password"] = get_password_hash(user_update.password)
            
        if user_update.email is not None:
            # email 중복 체크 (다른 사용자와)
            duplicate_user = users.find_one({
                "email": user_update.email,
                "email": {"$ne": user_email}
            })
            if duplicate_user:
                raise HTTPException(status_code=400, detail="이미 존재하는 이메일입니다")
            update_data["email"] = user_update.email
            
        if user_update.birthday is not None:
            update_data["birthday"] = user_update.birthday
        
        if not update_data:
            raise HTTPException(status_code=400, detail="수정할 데이터가 없습니다")
        
        # 수정일시 추가
        update_data["updated_at"] = datetime.utcnow()
        
        # 사용자 정보 업데이트
        result = users.update_one(
            {"email": user_email},
            {"$set": update_data}
        )
        
        if result.modified_count == 0:
            raise HTTPException(status_code=400, detail="사용자 정보 수정에 실패했습니다")
        
        # 업데이트된 사용자 정보 반환
        updated_user = users.find_one({"email": user_email})
        return {
            "message": "프로필 정보가 수정되었습니다",
            "user": {
                "id": updated_user.get("id", str(updated_user["_id"])),
                "username": updated_user["username"],
                "email": updated_user["email"],
                "birthday": updated_user.get("birthday", ""),
                "created_at": updated_user["created_at"],
                "updated_at": updated_user.get("updated_at")
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {str(e)}")

