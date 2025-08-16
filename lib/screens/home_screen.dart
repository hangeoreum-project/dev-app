import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/lat_lng.dart';
import 'next_screen.dart';
import 'postcard_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'sns_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final WebViewController _controller;
  LatLng? _currentPosition;
  int _steps = 0; // TODO: connect to a pedometer if needed

  @override
  void initState() {
    super.initState();
    _setupWebView();
    _getCurrentLocation();
  }

  void _setupWebView() {
    const htmlData = '''
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
      // 권한 체크/요청(간단 버전)
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

  void _onBottomNavTap(int index) {
    switch (index) {
      case 0:
      // 현재 화면이 메인이라 별도 처리 없음
        break;
      case 1:
        Navigator.pushNamed(context, PostcardScreen.routeName);
        break;
      case 2:
        Navigator.pushNamed(context, SNSScreen.routeName);
        break;
      case 3:
        Navigator.pushNamed(context, SettingsScreen.routeName);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도 (WebView)
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
                    child: Text('Today you walk $_steps steps.', style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, SearchScreen.routeName),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                    ),
                    height: 45,
                    child: const Row(
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Text('Search here')
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
                  heroTag: 'centerBtn',
                  onPressed: _centerMap,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'nextBtn',
                  onPressed: () => Navigator.pushNamed(context, NextScreen.routeName),
                  child: const Icon(Icons.arrow_forward),
                )
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Postcard'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'SNS Search'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}