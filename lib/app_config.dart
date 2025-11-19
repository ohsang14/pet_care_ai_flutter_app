import 'dart:io'; // Platform 감지용

class AppConfig {
  // static getter를 사용하여 실행 시점에 플랫폼을 확인합니다.
  static String get baseUrl {
    if (Platform.isAndroid) {
      // 안드로이드 에뮬레이터는 호스트(PC)를 10.0.2.2로 인식합니다.
      return "http://10.0.2.2:8080";
    } else {
      // iOS 시뮬레이터, 데스크탑(Mac/Windows)은 localhost를 사용합니다.
      return "http://localhost:8080";
    }
  }
}