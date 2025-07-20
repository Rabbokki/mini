#!/bin/bash

echo "🔧 OpenAI API 키 설정 도구"
echo "=========================="

# .env 파일이 이미 존재하는지 확인
if [ -f ".env" ]; then
    echo "⚠️  .env 파일이 이미 존재합니다."
    read -p "덮어쓰시겠습니까? (y/N): " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo "설정을 취소했습니다."
        exit 0
    fi
fi

# OpenAI API 키 입력 받기
echo ""
echo "📝 OpenAI API 키를 입력해주세요:"
echo "   (https://platform.openai.com/api-keys 에서 발급 가능)"
read -p "API 키: " api_key

# API 키 유효성 검사 (sk-로 시작하는지)
if [[ ! $api_key =~ ^sk- ]]; then
    echo "❌ 잘못된 API 키 형식입니다. 'sk-'로 시작해야 합니다."
    exit 1
fi

# .env 파일 생성
cat > .env << EOF
# OpenAI API 설정
OPENAI_API_KEY=$api_key

# 서버 설정
FLASK_ENV=development
FLASK_DEBUG=True

# 로깅 설정
LOG_LEVEL=INFO
EOF

echo ""
echo "✅ .env 파일이 성공적으로 생성되었습니다!"
echo ""
echo "다음 단계:"
echo "1. pip install -r requirements.txt"
echo "2. python stt_service.py"
echo ""
echo "⚠️  주의: .env 파일은 절대 Git에 커밋하지 마세요!" 