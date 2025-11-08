import 'dart:convert';
import 'package:flutter/services.dart';

class Environment {
  static late String supabaseUrl;
  static late String supabaseKey;
  
  static Future<void> load() async {
    final jsonString = await rootBundle.loadString('env.json');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    
    supabaseUrl = jsonMap['SUPABASE_URL'] as String;
    supabaseKey = jsonMap['SUPABASE_KEY'] as String;
  }
}