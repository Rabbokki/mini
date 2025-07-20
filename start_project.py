#!/usr/bin/env python3
"""
전체 프로젝트 실행 스크립트 (latest 브랜치용)
백엔드 서버와 Flutter 앱을 동시에 실행
"""

import os
import sys
import subprocess
import threading
import time
import signal
from pathlib import Path

class ProjectRunner:
    def __init__(self):
        self.backend_process = None
        self.flutter_process = None
        self.running = True
        
        # 시그널 핸들러 설정
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
    
    def signal_handler(self, signum, frame):
        """시그널 핸들러 - 프로세스 정리"""
        print("\n🛑 프로젝트를 종료합니다...")
        self.running = False
        self.cleanup()
        sys.exit(0)
    
    def create_env_file(self):
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
    
    def install_backend_dependencies(self):
        """백엔드 의존성 설치"""
        print("📦 백엔드 의존성을 설치합니다...")
        try:
            subprocess.run([sys.executable, "-m", "pip", "install", "-r", "backend/requirements.txt"], 
                          check=True, cwd=".", capture_output=True)
            print("✅ 백엔드 의존성 설치 완료")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ 백엔드 의존성 설치 실패: {e}")
            return False
    
    def install_flutter_dependencies(self):
        """Flutter 의존성 설치"""
        print("📦 Flutter 의존성을 설치합니다...")
        try:
            subprocess.run(["flutter", "pub", "get"], check=True, cwd=".", capture_output=True)
            print("✅ Flutter 의존성 설치 완료")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Flutter 의존성 설치 실패: {e}")
            return False
    
    def start_backend(self):
        """백엔드 서버 시작"""
        print("🚀 백엔드 서버를 시작합니다...")
        try:
            self.backend_process = subprocess.Popen(
                [sys.executable, "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"],
                cwd="backend",
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True
            )
            
            # 서버 시작 대기
            time.sleep(5)
            if self.backend_process.poll() is None:
                print("✅ 백엔드 서버가 시작되었습니다. (http://localhost:8000)")
                return True
            else:
                print("❌ 백엔드 서버 시작 실패")
                return False
        except Exception as e:
            print(f"❌ 백엔드 서버 시작 오류: {e}")
            return False
    
    def start_flutter(self):
        """Flutter 앱 시작"""
        print("🚀 Flutter 앱을 시작합니다...")
        try:
            self.flutter_process = subprocess.Popen(
                ["flutter", "run", "-d", "chrome"],
                cwd=".",
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True
            )
            print("✅ Flutter 앱이 시작되었습니다.")
            return True
        except Exception as e:
            print(f"❌ Flutter 앱 시작 오류: {e}")
            return False
    
    def monitor_processes(self):
        """프로세스 모니터링"""
        while self.running:
            # 백엔드 프로세스 상태 확인
            if self.backend_process and self.backend_process.poll() is not None:
                print("⚠️  백엔드 서버가 종료되었습니다.")
                break
            
            # Flutter 프로세스 상태 확인
            if self.flutter_process and self.flutter_process.poll() is not None:
                print("⚠️  Flutter 앱이 종료되었습니다.")
                break
            
            time.sleep(1)
    
    def cleanup(self):
        """프로세스 정리"""
        if self.backend_process:
            print("🛑 백엔드 서버를 종료합니다...")
            self.backend_process.terminate()
            try:
                self.backend_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.backend_process.kill()
        
        if self.flutter_process:
            print("🛑 Flutter 앱을 종료합니다...")
            self.flutter_process.terminate()
            try:
                self.flutter_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.flutter_process.kill()
    
    def run(self):
        """전체 프로젝트 실행"""
        print("🎯 전체 프로젝트 실행 (latest 브랜치)")
        print("=" * 50)
        
        # 환경 파일 생성
        self.create_env_file()
        
        # 의존성 설치
        if not self.install_backend_dependencies():
            print("❌ 백엔드 의존성 설치에 실패했습니다.")
            return
        
        if not self.install_flutter_dependencies():
            print("❌ Flutter 의존성 설치에 실패했습니다.")
            return
        
        # 백엔드 서버 시작
        if not self.start_backend():
            print("❌ 백엔드 서버 시작에 실패했습니다.")
            return
        
        # 잠시 대기 후 Flutter 앱 시작
        time.sleep(3)
        
        # Flutter 앱 시작
        if not self.start_flutter():
            print("❌ Flutter 앱 시작에 실패했습니다.")
            self.cleanup()
            return
        
        print("\n🎉 프로젝트가 성공적으로 시작되었습니다!")
        print("📱 Flutter 앱: Chrome에서 실행 중")
        print("🔧 백엔드 API: http://localhost:8000")
        print("📚 API 문서: http://localhost:8000/docs")
        print("🎤 ASR 기능: 음성-텍스트 변환 지원")
        print("\n프로젝트를 종료하려면 Ctrl+C를 누르세요.")
        
        # 프로세스 모니터링
        self.monitor_processes()

def main():
    runner = ProjectRunner()
    runner.run()

if __name__ == "__main__":
    main() 