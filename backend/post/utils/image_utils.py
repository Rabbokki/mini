"""
이미지 처리 유틸리티 모듈
"""
import os
import uuid
import shutil
from typing import List, Optional, Tuple
from fastapi import UploadFile, HTTPException
from datetime import datetime
import aiofiles

# 설정
UPLOAD_DIR = "uploads"
IMAGES_DIR = os.path.join(UPLOAD_DIR, "images")
TEMP_DIR = os.path.join(UPLOAD_DIR, "temp")
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB
MAX_IMAGES_PER_POST = 3
ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}

def ensure_directories():
    """업로드 디렉토리 확인 및 생성"""
    for directory in [UPLOAD_DIR, IMAGES_DIR, TEMP_DIR]:
        os.makedirs(directory, exist_ok=True)

def is_allowed_file(filename: str) -> bool:
    """허용된 파일 확장자인지 확인"""
    if not filename:
        return False
    extension = os.path.splitext(filename.lower())[1]
    return extension in ALLOWED_EXTENSIONS

def generate_unique_filename(original_filename: str) -> str:
    """고유한 파일명 생성"""
    if not original_filename:
        raise ValueError("파일명이 제공되지 않았습니다")
    
    # 확장자 추출
    _, extension = os.path.splitext(original_filename.lower())
    
    # UUID로 고유한 파일명 생성
    unique_id = str(uuid.uuid4())
    return f"{unique_id}{extension}"

def validate_image_file(file: UploadFile) -> None:
    """이미지 파일 유효성 검사"""
    # 파일명 확인
    if not file.filename:
        raise HTTPException(status_code=400, detail="파일명이 없습니다")
    
    # 확장자 확인
    if not is_allowed_file(file.filename):
        raise HTTPException(
            status_code=400, 
            detail=f"지원하지 않는 파일 형식입니다. 지원 형식: {', '.join(ALLOWED_EXTENSIONS)}"
        )

async def save_temp_image(file: UploadFile) -> Tuple[str, int]:
    """임시 이미지 파일 저장"""
    # 디렉토리 확인
    ensure_directories()
    
    # 파일 유효성 검사
    validate_image_file(file)
    
    # 고유한 파일명 생성
    if not file.filename:
        raise HTTPException(status_code=400, detail="파일명이 없습니다")
    unique_filename = generate_unique_filename(file.filename)
    temp_path = os.path.join(TEMP_DIR, unique_filename)
    
    # 파일 크기 체크 및 저장
    file_size = 0
    try:
        async with aiofiles.open(temp_path, 'wb') as f:
            while chunk := await file.read(8192):  # 8KB씩 읽기
                file_size += len(chunk)
                
                # 파일 크기 제한 확인
                if file_size > MAX_FILE_SIZE:
                    # 임시 파일 삭제
                    if os.path.exists(temp_path):
                        os.remove(temp_path)
                    raise HTTPException(
                        status_code=413, 
                        detail=f"파일 크기가 너무 큽니다. 최대 {MAX_FILE_SIZE // (1024*1024)}MB까지 업로드 가능합니다"
                    )
                
                await f.write(chunk)
    
    except Exception as e:
        # 오류 발생 시 임시 파일 삭제
        if os.path.exists(temp_path):
            os.remove(temp_path)
        
        if isinstance(e, HTTPException):
            raise e
        else:
            raise HTTPException(status_code=500, detail=f"파일 저장 중 오류가 발생했습니다: {str(e)}")
    
    return unique_filename, file_size

def move_temp_to_permanent(temp_filename: str) -> str:
    """임시 파일을 영구 저장소로 이동"""
    temp_path = os.path.join(TEMP_DIR, temp_filename)
    permanent_path = os.path.join(IMAGES_DIR, temp_filename)
    
    if not os.path.exists(temp_path):
        raise HTTPException(status_code=404, detail="임시 파일을 찾을 수 없습니다")
    
    try:
        shutil.move(temp_path, permanent_path)
        return permanent_path
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"파일 이동 중 오류: {str(e)}")

def delete_temp_file(filename: str) -> bool:
    """임시 파일 삭제"""
    temp_path = os.path.join(TEMP_DIR, filename)
    try:
        if os.path.exists(temp_path):
            os.remove(temp_path)
            return True
        return False
    except Exception:
        return False

def delete_permanent_file(filename: str) -> bool:
    """영구 파일 삭제"""
    permanent_path = os.path.join(IMAGES_DIR, filename)
    try:
        if os.path.exists(permanent_path):
            os.remove(permanent_path)
            return True
        return False
    except Exception:
        return False

def get_image_info(filename: str, file_size: int, original_filename: str) -> dict:
    """이미지 정보 딕셔너리 생성"""
    return {
        "filename": filename,
        "original_filename": original_filename,
        "file_path": os.path.join(IMAGES_DIR, filename),
        "file_size": file_size,
        "upload_date": datetime.utcnow()
    }

def cleanup_orphaned_temp_files(max_age_hours: int = 24):
    """오래된 임시 파일들 정리"""
    ensure_directories()
    
    current_time = datetime.now()
    cleaned_count = 0
    
    try:
        for filename in os.listdir(TEMP_DIR):
            file_path = os.path.join(TEMP_DIR, filename)
            
            # 파일 생성 시간 확인
            file_time = datetime.fromtimestamp(os.path.getctime(file_path))
            age_hours = (current_time - file_time).total_seconds() / 3600
            
            # 지정된 시간보다 오래된 파일 삭제
            if age_hours > max_age_hours:
                os.remove(file_path)
                cleaned_count += 1
                
    except Exception as e:
        print(f"임시 파일 정리 중 오류: {str(e)}")
    
    return cleaned_count

def validate_images_list(images: List[str]) -> List[str]:
    """이미지 목록 유효성 검사"""
    if len(images) > MAX_IMAGES_PER_POST:
        raise HTTPException(
            status_code=400, 
            detail=f"이미지는 최대 {MAX_IMAGES_PER_POST}개까지만 업로드할 수 있습니다"
        )
    
    # 실제 존재하는 파일만 필터링
    valid_images = []
    for filename in images:
        temp_path = os.path.join(TEMP_DIR, filename)
        if os.path.exists(temp_path):
            valid_images.append(filename)
    
    return valid_images

def get_file_size(file_path: str) -> int:
    """파일 크기 반환"""
    try:
        return os.path.getsize(file_path)
    except OSError:
        return 0

class ImageUtils:
    """이미지 처리 유틸리티 클래스"""
    
    def __init__(self):
        pass
    
    async def save_temp_image(self, file: UploadFile) -> str:
        """임시 이미지 파일 저장"""
        # 디렉토리 확인
        ensure_directories()
        
        # 파일 유효성 검사
        validate_image_file(file)
        
        # 고유한 파일명 생성
        if not file.filename:
            raise HTTPException(status_code=400, detail="파일명이 없습니다")
        unique_filename = generate_unique_filename(file.filename)
        temp_path = os.path.join(TEMP_DIR, unique_filename)
        
        # 파일 크기 체크 및 저장
        file_size = 0
        try:
            async with aiofiles.open(temp_path, 'wb') as f:
                while chunk := await file.read(8192):  # 8KB씩 읽기
                    file_size += len(chunk)
                    
                    # 파일 크기 제한 확인
                    if file_size > MAX_FILE_SIZE:
                        # 임시 파일 삭제
                        if os.path.exists(temp_path):
                            os.remove(temp_path)
                        raise HTTPException(
                            status_code=413, 
                            detail=f"파일 크기가 너무 큽니다. 최대 {MAX_FILE_SIZE // (1024*1024)}MB까지 업로드 가능합니다"
                        )
                    
                    await f.write(chunk)
        
        except Exception as e:
            # 오류 발생 시 임시 파일 삭제
            if os.path.exists(temp_path):
                os.remove(temp_path)
            
            if isinstance(e, HTTPException):
                raise e
            else:
                raise HTTPException(status_code=500, detail=f"파일 저장 중 오류가 발생했습니다: {str(e)}")
        
        return unique_filename
    
    def move_temp_to_permanent(self, temp_filename: str, post_id: str = None) -> str:
        """임시 파일을 영구 저장소로 이동"""
        temp_path = os.path.join(TEMP_DIR, temp_filename)
        permanent_path = os.path.join(IMAGES_DIR, temp_filename)
        
        if not os.path.exists(temp_path):
            raise HTTPException(status_code=404, detail="임시 파일을 찾을 수 없습니다")
        
        try:
            shutil.move(temp_path, permanent_path)
            return temp_filename  # 파일명만 반환
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"파일 이동 중 오류: {str(e)}")
    
    def delete_temp_file(self, filename: str) -> bool:
        """임시 파일 삭제"""
        return delete_temp_file(filename)
    
    def delete_permanent_file(self, filename: str) -> bool:
        """영구 파일 삭제"""
        return delete_permanent_file(filename)
    
    def get_file_info(self, filename: str) -> dict:
        """파일 정보 반환"""
        file_path = os.path.join(IMAGES_DIR, filename)
        return {
            "file_size": get_file_size(file_path),
            "exists": os.path.exists(file_path)
        }

# 전역 인스턴스
image_utils = ImageUtils() 