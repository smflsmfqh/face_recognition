# 👤 Face Recognition App (TFLite + FaceNet512)

> Flutter 기반 iOS/Android 얼굴 인식 앱 – TFLite로 변환한 FaceNet512 모델과 Google ML Kit을 사용해 실시간 얼굴 인식 및 사용자 식별 기능 제공

---

## 📸 주요 기능

- 📷 **얼굴 자동 캡처 및 등록** (3장 연속 촬영 후 사용자 정보 입력)
- 🧠 **FaceNet512 임베딩 추출 및 비교**
- 🧾 **사용자 정보 및 임베딩 로컬 저장 (`user_db.json`)**
- ✅ **실시간 얼굴 인식 및 사용자 매칭**
- 🔐 **Liveness Detection** (눈 깜빡임, 고개 회전 감지 → 실제 얼굴 여부 판단)

---

## 🧱 사용 기술

| 구성 요소                  | 설명                                |
|--------------------------|-------------------------------------|
| Flutter                  | UI 및 앱 프레임워크                  |
| camera                   | 실시간 얼굴 이미지 캡처              |
| google_mlkit_face_detection | 얼굴 감지 (ML Kit)                 |
| tflite_flutter           | TFLite 모델 로딩 및 추론             |
| DeepFace (FaceNet512)    | 얼굴 임베딩 추출용 모델              |
| image                    | 얼굴 크롭 및 이미지 전처리           |

---

## 📁 프로젝트 구조

```plaintext
lib/
├── face/
│   ├── register_screen.dart              # 얼굴 등록 
│   ├── register_info_screen.dart         # 사용자 이름/이메일 입력
│   ├── register_info_preview_screen.dart # 등록 성공 시 미리보기
│   ├── recognition_screen.dart           # 얼굴 인식 및 유저 식별
│   └── user_info_screen.dart             # 식별된 사용자 정보 표시
├── services/
│   ├── camera_service.dart
│   ├── facenet_service.dart
│   ├── preprocessing_service.dart
│   ├── similarity_service.dart
│   └── embedding_cache_service.dart
├── home_screen.dart
└── main.dart
```

## 🚀 시작하기

### 1. 클론 및 설치

```bash
git clone https://github.com/your-username/flutter-face-recognition.git
cd flutter-face-recognition
flutter pub get
```

### 2. FaceNet512 모델 다운로드 및 등록

> 앱에서 사용하는 얼굴 임베딩 추출 모델은 DeepFace 기반 FaceNet512를 TensorFlow Lite로 변환한 `.tflite` 파일입니다.

#### 📥 모델 다운로드

- [facenet512.tflite 모델 다운로드 링크](https://github.com/your-model-url/raw/main/facenet512.tflite)  
  (예: Google Drive, GitHub Releases, 직접 변환 등)

#### 📁 파일 위치

다운로드한 모델 파일을 아래 디렉토리에 저장합니다:

assets/models/facenet512.tflite

#### ⚙️ pubspec.yaml 등록

`pubspec.yaml`에 아래 내용을 추가해 `assets` 경로를 앱에 등록합니다:

```yaml
flutter:
  assets:
    - assets/models/facenet512.tflite

```

📌 flutter pub get 명령어를 실행해 반영해주세요.

## 🧪 사용 흐름

1. 홈 화면 → [얼굴 등록] 또는 [얼굴 인식] 선택
3. 등록 시 얼굴 촬영 + 사용자 이름/이메일 입력  
4. 얼굴 인식 시 실시간으로 촬영한 얼굴을 저장된 사용자들과 비교  
5. 가장 유사한 사용자의 정보 자동 표시  

---

## 🗃 user_db.json 구조 예시

```json
{
  "neri1": {
    "name": "Neri",
    "email": "neri@example.com",
    "images": ["neri1_0.jpg", "neri1_1.jpg", "neri1_2.jpg"],
    "embeddings": ["neri1_0.json", "neri1_1.json", "neri1_2.json"]
  }
}
```

## 🧼 임시 파일 자동 삭제

- 얼굴 등록 완료 후 다음 임시 파일들이 자동 삭제됩니다:
  - `tmp_*.jpg`
  - `tmp_*.json`
  - `user_*.json` (등록 전 테스트용으로 남은 경우)
- 앱 시작 시에도 남아 있는 임시 파일이 있으면 자동 정리됩니다.

---

## 🛣 향후 추가 예정

- [ ] **다각도 인식 대응**: 측면 얼굴 등록/비교 지원
- [ ] **Firebase 연동**: 사용자 데이터 클라우드 동기화
- [ ] **사용자 목록 화면**: 등록된 유저 정보 관리 UI

---

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.

- 코드: 자유롭게 수정 및 배포 가능
- 모델: [DeepFace](https://github.com/serengil/deepface)의 FaceNet512 기반 TensorFlow Lite 모델 사용
- 얼굴 데이터: 로컬에만 저장되며 외부 전송 없음


