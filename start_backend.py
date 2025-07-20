#!/usr/bin/env python3
"""
백엔드 서버 실행 스크립트 (latest 브랜치용)
"""

import os
import sys
import subprocess
from pathlib import Path

def create_env_file():
    """환경 설정 파일 생성 (latest 브랜치용)"""
    env_content = """# MongoDB 연결 설정
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=mini_project

# JWT 시크릿 키 (실제 운영환경에서는 더 복잡한 키를 사용해야 합니다)
JWT_SECRET_KEY=your-secret-key-here-change-in-production

# JWT 알고리즘
JWT_ALGORITHM=HS256

# JWT 토큰 만료 시간 (분)
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 서버 설정
HOST=0.0.0.0
PORT=8000

# OpenAI API 키 (필요한 경우)
OPENAI_API_KEY=your-openai-api-key-here

# 파일 업로드 설정
MAX_FILE_SIZE=10485760  # 10MB
UPLOAD_DIR=uploads
"""
    
    env_path = Path("backend/.env")
    if not env_path.exists():
        with open(env_path, "w", encoding="utf-8") as f:
            f.write(env_content)
        print("✅ .env 파일이 생성되었습니다.")
    else:
        print("ℹ️  .env 파일이 이미 존재합니다.")

def install_dependencies():
    """백엔드 의존성 설치"""
    print("📦 백엔드 의존성을 설치합니다...")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "backend/requirements.txt"], 
                      check=True, cwd=".")
        print("✅ 백엔드 의존성 설치 완료")
    except subprocess.CalledProcessError as e:
        print(f"❌ 의존성 설치 실패: {e}")
        return False
    return True

def start_server():
    """서버 시작"""
    print("🚀 백엔드 서버를 시작합니다...")
    try:
        subprocess.run([sys.executable, "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"], 
                      check=True, cwd="backend")
    except KeyboardInterrupt:
        print("\n🛑 서버가 중지되었습니다.")
    except subprocess.CalledProcessError as e:
        print(f"❌ 서버 시작 실패: {e}")

def main():
    print("🎯 백엔드 서버 설정 및 실행 (latest 브랜치)")
    print("=" * 40)
    
    # 환경 파일 생성
    create_env_file()
    
    # 의존성 설치
    if not install_dependencies():
        print("❌ 의존성 설치에 실패했습니다. 수동으로 설치해주세요.")
        return
    
    # 서버 시작
    start_server()

if __name__ == "__main__":
    main() 