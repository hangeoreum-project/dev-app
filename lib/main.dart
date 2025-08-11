import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health/health.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      routes: {
        '/search': (context) => SearchScreen(),
        '/postcard': (context) => PostcardScreen(),
        '/sns': (context) => SNSScreen(),
        '/settings': (context) => SettingsScreen(),
        '/next': (context) => NextScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _fetchStepData();
    _getCurrentLocation();
  }

  Future<void> _fetchStepData() async {
    HealthFactory health = HealthFactory();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    bool requested = await health.requestAuthorization([HealthDataType.STEPS]);
    if (requested) {
      List<HealthDataPoint> steps = await health.getHealthDataFromTypes(midnight, now, [HealthDataType.STEPS]);
      int totalSteps = steps.fold(0, (sum, e) => sum + (e.value as int));
      setState(() => _steps = totalSteps);
    }
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentPosition = LatLng(position.latitude, position.longitude));
  }

  void _centerMap() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? LatLng(37.7749, -122.4194), // default: SF
              zoom: 14,
            ),
            myLocationEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
          ),
          Positioned(
            top: 50,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text("Today you walk $_steps steps.", style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 3)],
                    ),
                    height: 45,
                    child: Row(
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Text("Search here")
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "centerBtn",
                  onPressed: _centerMap,
                  child: Icon(Icons.my_location),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "nextBtn",
                  onPressed: () => Navigator.pushNamed(context, '/next'),
                  child: Icon(Icons.arrow_forward),
                )
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/');
              break;
            case 1:
              Navigator.pushNamed(context, '/postcard');
              break;
            case 2:
              Navigator.pushNamed(context, '/sns');
              break;
            case 3:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: "Postcard"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "SNS Search"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search")),
      body: Center(child: Text("Search screen")),
    );
  }
}

class PostcardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Postcard")), body: Center(child: Text("Postcard screen")));
  }
}

class SNSScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("SNS Search")), body: Center(child: Text("SNS screen")));
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Settings")), body: Center(child: Text("Settings screen")));
  }
}

class NextScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Next Page")), body: Center(child: Text("Next screen")));
  }
}
