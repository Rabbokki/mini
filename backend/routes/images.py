from fastapi import APIRouter, HTTPException, status
from fastapi.responses import FileResponse
import os

router = APIRouter(tags=["images"])

@router.get("/{filename:path}")
async def get_image(filename: str):
    """이미지 파일 조회 (임시 또는 영구)"""
    try:
        # 현재 스크립트 위치 기준으로 절대 경로 생성
        current_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        
        # 디버깅을 위한 로그
        print(f"이미지 조회 요청: {filename}")
        print(f"현재 디렉토리: {current_dir}")
        
        # 임시 파일 경로 확인
        temp_path = os.path.join(current_dir, "uploads/temp", filename)
        print(f"임시 파일 경로: {temp_path}")
        print(f"임시 파일 존재: {os.path.exists(temp_path)}")
        
        if os.path.exists(temp_path):
            return FileResponse(temp_path)
        
        # 영구 파일 경로 확인
        permanent_path = os.path.join(current_dir, "uploads/images", filename)
        print(f"영구 파일 경로: {permanent_path}")
        print(f"영구 파일 존재: {os.path.exists(permanent_path)}")
        
        if os.path.exists(permanent_path):
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