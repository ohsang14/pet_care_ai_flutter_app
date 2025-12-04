<div align="center">
  <img width="180" alt="logo" src="https://github.com/user-attachments/assets/18c64887-4aa6-4efb-acba-9d0ca684a0c3" />
  <br><br>

  <h1>🐾 PetCare AI</h1>
  <h3>반려견 품종 분석 및 건강 관리 플랫폼</h3>

  <br>

  <p>
    <b>"사진 한 장으로 시작하는 우리 강아지 맞춤 주치의"</b>
  </p>
  <p>
    딥러닝(MobileNetV2)을 활용한 <b>실시간 견종 분석</b>과 생애 주기별 <b>건강 관리</b>를 제공하는<br>
    <b>Full-Stack 모바일 플랫폼</b>입니다.
  </p>
  <p>
     기획부터 디자인, AI 모델 서빙, 백엔드 구축, AWS 인프라 배포까지 <br>
     <b>1인 개발</b>로 주도적으로 수행했습니다.
  </p>
</div>

<br>

## 📝 목차
1. [프로젝트 개요](#-프로젝트-기간-및-인원)
2. [기술 스택](#-tech-stack)
3. [서비스 시연](#-service-demo-시연-화면)
4. [시스템 아키텍처](#-system-architecture)
5. [핵심 기능](#-key-features)

<br>

## 📅 프로젝트 기간 및 인원
* **기간:** 2025.09 ~ 2025.12 (약 12주)
* **인원:** 1인 개발 (Full-Stack / 기획, 디자인, 개발, 배포)

<br>

## 🛠 Tech Stack

| 분류 | 기술 스택 |
| :--- | :--- |
| **Frontend** | <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"> <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white"> |
| **Backend** | <img src="https://img.shields.io/badge/SpringBoot-6DB33F?style=for-the-badge&logo=springboot&logoColor=white"> <img src="https://img.shields.io/badge/Java 21-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white"> <img src="https://img.shields.io/badge/JPA-59666C?style=for-the-badge&logo=hibernate&logoColor=white"> |
| **AI Server** | <img src="https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white"> <img src="https://img.shields.io/badge/Python 3.12-3776AB?style=for-the-badge&logo=python&logoColor=white"> <img src="https://img.shields.io/badge/TensorFlow-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white"> |
| **Database** | <img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white"> |
| **Infra** | <img src="https://img.shields.io/badge/AWS EC2-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white"> <img src="https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white"> |

<br>

## 📱 Service Demo (시연 화면)

| 메인 및 로그인 | AI 품종 분석 (핵심) | 건강 관리 차트 |
| :---: | :---: | :---: |
| <img src="https://github.com/user-attachments/assets/3f000d8e-01c4-48cc-abf3-845c495c1f90" height="500"/> | <img src="https://github.com/user-attachments/assets/0acd50e9-baf0-40c5-afcc-cdfceed839f1" height="500"/> | <img src="https://github.com/user-attachments/assets/81ea3aaf-2966-4752-9f94-09c662c3c6b9" height="500"/> |
| **Kakao 로그인 및**<br>메인 화면 진입 | **사진 촬영 후**<br>MobileNetV2 분석 결과 | **문진표 데이터 기반**<br>건강 추이 그래프 |

<br>

## 🏗 System Architecture
**단일 EC2 인스턴스 내 이종 서버(Spring + Flask) 통합 아키텍처**

<img width="100%" alt="architecture" src="https://github.com/user-attachments/assets/96513b9c-cb66-4ba3-871b-d553a05239cc" />

> **💡 Architectural Decisions (설계 의도)**
>
> * **💰 Efficient Resource Management**
>   * 비용 절감을 위해 **AWS t2.micro (Free Tier)** 환경 내에서 Spring Boot(8080)와 Flask(5000)를 동시에 구동하여 리소스를 최적화했습니다.
> * **🚀 Direct Image Transfer**
>   * 이미지 전송 시 Spring을 거치지 않고 **App ➡ Flask로 직접 전송**하여 네트워크 대역폭 낭비를 최소화하고 응답 속도를 개선했습니다.

<br>

## ✨ Key Features

### 1. 📸 AI 견종 분석
* 사용자가 반려견 사진을 촬영하거나 업로드하면, **MobileNetV2 경량 모델**이 분석을 수행합니다.
* **0.5초 이내**의 빠른 응답 속도로 품종 분석 결과와 정확도를 제공합니다.

### 2. 📊 건강 모니터링 & 시각화
* 주기적인 문진표 데이터를 기반으로 반려견의 건강 상태를 추적합니다.
* **MPAndroidChart (Flutter)** 를 활용해 데이터를 **Line Chart**로 시각화하여, 건강 변화 추이를 직관적으로 파악할 수 있습니다.

### 3. 🔐 보안 및 사용자 편의성
* **Kakao OAuth2** 연동으로 간편하고 안전한 로그인을 지원합니다.
* **Secure Storage**를 적용하여 토큰 및 민감 정보를 디바이스 내에 안전하게 암호화하여 저장합니다.

### 4. 🧹 데이터 무결성 보장
* 회원 탈퇴 시, 해당 계정과 연관된 모든 데이터(반려견 정보, 건강 기록 등)를 **Cascade(연쇄) 삭제** 처리하여 DB 내 고아 데이터(Orphan Data) 발생을 방지했습니다.

<br>

## 📞 Contact
* **Email:** [ohsanghyun14@gmail.com](mailto:ohsanghyun14@gmail.com)
* **GitHub:** [https://github.com/ohsang14](https://github.com/ohsang14)
