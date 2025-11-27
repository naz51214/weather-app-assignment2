import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const WeatherApp());
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.grey[900],
              cardColor: Colors.grey[850],
              colorScheme: ColorScheme.dark(
                primary: Colors.blue.shade400,
              ),
            )
          : ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.blue.shade50,
              cardColor: Colors.white,
              colorScheme: ColorScheme.light(
                primary: Colors.blue.shade700,
              ),
            ),
      home: WeatherHomePage(toggleTheme: toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  const WeatherHomePage({super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController();
  final String _apiKey = "63ce35db3c14423b9c083031252611";

  Map<String, dynamic>? _currentWeather;
  List<dynamic> _forecastList = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _lastCity = 'London';

  @override
  void initState() {
    super.initState();
    _loadLastCity();
  }

  Future<void> _loadLastCity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCity = prefs.getString('lastCity') ?? 'London';
    setState(() {
      _lastCity = lastCity;
    });
    _cityController.text = lastCity;
    _fetchWeatherData(lastCity);
  }

  Future<void> _saveLastCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastCity', city);
  }

  Future<void> _fetchWeatherData(String city) async {
    if (city.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currentUrl =
          "https://api.weatherapi.com/v1/current.json?key=$_apiKey&q=$city&aqi=no";
      final currentResponse = await http.get(Uri.parse(currentUrl));

      if (currentResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);

        final forecastUrl =
            "https://api.weatherapi.com/v1/forecast.json?key=$_apiKey&q=$city&days=8&aqi=no&alerts=no";
        final forecastResponse = await http.get(Uri.parse(forecastUrl));

        if (forecastResponse.statusCode == 200) {
          final forecastData = json.decode(forecastResponse.body);

          setState(() {
            _currentWeather = currentData;
            _forecastList = forecastData["forecast"]["forecastday"]
                .skip(1)
                .take(7)
                .toList();
          });

          await _saveLastCity(city);
        } else {
          throw Exception("Failed to load forecast data");
        }
      } else if (currentResponse.statusCode == 400) {
        throw Exception("City not found — please enter a valid city name.");
      } else {
        throw Exception("Failed to load weather data");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _currentWeather = null;
        _forecastList = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String date) {
    final d = DateTime.parse(date);
    return "${d.day}/${d.month}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: widget.toggleTheme,
          )
        ],
      ),
      body: Column(
        children: [
          // SEARCH BOX
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      hintText: "Enter city name",
                      filled: true,
                      fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onSubmitted: (v) => _fetchWeatherData(v),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _fetchWeatherData(_cityController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Text(
                    "Search",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)))
                    : _currentWeather == null
                        ? const Center(child: Text("Search a city to view weather"))
                        : _buildWeatherUI(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // CURRENT WEATHER CARD
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                Text(
                  _currentWeather!["location"]["name"],
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 5),
                Text(_currentWeather!["location"]["country"], style: TextStyle(fontSize: 16, color: widget.isDarkMode ? Colors.white70 : Colors.grey)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      "https:${_currentWeather!['current']['condition']['icon']}",
                      width: 90,
                      height: 90,
                    ),
                    const SizedBox(width: 10),
                    Text("${_currentWeather!['current']['temp_c'].round()}°C", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(
                  _currentWeather!['current']['condition']['text'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: widget.isDarkMode ? Colors.white70 : Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherDetail(Icons.water_drop, "Humidity", "${_currentWeather!['current']['humidity']}%"),
                    _buildWeatherDetail(Icons.wind_power, "Wind", "${_currentWeather!['current']['wind_kph']} km/h"),
                    _buildWeatherDetail(Icons.thermostat, "Feels Like", "${_currentWeather!['current']['feelslike_c']}°C"),
                  ],
                ),
              ],
            ),
          ),

          // FORECAST CARD
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("7-Day Forecast", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 33, 215, 243))),
                const SizedBox(height: 20),
                ..._forecastList.map((day) => _buildForecastItem(day)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 30),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildForecastItem(dynamic data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[700] : const Color.fromARGB(255, 234, 227, 253),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(_formatDate(data["date"]), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Spacer(),
          Image.network("https:${data['day']['condition']['icon']}", width: 45, height: 45),
          const SizedBox(width: 10),
          Text(data['day']['condition']['text'], style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text("${data['day']['mintemp_c'].round()}° / ${data['day']['maxtemp_c'].round()}°", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}
