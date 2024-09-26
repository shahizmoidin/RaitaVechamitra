import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:raitavechamitra/services/weather_service.dart';

final weatherProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, location) async {
  final weatherService = WeatherService();
  return await weatherService.getWeather(location);
});

final forecastProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, location) async {
  final weatherService = WeatherService();
  return await weatherService.getForecast(location);
});

class WeatherScreen extends ConsumerStatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  String location = 'London';

  @override
  Widget build(BuildContext context) {
    final weatherSnapshot = ref.watch(weatherProvider(location));
    final forecastSnapshot = ref.watch(forecastProvider(location));

    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Forecast'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[800]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _showLocationSearch(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: weatherSnapshot.when(
            data: (weatherData) {
              return forecastSnapshot.when(
                data: (forecastData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentWeather(weatherData),
                      SizedBox(height: 16),
                      Text(
                        'Weather Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      _buildWeatherDetails(weatherData),
                      SizedBox(height: 16),
                      Text(
                        'Next 12 Hours',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      _buildHourlyForecast(forecastData, isNext: true),
                      SizedBox(height: 16),
                      Text(
                        'Previous 12 Hours',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      _buildHourlyForecast(forecastData, isNext: false),
                    ],
                  );
                },
                loading: () => _buildLoading(),
                error: (err, _) => Center(child: Text('Error loading forecast')),
              );
            },
            loading: () => _buildLoading(),
            error: (err, _) => Center(child: Text('Error loading weather')),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeather(Map<String, dynamic> weatherData) {
    final temp = weatherData['main']['temp'];
    final description = weatherData['weather'][0]['description'];
    final icon = weatherData['weather'][0]['icon'];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.withOpacity(0.5), Colors.blueAccent.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Image.network(
              'https://openweathermap.org/img/wn/$icon@2x.png',
              height: 80,
              width: 80,
            ),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$temp°C',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(Map<String, dynamic> weatherData) {
    final humidity = weatherData['main']['humidity'];
    final pressure = weatherData['main']['pressure'];
    final windSpeed = weatherData['wind']['speed'];

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildWeatherDetailItem('Humidity', '$humidity%', Icons.water),
            _buildWeatherDetailItem('Pressure', '$pressure hPa', Icons.compress),
            _buildWeatherDetailItem('Wind', '$windSpeed m/s', Icons.air),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetailItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 30),
        SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHourlyForecast(Map<String, dynamic> forecastData, {required bool isNext}) {
    final forecastList = forecastData['list'];
    final currentTime = DateTime.now();

    // Filter the forecast for the next or previous 12 hours
    final forecastItems = forecastList.where((item) {
      final itemTime = DateTime.parse(item['dt_txt']);
      return isNext
          ? itemTime.isAfter(currentTime) && itemTime.isBefore(currentTime.add(Duration(hours: 12)))
          : itemTime.isBefore(currentTime) && itemTime.isAfter(currentTime.subtract(Duration(hours: 12)));
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: forecastItems.map<Widget>((item) {
          final time = DateTime.parse(item['dt_txt']);
          final temp = item['main']['temp'];
          final icon = item['weather'][0]['icon'];

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            width: 80,
            child: Column(
              children: [
                Text(DateFormat.j().format(time)),
                Image.network(
                  'https://openweathermap.org/img/wn/$icon@2x.png',
                  height: 50,
                  width: 50,
                ),
                Text('$temp°C'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator());
  }

  void _showLocationSearch(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Location'),
        content: SingleChildScrollView(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(hintText: 'Enter city name'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                location = searchController.text;
              });
              Navigator.pop(context);
            },
            child: Text('Search'),
          ),
        ],
      ),
    );
  }
}
