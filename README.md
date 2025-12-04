# 🐾 PetCare AI (반려견 품종 분석 및 건강 관리 플랫폼)

<img width="256" height="256" alt="Gemini_Generated_Image_ewaxy2ewaxy2ewax" src="https://github.com/user-attachments/assets/d0c7aa98-5236-4a0e-abd8-e8939bd0108d" />

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
| <img src="https://github.com/user-attachments/assets/3f000d8e-01c4-48cc-abf3-845c495c1f90" height="500"/> | <img src="https://github.com/user-attachments/assets/0acd50e9-baf0-40c5-afcc-cdfceed839f1" height="500"/> | <img src="https://github.com/user-attachments/assets/81ea3aaf-2966-4752-9f94-09c662c3c6b9" height="500"/> |
| 카카오 로그인 및<br>메인 화면 진입 | 사진 촬영 후<br>MobileNetV2 분석 결과 | 문진표 데이터 기반<br>건강 추이 그래프 |


## 🏗 System Architecture
**단일 EC2 인스턴스 내 이종 서버(Spring + Flask) 통합 아키텍처**

<img width="1934" height="910" alt="image" src="https://github.com/user-attachments/assets/96513b9c-cb66-4ba3-871b-d553a05239cc" />
 Efficient Resource Management: 비용 절감을 위해 AWS t2.micro 프리티어 환경 내에서 Spring Boot(8080)와 Flask(5000)를 동시에 구동.
Direct Image Transfer:  이미지 전송 시 Spring을 거치지 않고  App  ➡  Flask로 직접 전송하여 대역폭 낭비 최소화.

<br>

## ✨ Key Features
* **📸 AI 견종 분석:** 카메라 촬영 시 MobileNetV2 경량 모델이 0.5초 이내에 품종 분석 결과 제공.
* **📊 건강 모니터링:** 문진표 데이터를 시각화(Line Chart)하여 건강 변화 추이를 그래프로 제공.
* **🔐 보안 로그인:** Kakao OAuth2 및 Secure Storage 적용으로 안전한 자동 로그인 구현.
* **🧹 데이터 무결성:** 회원 탈퇴 시 연관 데이터(반려견, 기록) Cascade(연쇄) 삭제 처리.



## 📞 Contact
* **Email:** ohsanghyun14@gmail.com
* **GitHub:** https://github.com/ohsang14