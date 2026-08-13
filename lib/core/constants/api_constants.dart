class ApiConstants {
  ApiConstants._();

  // API en production :
  static const String baseUrl = 'https://apienagnon.vibecro.com/api';

  // Émulateur Android :
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Téléphone physique connecté au même réseau Wi-Fi :
  // static const String baseUrl = 'http://192.168.100.15:8000/api';

  // Web / Linux desktop en local :
  //static const String baseUrl = 'http://192.168.100.15:8000/api';

  static const login = '/auth/login';
  static const me = '/auth/me';
  static const summary = '/summary';
  static const requestTimeout = Duration(seconds: 15);
}
