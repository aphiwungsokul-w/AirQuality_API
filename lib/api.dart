import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AirQualityScreen extends StatefulWidget {
  const AirQualityScreen({Key? key}) : super(key: key);

  @override
  State<AirQualityScreen> createState() => _AirQualityScreenState();
}

class _AirQualityScreenState extends State<AirQualityScreen> {
  static const String token =
      "28e3391c064638a782d88c787188514a7b0d05fc"; // ใส่ token ของคุณ
  final List<String> thaiCities = const [
    "Bangkok",
    "Nonthaburi",
    "Pathum Thani",
    "Samut Prakan",
    "Chonburi",
    "Rayong",
    "Chiang Mai",
    "Chiang Rai",
    "Phuket",
    "Khon Kaen",
    "Nakhon Ratchasima",
    "Udon Thani",
    "Hat Yai",
    "Nakhon Si Thammarat",
  ];
  DateTime? lastUpdated;

  String selectedCity = "Bangkok";
  final TextEditingController cityController = TextEditingController(
    text: "Bangkok",
  );

  int? aqi;
  String? cityName;
  double? temperatureC;
  double? pm25;
  double? pm10;
  String? errorMessage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAirQualityForCity(selectedCity);
  }

  Future<void> fetchAirQualityForCity(String city) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      lastUpdated = DateTime.now();
    });

    final url = Uri.parse("https://api.waqi.info/feed/$city/?token=$token");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["status"] == "ok") {
          final d = data["data"];
          setState(() {
            aqi = (d["aqi"] is int) ? d["aqi"] : (d["aqi"] as num?)?.toInt();
            cityName = d["city"]?["name"];

            temperatureC = (d["iaqi"]?["t"]?["v"] as num?)?.toDouble();
            pm25 = (d["iaqi"]?["pm25"]?["v"] as num?)?.toDouble();
            pm10 = (d["iaqi"]?["pm10"]?["v"] as num?)?.toDouble();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = data["data"]?.toString() ?? "Unknown API error";
            aqi = null;
            cityName = null;
            temperatureC = null;
            pm25 = null;
            pm10 = null;
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "HTTP ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String getAqiStatus(int? aqi) {
    if (aqi == null) return "Unknown";
    if (aqi <= 50) return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 150) return "Unhealthy for Sensitive Groups";
    if (aqi <= 200) return "Unhealthy";
    if (aqi <= 300) return "Very Unhealthy";
    return "Hazardous";
  }

  Color getAqiColor(int? aqi) {
    if (aqi == null) return Colors.grey;
    if (aqi <= 50) return const Color(0xFF2ECC71);
    if (aqi <= 100) return const Color(0xFFF1C40F);
    if (aqi <= 150) return const Color(0xFFE67E22);
    if (aqi <= 200) return const Color(0xFFE74C3C);
    if (aqi <= 300) return const Color(0xFF8E44AD);
    return const Color(0xFF6E2C00);
  }

  IconData getAqiIcon(int? aqi) {
    if (aqi == null) return Icons.cloud;
    if (aqi <= 50) return Icons.sentiment_very_satisfied;
    if (aqi <= 100) return Icons.sentiment_satisfied;
    if (aqi <= 150) return Icons.sentiment_neutral;
    if (aqi <= 200) return Icons.sentiment_dissatisfied;
    if (aqi <= 300) return Icons.sentiment_very_dissatisfied;
    return Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = getAqiColor(aqi);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Air Quality Index (AQI)",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 173, 21, 59),
      ),
      body: RefreshIndicator(
        onRefresh: () => fetchAirQualityForCity(selectedCity),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cityController,
                    onSubmitted: (v) {
                      if (v.trim().isEmpty) return;
                      setState(() => selectedCity = v.trim());
                      fetchAirQualityForCity(v.trim());
                    },
                    decoration: InputDecoration(
                      hintText: "พิมพ์ชื่อเมือง เช่น Bangkok",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          final v = cityController.text.trim();
                          if (v.isEmpty) return;
                          setState(() => selectedCity = v);
                          fetchAirQualityForCity(v);
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  tooltip: "เลือกเมือง",
                  onSelected: (v) {
                    cityController.text = v;
                    setState(() => selectedCity = v);
                    fetchAirQualityForCity(v);
                  },
                  itemBuilder: (context) => thaiCities
                      .map((c) => PopupMenuItem(value: c, child: Text(c)))
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 173, 21, 59),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_city, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pin_drop, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text(
                        cityName ?? selectedCity,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  if (lastUpdated != null)
                    Text(
                      "Updated: ${lastUpdated!.day.toString().padLeft(2, '0')}/"
                      "${lastUpdated!.month.toString().padLeft(2, '0')}/"
                      "${lastUpdated!.year} • "
                      "${lastUpdated!.hour.toString().padLeft(2, '0')}:"
                      "${lastUpdated!.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    aqi == null ? "—" : "AQI: $aqi • ${getAqiStatus(aqi)}",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _AqiGlassCard(
              color: color,
              aqi: aqi,
              status: getAqiStatus(aqi),
              icon: getAqiIcon(aqi),
              isLoading: isLoading,
              errorMessage: errorMessage,
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _metricChip(
                  Icons.thermostat,
                  temperatureC,
                  "°C",
                  "Temperature",
                ),
                _metricChip(Icons.blur_on, pm25, " µg/m³", "PM2.5"),
                _metricChip(Icons.grain, pm10, " µg/m³", "PM10"),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 173, 21, 59),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => fetchAirQualityForCity(selectedCity),
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(IconData icon, double? value, String unit, String label) {
    final show = value != null;
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(
        show ? "$label: ${value!.toStringAsFixed(1)}$unit" : "$label: —",
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _AqiGlassCard extends StatelessWidget {
  const _AqiGlassCard({
    required this.color,
    required this.aqi,
    required this.status,
    required this.icon,
    required this.isLoading,
    required this.errorMessage,
  });

  final Color color;
  final int? aqi;
  final String status;
  final IconData icon;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: gradient,
      ),
      padding: const EdgeInsets.all(1.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // blur layer
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            // content
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
              child: Column(
                children: [
                  Icon(icon, color: Colors.white, size: 56),
                  const SizedBox(height: 14),
                  Text(
                    aqi?.toString() ?? "--",
                    style: const TextStyle(
                      fontSize: 64,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 6.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  if (!isLoading && errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
