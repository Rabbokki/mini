# 🎯 AI Mini Implementation Project (Latest)

Flutter 앱과 FastAPI 백엔드로 구성된 일기 애플리케이션입니다. 음성 인식(ASR) 기능을 포함한 최신 버전입니다.

## 📁 프로젝트 구조

```
mproj/
├── lib/                    # Flutter 앱 소스 코드
│   ├── components/         # UI 컴포넌트
│   ├── models/            # 데이터 모델
│   ├── pages/             # 페이지
│   ├── services/          # API 서비스
│   └── widgets/           # 재사용 가능한 위젯
├── backend/               # FastAPI 백엔드
│   ├── routes/            # API 라우트
│   │   ├── auth.py        # 인증 관련
│   │   ├── images.py      # 이미지 업로드
│   │   └── asr.py         # 음성 인식
│   ├── post/              # 포스트 관련 기능
│   │   ├── database/      # 데이터베이스 설정
│   │   ├── models/        # 데이터 모델
│   │   └── routes/        # 포스트 라우트
│   └── requirements.txt   # Python 의존성
├── assets/                # 이미지 등 정적 파일
└── start_project.py       # 전체 프로젝트 실행 스크립트
```

## 🚀 빠른 시작

### 1. 전체 프로젝트 실행 (권장)

```bash
python3 start_project.py
```

이 스크립트는 다음을 자동으로 수행합니다:
- 환경 설정 파일 생성
- 백엔드 의존성 설치
- Flutter 의존성 설치
- 백엔드 서버 시작 (포트 8000)
- Flutter 앱 시작 (Chrome)

### 2. 개별 실행

#### 백엔드만 실행
```bash
python3 start_backend.py
```

#### Flutter 앱만 실행
```bash
python3 start_flutter.py
```

## 📋 사전 요구사항

### 필수 설치 항목

1. **Python 3.8+**
   ```bash
   python3 --version
   ```

2. **Flutter SDK**
   ```bash
   flutter --version
   ```
   설치: https://flutter.dev/docs/get-started/install

3. **MongoDB** (로컬 또는 클라우드)
   - 로컬 설치: https://docs.mongodb.com/manual/installation/
   - 또는 MongoDB Atlas 사용

### 선택적 설치 항목

- **Android Studio** (Android 개발용)
- **Xcode** (iOS 개발용, macOS만)
- **VS Code** (권장 에디터)

## 🔧 설정

### 환경 변수

프로젝트 실행 시 자동으로 `backend/.env` 파일이 생성됩니다:

```env
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=mini_project
JWT_SECRET_KEY=your-secret-key-here-change-in-production
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
HOST=0.0.0.0
PORT=8000
```

### MongoDB 설정

1. MongoDB 서버가 실행 중인지 확인
2. `mini_project` 데이터베이스가 자동으로 생성됩니다

## 📱 앱 기능

### 주요 기능
- 📝 일기 작성 및 관리
- 🎨 감정 표현 (이모티콘)
- 📅 캘린더 뷰
- 👤 사용자 인증
- ⚙️ 사용자 설정
- 🎤 **음성 인식 (ASR)** - 음성을 텍스트로 변환
- 🎵 **음성 녹음** - 일기에 음성 추가
- 📸 **이미지 업로드** - 일기에 사진 추가

### 기술 스택
- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **Database**: MongoDB
- **Authentication**: JWT
- **File Upload**: 이미지 업로드 지원
- **Audio Processing**: 음성 녹음 및 인식

## 🔗 API 엔드포인트

백엔드 서버 실행 후 다음 URL에서 API 문서를 확인할 수 있습니다:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

### 주요 API
- `POST /api/auth/register` - 회원가입
- `POST /api/auth/login` - 로그인
- `GET /api/posts` - 일기 목록 조회
- `POST /api/posts` - 일기 작성
- `POST /api/asr/` - **음성-텍스트 변환**
- `GET /api/asr/supported-languages` - 지원 언어 목록
- `POST /api/images/upload` - 이미지 업로드

## 🎤 ASR (음성 인식) 기능

### 지원 언어
- 한국어 (ko)
- 영어 (en)
- 일본어 (ja)
- 중국어 (zh)
- 스페인어 (es)
- 프랑스어 (fr)
- 독일어 (de)
- 이탈리아어 (it)
- 포르투갈어 (pt)
- 러시아어 (ru)

### 사용 방법
1. 일기 작성 화면에서 음성 녹음 버튼 클릭
2. 음성 녹음 후 텍스트로 변환
3. 변환된 텍스트를 일기에 추가

## 🛠️ 개발

### Flutter 앱 개발
```bash
cd mproj
flutter pub get
flutter run -d chrome
```

### 백엔드 개발
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### 데이터베이스 관리
MongoDB Compass 또는 mongo shell을 사용하여 데이터베이스를 관리할 수 있습니다.

## 🐛 문제 해결

### 일반적인 문제

1. **Flutter 의존성 오류**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Python 의존성 오류**
   ```bash
   pip3 install --upgrade pip
   pip3 install -r backend/requirements.txt
   ```

3. **MongoDB 연결 오류**
   - MongoDB 서버가 실행 중인지 확인
   - `.env` 파일의 `MONGODB_URL` 설정 확인

4. **포트 충돌**
   - 백엔드: 기본 포트 8000
   - Flutter: 기본 포트 8080 (웹)

5. **음성 인식 오류**
   - STT 서비스가 실행 중인지 확인
   - 오디오 파일 형식 확인 (m4a, wav, mp3 등)

## 📄 라이선스

이 프로젝트는 교육 목적으로 제작되었습니다.

## 🤝 기여

버그 리포트나 기능 제안은 이슈를 통해 해주세요.
