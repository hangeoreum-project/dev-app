import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  late final WebViewController _controller;
  LatLng? _currentPosition;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _setupWebView();
    _getCurrentLocation();
  }

  void _setupWebView() {
    final htmlData = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        html, body { height: 100%; margin: 0; padding: 0; }
        #map { width: 100%; height: 100%; display:flex; align-items:center; justify-content:center; font-family: -apple-system, Roboto, "Segoe UI", Arial, sans-serif; }
      </style>
    </head>
    <body>
      <div id="map">카카오맵 자리에 임시 컨텐츠</div>
      <script>
        function moveToLocation(lat, lng) {
          document.getElementById('map').innerText = '이동한 위치: ' + lat + ', ' + lng;
        }
      </script>
    </body>
    </html>
    ''';

    final uri = Uri.dataFromString(
      htmlData,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8'),
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(uri);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // 최소 권한 체크/요청(간단 버전)
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
    } catch (_) {
      // 데모 단계이므로 조용히 무시
    }
  }

  void _centerMap() {
    if (_currentPosition != null) {
      final js = "moveToLocation(${_currentPosition!.latitude}, ${_currentPosition!.longitude});";
      _controller.runJavaScript(js);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 위치를 가져오는 중입니다...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ 최신 API
          WebViewWidget(controller: _controller),

          // 상단 카드 + 검색창
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
                    child: Text("Today you walk $_steps steps.", style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0,2))],
                    ),
                    height: 45,
                    child: const Row(
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

          // 오른쪽 하단 FAB들
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "centerBtn",
                  onPressed: _centerMap,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "nextBtn",
                  onPressed: () => Navigator.pushNamed(context, '/next'),
                  child: const Icon(Icons.arrow_forward),
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
            // 현재 화면이 메인이라 보통은 popUntil 등으로 처리하지만 데모에선 생략
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

class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);
}

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Search")), body: const Center(child: Text("Search screen")));
  }
}

class PostcardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Postcard")), body: const Center(child: Text("Postcard screen")));
  }
}

class SNSScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("SNS Search")), body: const Center(child: Text("SNS screen")));
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Settings")), body: const Center(child: Text("Settings screen")));
  }
}

class NextScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text("Next Page")), body: const Center(child: Text("Next screen")));
  }
}
