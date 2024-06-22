import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safeplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({Key? key}) : super(key: key);

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late InAppWebViewController _webViewController;
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var permission = await Geolocator.checkPermission();
    print("Initial Location Permission Status: $permission");

    if (permission == LocationPermission.denied) {
      _requestPermissionOnStartup();
    } else if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied");
    } else {
      setState(() {
        _permissionsRequested = true;
      });
      _getCurrentLocation();
    }
  }

  void _requestPermissionOnStartup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_permissionsRequested) {
        _permissionsRequested = true;
        _showPermissionDialog();
      }
    });
  }

  Future<void> _requestPermissions() async {
    LocationPermission permission = await Geolocator.requestPermission();
    print("Location Permission Status: $permission");

    if (permission != LocationPermission.deniedForever) {
      _getCurrentLocation();
    } else {
      print("Location permissions are permanently denied");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      var position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      print("Current Location from Flutter: Latitude = ${position.latitude}, Longitude = ${position.longitude}");

      // JavaScript 함수 호출
      _webViewController.evaluateJavascript(
        source: """
          console.log("JavaScript function called with Latitude = ${position.latitude}, Longitude = ${position.longitude}");
          window.sendLocation(${position.latitude}, ${position.longitude});
        """
      );
    } catch (e) {
      print("Failed to get current location: $e");
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('위치 정보 권한 요청'),
        content: Text('이 앱은 위치 정보를 요청하고 있습니다. 위치 서비스를 허용하시겠습니까?'),
        actions: <Widget>[
          TextButton(
            child: Text('거절'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('허용'),
            onPressed: () {
              Navigator.of(context).pop();
              _requestPermissions();
            },
          ),
        ],
      ),
    );
  }

  void _sendCurrentLocation() async {
    try {
      var position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      print("Sending current location: Latitude = ${position.latitude}, Longitude = ${position.longitude}");

      // JavaScript 함수 호출
      _webViewController.evaluateJavascript(
        source: """
          console.log("JavaScript function called with Latitude = ${position.latitude}, Longitude = ${position.longitude}");
          window.sendLocation(${position.latitude}, ${position.longitude});
        """
      );
    } catch (e) {
      print("Failed to get current location: $e");
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://xn--4k0b046bf8b.shop/')
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              width: 56,
              height: 56,
              child: IconButton(
                icon: Icon(Icons.my_location, color: Colors.white),
                onPressed: _sendCurrentLocation,
                tooltip: '현재 위치',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}