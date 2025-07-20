# AI 서비스 (STT)

OpenAI Whisper API를 사용한 음성-텍스트 변환(STT) 서비스입니다.

## 설정 방법

### 1. OpenAI API 키 발급

1. [OpenAI 웹사이트](https://platform.openai.com/)에 가입
2. API 키 발급: https://platform.openai.com/api-keys
3. API 키 복사

### 2. 환경변수 설정

```bash
# env.example을 .env로 복사
cp env.example .env

# .env 파일 편집
nano .env
```

`.env` 파일에 실제 API 키 입력:
```env
OPENAI_API_KEY=sk-your-actual-api-key-here
```

### 3. 의존성 설치

```bash
pip install -r requirements.txt
```

### 4. 서버 실행

```bash
python stt_service.py
```

서버가 `http://localhost:5000`에서 실행됩니다.

## API 엔드포인트

### 1. STT 변환 (전체 파일)
- **URL**: `POST /stt/transcribe`
- **용도**: 전체 오디오 파일을 텍스트로 변환
- **응답**: 완전한 텍스트와 세그먼트 정보

### 2. STT 변환 (청크)
- **URL**: `POST /stt/transcribe-chunk`
- **용도**: 실시간 변환을 위한 청크 처리
- **응답**: 빠른 응답을 위한 간단한 텍스트

### 3. 서비스 상태 확인
- **URL**: `GET /stt/health`
- **용도**: 서비스 상태 및 설정 정보 확인

### 4. 지원 언어 목록
- **URL**: `GET /stt/supported-languages`
- **용도**: 지원하는 언어 목록 확인

## 지원 파일 형식

- MP3
- WAV
- M4A
- OGG
- FLAC

최대 파일 크기: 25MB

## 보안 주의사항

⚠️ **중요**: 
- `.env` 파일은 절대 Git에 커밋하지 마세요
- API 키를 코드에 직접 입력하지 마세요
- 프로덕션 환경에서는 환경변수를 안전하게 관리하세요

## 비용 정보

OpenAI Whisper API 사용량에 따른 비용이 발생합니다:
- 입력 오디오: $0.006 / 분
- 자세한 가격: https://openai.com/pricing 