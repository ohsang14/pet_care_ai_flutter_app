# 🐾 PetCare AI (반려견 품종 분석 및 건강 관리 플랫폼)

<img width="512" height="512" alt="Gemini_Generated_Image_ewaxy2ewaxy2ewax" src="https://github.com/user-attachments/assets/d0c7aa98-5236-4a0e-abd8-e8939bd0108d" />

> **"사진 한 장으로 시작하는 우리 강아지 맞춤 주치의"**
> 
> 딥러닝(MobileNetV2)을 활용한 실시간 견종 분석과 생애 주기별 건강 관리를 제공하는 **Full-Stack 모바일 플랫폼**입니다.
> 기획부터 디자인, AI 모델 서빙, 백엔드 구축, AWS 인프라 배포까지 **1인 개발**로 수행했습니다.

<br>

## 📅 프로젝트 기간 및 인원
* **기간:** 2025.09 ~ 2025.12 (약 12주)
* **인원:** 1인 개발 (Full-Stack)

<br>

## 🛠 Tech Stack


| 분류 | 기술 스택 |
| :--- | :--- |
| **Frontend** | ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white) **Dart** |
| **Backend** | ![Spring Boot](https://img.shields.io/badge/SpringBoot-6DB33F?style=flat&logo=springboot&logoColor=white) **Java 21**, JPA, Gradle |
| **AI Server** | ![Flask](https://img.shields.io/badge/Flask-000000?style=flat&logo=flask&logoColor=white) **Python 3.12**, TensorFlow, Keras |
| **Database** | ![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=flat&logo=mysql&logoColor=white) |
| **Infra** | ![AWS](https://img.shields.io/badge/AWS%20EC2-232F3E?style=flat&logo=amazon-aws&logoColor=white) Ubuntu 24.04 LTS |

<br>

## 📱 Service Demo (시연 화면)

| 메인 및 로그인 | AI 품종 분석 (핵심) | 건강 관리 차트 |
| :---: | :---: | :---: |
| ![로그인 ](https://github.com/user-attachments/assets/02ecb81e-4c59-432a-b2d9-8a601c6a92cd)
 | ![Analysis](여기에_아까_복사한_GIF_링크_붙여넣기) | <video src="[차트_영상_주소]" controls width="100%"></video> |
| 카카오 로그인 및<br>메인 화면 진입 | 사진 촬영 후<br>MobileNetV2 분석 결과 | 문진표 데이터 기반<br>건강 추이 그래프 |


## 🏗 System Architecture
**단일 EC2 인스턴스 내 이종 서버(Spring + Flask) 통합 아키텍처**

<img width="1934" height="910" alt="image" src="https://github.com/user-attachments/assets/96513b9c-cb66-4ba3-871b-d553a05239cc" />
* **Efficient Resource Management:** 비용 절감을 위해 AWS t2.micro 프리티어 환경 내에서 Spring Boot(8080)와 Flask(5000)를 동시에 구동.
* **Direct Image Transfer:** 이미지 전송 시 Spring을 거치지 않고 **App ➡️ Flask**로 직접 전송하여 대역폭 낭비 최소화.

<br>

## ✨ Key Features
* **📸 AI 견종 분석:** 카메라 촬영 시 MobileNetV2 경량 모델이 0.5초 이내에 품종 분석 결과 제공.
* **📊 건강 모니터링:** 문진표 데이터를 시각화(Line Chart)하여 건강 변화 추이를 그래프로 제공.
* **🔐 보안 로그인:** Kakao OAuth2 및 Secure Storage 적용으로 안전한 자동 로그인 구현.
* **🧹 데이터 무결성:** 회원 탈퇴 시 연관 데이터(반려견, 기록) Cascade(연쇄) 삭제 처리.

<br>

## 🚀 Troubleshooting & Performance (핵심 성과)

### 1. AWS EC2 프리티어 메모리 부족(OOM) 해결
* **문제(Problem):** t2.micro(RAM 1GB)에서 Java(Spring)와 Python(Flask) 동시 실행 시 메모리 부족으로 서버가 멈추는(Freezing) 현상 발생.
* **해결(Action):**
    1. **OS 레벨:** 리눅스 **Swap Memory 2GB**를 할당하여 가상 메모리 공간 확보.
    2. **App 레벨:** Spring Boot 실행 시 **JVM Heap Size를 400MB로 제한**(`-Xmx400m`)하여 메모리 점유율 통제.
* **결과(Result):** 추가 비용 없이 두 개의 서버 프로세스를 24시간 안정적으로 가동 성공.
<img width="300" height="320" alt="image" src="https://github.com/user-attachments/assets/2bb24b72-3a19-4c54-be81-b2fd86da30ec" />


### 2. 고해상도 이미지 전송 속도 90% 개선
* **문제(Problem):** 스마트폰 고화질 사진(약 5MB) 전송 시 업로드 지연 발생.
* **해결(Action):** 클라이언트(Flutter) 단에서 `image_picker`의 `imageQuality: 70` 옵션을 적용하여 전송 전 압축 수행.
* **결과(Result):** 이미지 용량을 평균 **300KB(94% 감소)**로 줄이면서도 AI 분석 정확도는 유지, 전송 속도 2배 이상 향상.

<br>

## 💭 Retrospective (회고)
* **이종 언어 통합 경험:** Java의 안정성과 Python의 AI 라이브러리 강점을 결합하기 위해 API 통신 규격을 설계하며 **마이크로 서비스 구조**에 대한 이해도를 높였습니다.
* **인프라 최적화:** 제한된 클라우드 자원 안에서 서비스를 운영하기 위해 OS(Linux)와 JVM 메모리 구조를 깊이 있게 학습하는 계기가 되었습니다.
* **향후 계획:** 현재 로컬 스토리지에 저장되는 이미지 캐싱 전략을 개선하여 리스트 로딩 속도를 더욱 높일 예정입니다.

<br>

## 📞 Contact
* **Email:** ohsanghyun14@gmail.com
* **GitHub:** https://github.com/ohsang14
