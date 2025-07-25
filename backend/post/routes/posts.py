from fastapi import APIRouter, HTTPException, status, UploadFile, File, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import List
from datetime import datetime
import uuid
import os

from post.models.post import (
    PostCreate, PostUpdate, PostListResponse, PostDetailResponse,
    PostCreateResponse, PostUpdateResponse, PostDeleteResponse, PostStatus,
    ImageUploadResponse, ImageDeleteResponse, ImageInfo
)
from post.database.mongodb import get_mongodb
from post.utils.image_utils import image_utils, move_temp_to_permanent
from auth_utils import verify_token, get_user_id_from_token
from database import posts as posts_collection, user_settings

router = APIRouter(tags=["posts"])
security = HTTPBearer()


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """현재 인증된 사용자 정보를 가져옵니다"""
    try:
        # 토큰에서 user_id 직접 추출
        user_id = get_user_id_from_token(credentials.credentials)
        print(f"DEBUG: get_current_user - user_id: {user_id}")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="유효하지 않은 토큰입니다"
            )
        return user_id
    except Exception as e:
        print(f"DEBUG: get_current_user - error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="인증에 실패했습니다"
        )

def get_user_emoticon_category(user_id: int) -> str:
    """사용자의 선택된 이모지 카테고리를 가져옵니다"""
    try:
        # 사용자 설정이 없으면 기본값 반환 (무한루프 방지)
        setting = user_settings.find_one({"user_id": user_id})
        if setting and "last_selected_emotion_category" in setting:
            category = setting["last_selected_emotion_category"]
            # 유효한 카테고리인지 확인
            valid_categories = ["shape", "fruit", "animal", "weather"]
            if category in valid_categories:
                return category
        return "shape"  # 기본값
    except Exception as e:
        print(f"사용자 이모지 카테고리 조회 실패: {e}")
        return "shape"  # 기본값

def get_emotion_emoji_url(emotion: str, category: str) -> str:
    """감정과 카테고리에 따른 이모지 URL을 반환합니다"""
    # 모든 카테고리의 이모지 URL 매핑
    emotion_emoji_maps = {
        "shape": {
            "angry": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fangry_shape-removebg-preview.png?alt=media&token=92a25f79-4c1d-4b5d-9e5c-2f469e56cefa",
            "anxious": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fanxious_shape-removebg-preview.png?alt=media&token=7859ebac-cd9d-43a3-a42c-aec651d37e6e",
            "calm": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fcalm_shape-removebg-preview.png?alt=media&token=cdc2fa85-10b7-46f6-881c-dd874c38b3ea",
            "confident": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfident_shape-removebg-preview.png?alt=media&token=8ab02c8-8569-42ff-b78d-b9527f15d0af",
            "confused": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fconfused_shape-removebg-preview.png?alt=media&token=4794d127-9b61-4c68-86de-8478c4da8fb9",
            "determined": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fdetermined_shape-removebg-preview.png?alt=media&token=69eb4cf0-ab61-4f5e-add3-b2148dc2a108",
            "excited": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fexcited_shape-removebg-preview.png?alt=media&token=85fadfb8-7006-44d0-a39d-b3fd6070bb96",
            "happy": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fhappy_shape-removebg-preview.png?alt=media&token=5a8aa9dd-6ea5-4132-95af-385340846076",
            "love": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Flove_shape-removebg-preview.png?alt=media&token=1a7ec74f-4297-42a4-aeb8-97aee1e9ff6c",
            "neutral": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fneutral_shape-removebg-preview.png?alt=media&token=02e85132-3a83-4257-8c1e-d2e478c7fcf5",
            "sad": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Fsad_shape-removebg-preview.png?alt=media&token=acbc7284-1126-4428-a3b2-f8b6e7932b98",
            "touched": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/shape%2Ftouched_shape-removebg-preview.png?alt=media&token=bbb50a1c-90d6-43fd-be40-4be4f51bc1d0",
        },
        "fruit": {
            "angry": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fangry_fruit-removebg-preview.png?alt=media&token=679778b9-5a1b-469a-8e86-b01585cb1ee2",
            "anxious": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fanxious_fruit-removebg-preview.png?alt=media&token=be8f8279-2b08-47bf-9856-c39daf5eac40",
            "calm": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fcalm_fruit-removebg-preview.png?alt=media&token=839efcad-0022-4cc9-ac38-90175d9026d2",
            "confident": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fconfident_fruit-removebg-preview.png?alt=media&token=6edcc903-8d78-4dd9-bcdd-1c6b26645044",
            "confused": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fconfused_fruit-removebg-preview.png?alt=media&token=7adfcf22-af7a-4eb1-a225-34875b6540cf",
            "determined": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fdetermined_fruit-removebg-preview.png?alt=media&token=ed288879-86c4-4d6d-946e-477f2aafc3ce",
            "excited": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fexcited_fruit-removebg-preview.png?alt=media&token=0284bce2-aa88-4766-97fb-5d5d2248cf31",
            "happy": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fhappy_fruit-removebg-preview.png?alt=media&token=d10a503b-fee7-4bc2-b141-fd4b33dae1f1",
            "love": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Flove_fruit-removebg-preview.png?alt=media&token=ba7857c6-5afd-48e0-addd-7b3f54583c15",
            "neutral": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fneutral_fruit-removebg-preview.png?alt=media&token=9bdea06c-13e6-4c59-b961-1424422a3c39",
            "sad": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Fsad_fruit-removebg-preview.png?alt=media&token=e9e0b0f7-6590-4209-a7d1-26377eb33c05",
            "touched": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/fruit%2Ftouched_fruit-removebg-preview.png?alt=media&token=c69dee6d-7d53-4af7-a884-2f751aecbe42",
        },
        "animal": {
            "angry": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fangry_animal-removebg-preview.png?alt=media&token=9bde31db-8801-4af0-9368-e6ce4a35fbac",
            "anxious": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fanxious_animal-removebg-preview.png?alt=media&token=bd25e31d-629b-4e79-b95e-019f8c76dac2",
            "calm": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fcalm_animal-removebg-preview.png?alt=media&token=afd7bf65-5150-40e3-8b95-cd956dff113d",
            "confident": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fconfident__animal-removebg-preview.png?alt=media&token=2983b323-a2a6-40aa-9b6c-a381d944dd27",
            "confused": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fconfused__animal-removebg-preview.png?alt=media&token=74192a1e-86a7-4eb6-b690-154984c427dc",
            "determined": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fdetermined_animal-removebg-preview.png?alt=media&token=abf05981-4ab3-49b3-ba37-096ab8c22478",
            "excited": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fexcited_animal-removebg-preview.png?alt=media&token=48442937-5504-4392-88a9-039aef405f14",
            "happy": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fhappy_animal-removebg-preview.png?alt=media&token=66ff8e2d-d941-4fd7-9d7f-9766db03cbd5",
            "love": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Flove_animal-removebg-preview.png?alt=media&token=e0e2ccbd-b59a-4d09-968a-562208f90be1",
            "neutral": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fneutral_animal-removebg-preview.png?alt=media&token=f884e38d-5d8c-4d4a-bb62-a47a198d384f",
            "sad": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Fsad_animal-removebg-preview.png?alt=media&token=04c99bd8-8ad4-43de-91cd-3b7354780677",
            "touched": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/animal%2Ftouched_animal-removebg-preview.png?alt=media&token=629be9ec-be17-407f-beb0-6b67f09b7036",
        },
        "weather": {
            "angry": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fangry_weather-removebg-preview.png?alt=media&token=2f4c6212-697d-49b7-9d5e-ae1f2b1fa84e",
            "anxious": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fanxious_weather-removebg-preview.png?alt=media&token=fc718a17-8d8e-4ed1-a78a-891fa9a149d0",
            "calm": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fcalm_weather-removebg-preview.png?alt=media&token=7703fd25-fe2b-4750-a415-5f86c4e7b058",
            "confident": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fconfident_weather-removebg-preview.png?alt=media&token=ea30d002-312b-4ae5-ad85-933bbc009dc6",
            "confused": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fconfused_weather-removebg-preview.png?alt=media&token=afdfb6bf-2c69-4ef2-97a1-2e5aa67e6fdb",
            "determined": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fdetermined_weather-removebg-preview.png?alt=media&token=0eb8fb3d-22dd-4b4f-8e12-7d830f32be6d",
            "excited": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fexcited_weather-removebg-preview.png?alt=media&token=5de71f38-1178-4e3c-887e-af07547caba9",
            "happy": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fhappy_weather-removebg-preview.png?alt=media&token=fd77e998-6f47-459a-bd1c-458e309fed41",
            "love": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Flove_weather-removebg-preview.png?alt=media&token=2451105b-ab3e-482d-bf9f-12f0a6a69a53",
            "neutral": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fneutral_weather-removebg-preview.png?alt=media&token=57ad1adf-baa6-4b79-96f5-066a4ec3358f",
            "sad": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Fsad_weather-removebg-preview.png?alt=media&token=aa972b9a-8952-4dc7-abe7-692ec7be0d16",
            "touched": "https://firebasestorage.googleapis.com/v0/b/diary-3bbf7.firebasestorage.app/o/wheather%2Ftouched_weather-removebg-preview.png?alt=media&token=5e224042-72ae-45a4-891a-8e6abdb5285c",
        }
    }
    
    # 선택된 카테고리의 이모지 매핑에서 해당 감정의 URL 반환
    category_map = emotion_emoji_maps.get(category, emotion_emoji_maps["shape"])
    return category_map.get(emotion, category_map["neutral"])
    
@router.post("/", response_model=PostCreateResponse, status_code=status.HTTP_201_CREATED)
async def create_post(post_data: PostCreate, current_user_id: int = Depends(get_current_user)):
    """일기 작성"""
    try:
        collection = posts_collection
        
        # 새로운 일기 ID 생성
        post_id = str(uuid.uuid4())
        
        # 현재 시간
        current_time = post_data.created_at if post_data.created_at else datetime.now()
        
        # 이미지 처리
        images_info = []
        if post_data.images:
            print(f"DEBUG: 일기 저장 - 이미지 목록: {post_data.images}")
            for temp_filename in post_data.images:
                try:
                    print(f"DEBUG: 임시 파일 처리 시작: {temp_filename}")
                    # 임시 파일 존재 확인
                    temp_path = os.path.join("uploads/temp", temp_filename)
                    print(f"DEBUG: 임시 파일 경로: {temp_path}")
                    print(f"DEBUG: 임시 파일 존재: {os.path.exists(temp_path)}")
                    
                    # 임시 파일을 정식 업로드 폴더로 이동
                    permanent_filename = move_temp_to_permanent(temp_filename)
                    
                    # 이미지 정보 저장
                    file_info = image_utils.get_file_info(permanent_filename)
                    images_info.append({
                        "filename": permanent_filename,
                        "original_filename": temp_filename,
                        "file_path": os.path.join("uploads/images", permanent_filename),
                        "file_size": file_info["file_size"] if file_info else 0,
                        "upload_date": current_time
                    })
                except HTTPException:
                    # 임시 파일 이동 실패 시 다른 임시 파일들 정리
                    for temp_file in post_data.images:
                        image_utils.delete_temp_file(temp_file)
                    raise
        
        # 사용자의 선택된 이모지 카테고리 가져오기
        user_category = get_user_emoticon_category(current_user_id)
        print(f"DEBUG: 사용자 선택 카테고리: {user_category}")
        
        # 감정에 따른 이모지 URL 가져오기 (사용자 선택 카테고리 기준)
        emoji_url = get_emotion_emoji_url(post_data.emotion, user_category)
        print(f"DEBUG: 선택된 이모지 URL: {emoji_url}")
        
        # 일기 데이터 저장 (사용자 ID 추가)
        new_post = {
            "post_id": post_id,
            "user_id": current_user_id,  # 사용자 ID 추가
            "content": post_data.content,
            "status": post_data.status,
            "emotion": post_data.emotion,  # 감정 정보 추가
            "emoji": emoji_url,  # 사용자 선택 카테고리의 이모지 URL
            "images": images_info,
            "created_at": current_time
        }
        
        # MongoDB 문서 생성 및 저장
        result = collection.insert_one(new_post)
        
        if not result.inserted_id:
            # 저장 실패 시 업로드된 이미지들 삭제
            for img_info in images_info:
                image_utils.delete_permanent_file(img_info["filename"])
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="일기 저장에 실패했습니다"
            )
        
        return PostCreateResponse(
            message="일기가 성공적으로 작성되었습니다",
            post_id=post_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"일기 작성 중 오류가 발생했습니다: {str(e)}"
        )
    


@router.get("/", response_model=List[PostListResponse])
async def get_posts(current_user_id: int = Depends(get_current_user)):
    """사용자별 일기 목록 조회"""
    try:
        collection = posts_collection
        
        print(f"DEBUG: get_posts - current_user_id: {current_user_id}")
        
        # 현재 사용자의 삭제되지 않은 일기만 조회
        query = {
            "user_id": current_user_id,
            "status": {"$ne": PostStatus.DELETED}
        }
        print(f"DEBUG: get_posts - query: {query}")
        cursor = collection.find(query).sort("created_at", -1)
        
        posts = []
        for doc in cursor:
            # 이미지 정보 변환
            images = []
            raw_images = doc.get("images", [])
            if isinstance(raw_images, list):
                for img_data in raw_images:
                    if isinstance(img_data, dict):
                        images.append(ImageInfo(
                            filename=img_data.get("filename", ""),
                            original_filename=img_data.get("original_filename", ""),
                            file_path=img_data.get("file_path", ""),
                            file_size=img_data.get("file_size", 0),
                            upload_date=img_data.get("upload_date", "")
                        ))
            # 리스트가 아니거나, 리스트 내 요소가 dict가 아니면 images는 빈 리스트로 둠
            posts.append(PostListResponse(
                id=doc["post_id"],
                content=doc["content"],
                status=doc["status"],
                emotion=doc.get("emotion", "neutral"),  # 감정 정보 추가
                emoji=doc.get("emoji", "⭐"),  # 이모지 URL 추가
                created_at=doc["created_at"],
                images=images
            ))
        
        return posts
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"일기 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )

async def get_post_detail(post_id: str, current_user_id: int = Depends(get_current_user)):
    """일기 상세 조회 (본인의 일기만 조회 가능)"""
    try:
        collection = posts_collection
        
        # 본인의 일기만 조회
        post_doc = collection.find_one({
            "post_id": post_id,
            "user_id": current_user_id
        })
        if not post_doc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="해당 일기를 찾을 수 없습니다"
            )
        
        # 삭제된 일기는 조회 불가
        if post_doc["status"] == PostStatus.DELETED:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="해당 일기를 찾을 수 없습니다"
            )
        
        # 이미지 정보 변환
        images = []
        for img_data in post_doc.get("images", []):
            images.append(ImageInfo(
                filename=img_data["filename"],
                original_filename=img_data["original_filename"],
                file_path=img_data["file_path"],
                file_size=img_data["file_size"],
                upload_date=img_data["upload_date"]
            ))
        
        return PostDetailResponse(
            id=post_doc["post_id"],
            content=post_doc["content"],
            status=post_doc["status"],
            created_at=post_doc["created_at"],
            images=images
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"일기 조회 중 오류가 발생했습니다: {str(e)}"
        )

async def update_post(post_id: str, post_data: PostUpdate, current_user_id: int = Depends(get_current_user)):
    """일기 수정 (본인의 일기만 수정 가능)"""
    try:
        collection = posts_collection
        
        # 본인의 일기 존재 여부 확인
        existing_post = collection.find_one({
            "post_id": post_id,
            "user_id": current_user_id
        })
        if not existing_post:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="해당 일기를 찾을 수 없습니다"
            )
        
        # 삭제된 일기는 수정 불가
        if existing_post["status"] == PostStatus.DELETED:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="해당 일기를 찾을 수 없습니다"
            )
        
        # 변경된 필드만 업데이트
        update_data = post_data.dict(exclude_unset=True)
        
        # 감정이 변경된 경우 사용자 선택 카테고리의 이모지로 업데이트
        if "emotion" in update_data:
            user_category = get_user_emoticon_category(current_user_id)
            emoji_url = get_emotion_emoji_url(update_data["emotion"], user_category)
            update_data["emoji"] = emoji_url
            print(f"DEBUG: 감정 변경 - 카테고리: {user_category}, 감정: {update_data['emotion']}, 이모지: {emoji_url}")
        
        # 이미지 필드가 있으면 ImageInfo 객체로 변환
        if "images" in update_data and update_data["images"] is not None:
            images_info = []
            current_time = datetime.now()
            for filename in update_data["images"]:
                # 기존 이미지 정보가 있는지 확인
                existing_image = None
                if "images" in existing_post:
                    for img in existing_post["images"]:
                        # img가 문자열인 경우와 딕셔너리인 경우 모두 처리
                        if isinstance(img, str) and img == filename:
                            existing_image = {"filename": filename, "original_filename": filename, "file_path": os.path.join("uploads/images", filename), "file_size": 0, "upload_date": current_time}
                            break
                        elif isinstance(img, dict) and img.get("filename") == filename:
                            existing_image = img
                            break
                
                if existing_image:
                    # 기존 이미지 정보 재사용
                    images_info.append(existing_image)
                else:
                    # 새 이미지 정보 생성
                    file_info = image_utils.get_file_info(filename)
                    images_info.append({
                        "filename": filename,
                        "original_filename": filename,
                        "file_path": os.path.join("uploads/images", filename),
                        "file_size": file_info["file_size"] if file_info else 0,
                        "upload_date": current_time
                    })
            
            update_data["images"] = images_info
        
        result = collection.update_one(
            {"post_id": post_id, "user_id": current_user_id},
            {"$set": update_data}
        )
        
        if result.modified_count == 0:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="일기 수정에 실패했습니다"
            )
        
        return PostUpdateResponse(
            message="일기가 성공적으로 수정되었습니다",
            post_id=post_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"일기 수정 중 오류가 발생했습니다: {str(e)}"
        )

async def delete_post(post_id: str, current_user_id: int = Depends(get_current_user)):
    """일기 삭제 (본인의 일기만 삭제 가능)"""
    try:
        collection = posts_collection
        
        # 본인의 일기 존재 여부 확인
        existing_post = collection.find_one({
            "post_id": post_id,
            "user_id": current_user_id
        })
        if not existing_post:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="해당 일기를 찾을 수 없습니다"
            )
        
        # 이미 삭제된 일기인지 확인
        if existing_post["status"] == PostStatus.DELETED:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="해당 일기를 찾을 수 없습니다"
            )
        
        # 소프트 삭제 (상태만 변경)
        result = collection.update_one(
            {"post_id": post_id, "user_id": current_user_id},
            {"$set": {
                "status": PostStatus.DELETED
            }}
        )
        
        if result.modified_count == 0:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="일기 삭제에 실패했습니다"
            )
        
        return PostDeleteResponse(
            message="일기가 성공적으로 삭제되었습니다",
            post_id=post_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"일기 삭제 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/date/{date}", response_model=List[PostListResponse])
async def get_posts_by_date(date: str, current_user_id: int = Depends(get_current_user)):
    """특정 날짜의 사용자별 일기 목록 조회"""
    try:
        collection = posts_collection
        
        # 날짜 형식 검증 (YYYY-MM-DD)
        try:
            datetime.strptime(date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="잘못된 날짜 형식입니다. YYYY-MM-DD 형식이어야 합니다."
            )
        
        query = {
            "user_id": current_user_id,
            "created_at": {
                "$gte": datetime.strptime(f"{date} 00:00:00", "%Y-%m-%d %H:%M:%S"),
                "$lt": datetime.strptime(f"{date} 23:59:59", "%Y-%m-%d %H:%M:%S")
            },
            "status": {"$ne": PostStatus.DELETED}
        }
        
        cursor = collection.find(query).sort("created_at", -1)
        
        posts = []
        for doc in cursor:
            # 이미지 정보 변환
            images = []
            raw_images = doc.get("images", [])
            if isinstance(raw_images, list):
                for img_data in raw_images:
                    if isinstance(img_data, dict):
                        images.append(ImageInfo(
                            filename=img_data.get("filename", ""),
                            original_filename=img_data.get("original_filename", ""),
                            file_path=img_data.get("file_path", ""),
                            file_size=img_data.get("file_size", 0),
                            upload_date=img_data.get("upload_date", "")
                        ))
            # 리스트가 아니거나, 리스트 내 요소가 dict가 아니면 images는 빈 리스트로 둠
            posts.append(PostListResponse(
                id=doc["post_id"],
                content=doc["content"],
                status=doc["status"],
                emotion=doc.get("emotion", "neutral"),  # 감정 정보 추가
                emoji=doc.get("emoji", "⭐"),  # 이모지 URL 추가
                created_at=doc["created_at"],
                images=images
            ))
        
        return posts
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"일기 목록 조회 중 오류가 발생했습니다: {str(e)}"
        )

@router.put("/{post_id}", response_model=PostUpdateResponse)
async def update_post_route(post_id: str, post_data: PostUpdate, current_user_id: int = Depends(get_current_user)):
    """일기 수정"""
    return await update_post(post_id, post_data, current_user_id)

@router.post("/upload-image", response_model=ImageUploadResponse)
async def upload_image(file: UploadFile = File(...)):
    """이미지 업로드"""
    try:
        # 파일 검증 (더 유연하게)
        allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
        file_extension = ''
        
        if file.filename:
            file_extension = os.path.splitext(file.filename.lower())[1]
        
        # content_type이 없거나 이미지가 아닌 경우 파일 확장자로 검증
        if (not file.content_type or not file.content_type.startswith('image/')) and file_extension not in allowed_extensions:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미지 파일만 업로드할 수 있습니다 (jpg, jpeg, png, gif, bmp, webp)"
            )
        
        # 파일 크기 검증 (10MB 제한)
        if file.size and file.size > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="파일 크기는 10MB를 초과할 수 없습니다"
            )
        
        # 임시 파일로 저장
        temp_filename, file_size = await image_utils.save_temp_image(file)
        
        return ImageUploadResponse(
            message="이미지가 성공적으로 업로드되었습니다",
            filename=temp_filename,
            file_size=file_size
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"이미지 업로드 중 오류가 발생했습니다: {str(e)}"
        )

@router.delete("/delete-image/{filename}", response_model=ImageDeleteResponse)
async def delete_image(filename: str):
    """이미지 삭제 (임시 또는 영구 파일)"""
    try:
        # 임시 파일 삭제 시도
        temp_deleted = image_utils.delete_temp_file(filename)
        
        # 영구 파일 삭제 시도
        permanent_deleted = image_utils.delete_permanent_file(filename)
        
        if temp_deleted or permanent_deleted:
            return ImageDeleteResponse(
                message="이미지가 성공적으로 삭제되었습니다",
                filename=filename
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="이미지 파일을 찾을 수 없습니다"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"이미지 삭제 중 오류가 발생했습니다: {str(e)}"
        )

@router.get("/image/{filename:path}")
async def get_image(filename: str):
    """이미지 파일 조회 (임시 또는 영구)"""
    try:
        import os
        
        # 현재 스크립트 위치 기준으로 절대 경로 생성
        current_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        
        # 디버깅을 위한 로그
        print(f"이미지 조회 요청: {filename}")
        print(f"현재 디렉토리: {current_dir}")
        
        # 임시 파일 경로 확인
        temp_path = os.path.join(current_dir, "uploads/temp", filename)
        print(f"임시 파일 경로: {temp_path}")
        print(f"임시 파일 존재: {os.path.exists(temp_path)}")
        
        if os.path.exists(temp_path):
            from fastapi.responses import FileResponse
            return FileResponse(temp_path)
        
        # 영구 파일 경로 확인
        permanent_path = os.path.join(current_dir, "uploads/images", filename)
        print(f"영구 파일 경로: {permanent_path}")
        print(f"영구 파일 존재: {os.path.exists(permanent_path)}")
        
        if os.path.exists(permanent_path):
            from fastapi.responses import FileResponse
            return FileResponse(permanent_path)
        
        # 파일이 없으면 404
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="이미지 파일을 찾을 수 없습니다"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"이미지 조회 중 오류가 발생했습니다: {str(e)}"
        )
