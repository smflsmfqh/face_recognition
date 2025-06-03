# 👤 Flutter Face Recognition App (TFLite + FaceNet512)

> Flutter 기반 iOS/Android 얼굴 인식 앱 – TFLite로 변환한 FaceNet512 모델과 Google ML Kit을 사용해 실시간 얼굴 인식 및 사용자 식별 기능 제공

---

## 📸 주요 기능

- 실시간 얼굴 감지 및 등록 (3장 연속 캡처)
- 사용자 이름/이메일 입력 및 등록 데이터 저장
- FaceNet512 임베딩 모델 기반 유사도 계산
- cosine similarity 기반 사용자 매칭
- 중복 사용자 탐지 및 등록 차단
- `user_db.json`로 사용자 정보 관리
- iOS/Android 크로스 플랫폼 대응
- 등록 시 임시 이미지/임베딩 자동 정리

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
'''
lib/
├── face/
│ ├── register_screen.dart # 얼굴 등록 (3장 촬영)
│ ├── register_info_screen.dart # 사용자 이름/이메일 입력
│ ├── register_info_preview_screen.dart # 등록 성공 시 미리보기
│ ├── recognition_screen.dart # 얼굴 인식 및 유저 식별
│ └── user_info_screen.dart # 식별된 사용자 정보 표시
├── services/
│ ├── camera_service.dart
│ ├── facenet_service.dart
│ ├── preprocessing_service.dart
│ ├── similarity_service.dart
│ └── embedding_cache_service.dart
├── home_screen.dart
└── main.dart
'''

## 🚀 시작하기

### 1. 클론 및 설치

```bash
git clone https://github.com/your-username/flutter-face-recognition.git
cd flutter-face-recognition
flutter pub get

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

📌 flutter pub get 명령어를 실행해 반영해주세요.
