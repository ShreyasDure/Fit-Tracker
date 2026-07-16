import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherData {
  final double temp;
  final double feelsLike;
  final String condition;
  final int conditionCode;
  final double humidity;
  final double windSpeed;
  final double uvIndex;
  final String sunrise;
  final String sunset;
  final int isDay;
  final String recommendation;
  final DateTime fetchedAt;

  WeatherData({
    required this.temp,
    required this.feelsLike,
    required this.condition,
    required this.conditionCode,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
    required this.isDay,
    required this.recommendation,
    required this.fetchedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'temp': temp,
      'feelsLike': feelsLike,
      'condition': condition,
      'conditionCode': conditionCode,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'uvIndex': uvIndex,
      'sunrise': sunrise,
      'sunset': sunset,
      'isDay': isDay,
      'recommendation': recommendation,
      'fetchedAt': fetchedAt.toIso8601String(),
    };
  }

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      temp: (map['temp'] as num).toDouble(),
      feelsLike: (map['feelsLike'] as num).toDouble(),
      condition: map['condition'] ?? 'Clear',
      conditionCode: (map['conditionCode'] as num).toInt(),
      humidity: (map['humidity'] as num).toDouble(),
      windSpeed: (map['windSpeed'] as num).toDouble(),
      uvIndex: (map['uvIndex'] as num).toDouble(),
      sunrise: map['sunrise'] ?? '06:00',
      sunset: map['sunset'] ?? '18:00',
      isDay: (map['isDay'] as num).toInt(),
      recommendation: map['recommendation'] ?? '',
      fetchedAt: DateTime.parse(map['fetchedAt']),
    );
  }
}

class WeatherService {
  static const String _cacheKey = 'cached_weather_data';

  static String _getConditionString(int code) {
    if (code == 0) return 'Sunny';
    if (code >= 1 && code <= 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Foggy';
    // Rain and Thunderstorm codes
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || (code >= 95 && code <= 99)) return 'Rainy';
    // Snow codes
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) return 'Snowy';
    return 'Clear';
  }

  static String _generateRecommendation(double temp, String condition, double uvIndex) {
    if (condition == 'Rainy') {
      return 'Rain active. Indoor workout recommended today! Try a treadmill run, indoor HIIT, or core yoga. 🌧️🧘';
    }
    if (condition == 'Snowy') {
      return 'Snow outside! Warm up thoroughly and stay safe indoors with dynamic stretching or bodyweight strength training. ❄️🏋️';
    }
    if (temp >= 30) {
      if (uvIndex >= 6.0) {
        return 'Extreme heat & high UV index. Shift running to morning/evening. Stay hydrated: drink 1L of water every hour! 🥵🥤';
      }
      return 'Weather is hot. Drink extra water and seek shade during workouts. Perfect for an air-conditioned gym session. ☀️💧';
    }
    if (temp <= 10) {
      return 'It is cold outside. Warm up properly before exercising to prevent injury. Consider wearing layers! ❄️🧥';
    }
    if (uvIndex >= 6.0) {
      return 'UV index is high today. Apply sunscreen and avoid running under direct sunlight in the afternoon! 🧴🏃';
    }
    if (temp >= 15 && temp <= 22) {
      return 'Endurance weather booster! Cool, pleasant temperatures are absolutely perfect for outdoor long-distance running or jogging. 🏃‍♂️🍃';
    }
    return 'Pleasant conditions outside. Great day for a brisk walk, outdoor bodyweight exercises, or cycling! 🚲✨';
  }

  static Future<WeatherData?> getCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final map = json.decode(raw);
      final data = WeatherData.fromMap(map);
      
      // Cache is valid for 20 minutes
      if (DateTime.now().difference(data.fetchedAt).inMinutes < 20) {
        return data;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> cacheWeather(WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data.toMap()));
    } catch (_) {}
  }

  static Future<WeatherData> fetchWeather() async {
    // 1. Check & Request Permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission required for weather insights.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission required for weather insights.');
    }

    // 2. Try Cached Weather
    final cached = await getCachedWeather();
    if (cached != null) return cached;

    // 3. Get Coordinates (low accuracy for faster and more energy-efficient response)
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: const Duration(seconds: 5),
    );

    // 4. Fetch from Open-Meteo
    final url = 'https://api.open-meteo.com/v1/forecast?'
        'latitude=${position.latitude}&longitude=${position.longitude}'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m'
        '&daily=uv_index_max,sunrise,sunset&timezone=auto&forecast_days=1';

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Failed to connect to weather service.');
    }

    final data = json.decode(response.body);
    final current = data['current'];
    final daily = data['daily'];

    final wCode = (current['weather_code'] as num).toInt();
    final temp = (current['temperature_2m'] as num).toDouble();
    final feelsLike = (current['apparent_temperature'] as num).toDouble();
    final humidity = (current['relative_humidity_2m'] as num).toDouble();
    final windSpeed = (current['wind_speed_10m'] as num).toDouble();
    final isDay = (current['is_day'] as num).toInt();
    
    final uvIndex = (daily['uv_index_max']?[0] as num?)?.toDouble() ?? 0.0;
    
    final sunriseFull = daily['sunrise']?[0] ?? '';
    final sunsetFull = daily['sunset']?[0] ?? '';
    
    final sunrise = sunriseFull.length >= 16 ? sunriseFull.substring(11) : '06:00';
    final sunset = sunsetFull.length >= 16 ? sunsetFull.substring(11) : '18:00';

    final condition = _getConditionString(wCode);
    final recommendation = _generateRecommendation(temp, condition, uvIndex);

    final weather = WeatherData(
      temp: temp,
      feelsLike: feelsLike,
      condition: condition,
      conditionCode: wCode,
      humidity: humidity,
      windSpeed: windSpeed,
      uvIndex: uvIndex,
      sunrise: sunrise,
      sunset: sunset,
      isDay: isDay,
      recommendation: recommendation,
      fetchedAt: DateTime.now(),
    );

    await cacheWeather(weather);
    return weather;
  }
}
