#!/usr/bin/env python3
"""
Flutter 앱 실행 스크립트 (latest 브랜치용)
"""

import os
import sys
import subprocess
import platform

def check_flutter():
    """Flutter가 설치되어 있는지 확인"""
    try:
        result = subprocess.run(["flutter", "--version"], 
                              capture_output=True, text=True, check=True)
        print("✅ Flutter가 설치되어 있습니다.")
        print(result.stdout.split('\n')[0])  # 버전 정보 출력
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Flutter가 설치되어 있지 않습니다.")
        print("Flutter를 설치하려면: https://flutter.dev/docs/get-started/install")
        return False

def get_flutter_devices():
    """사용 가능한 Flutter 디바이스 목록 출력"""
    try:
        result = subprocess.run(["flutter", "devices"], 
                              capture_output=True, text=True, check=True)
        print("📱 사용 가능한 디바이스:")
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ 디바이스 목록 조회 실패: {e}")
        return False

def install_dependencies():
    """Flutter 의존성 설치"""
    print("📦 Flutter 의존성을 설치합니다...")
    try:
        subprocess.run(["flutter", "pub", "get"], check=True, cwd=".")
        print("✅ Flutter 의존성 설치 완료")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ 의존성 설치 실패: {e}")
        return False

def run_flutter_app(device_id=None):
    """Flutter 앱 실행"""
    print("🚀 Flutter 앱을 시작합니다...")
    
    cmd = ["flutter", "run"]
    if device_id:
        cmd.extend(["-d", device_id])
    else:
        # 기본적으로 Chrome에서 실행
        cmd.extend(["-d", "chrome"])
    
    try:
        subprocess.run(cmd, check=True, cwd=".")
    except KeyboardInterrupt:
        print("\n🛑 앱이 중지되었습니다.")
    except subprocess.CalledProcessError as e:
        print(f"❌ 앱 실행 실패: {e}")

def main():
    print("🎯 Flutter 앱 실행 (latest 브랜치)")
    print("=" * 30)
    
    # Flutter 설치 확인
    if not check_flutter():
        return
    
    # 의존성 설치
    if not install_dependencies():
        print("❌ 의존성 설치에 실패했습니다.")
        return
    
    # 디바이스 목록 출력
    get_flutter_devices()
    
    # 사용자에게 디바이스 선택 옵션 제공
    print("\n💡 실행할 디바이스를 선택하세요:")
    print("1. Chrome (웹) - 기본")
    print("2. 특정 디바이스 ID 입력")
    
    choice = input("선택 (1 또는 2): ").strip()
    
    device_id = None
    if choice == "2":
        device_id = input("디바이스 ID를 입력하세요: ").strip()
        if not device_id:
            print("❌ 유효하지 않은 디바이스 ID입니다.")
            return
    
    # 앱 실행
    run_flutter_app(device_id)

if __name__ == "__main__":
    main() 