import 'package:flutter_dotenv/flutter_dotenv.dart';
String get apiUrl => dotenv.env['API_URL'] ?? 'http://localhost:8000/api/v1';
