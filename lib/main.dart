import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<InitializationStatus> _initGoogleMobileAds() {
    return MobileAds.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    _initGoogleMobileAds(); // 광고 초기화를 보장합니다.
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('위치 정보 권한이 필요합니다'),
          content: Text('Safeplace에서 사용자의 위치를 확인하기 위해 권한이 필요합니다'),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermissions();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri('https://xn--4k0b046bf8b.shop/')
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
              ),
            ),
            Container(
              height: 50, // 광고 배너의 높이 설정
              width: double.infinity, // 가로를 꽉 채우도록 설정
              child: AdBanner(), // 배너 광고 위젯
            ),
          ],
        ),
      ),
    );
  }
}

class AdBanner extends StatefulWidget {
  const AdBanner({Key? key}) : super(key: key);

  @override
  _AdBannerState createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _initBannerAd();
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',  // Test ad unit ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Ad failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: _bannerAd == null ? SizedBox(height: 50) : AdWidget(ad: _bannerAd!),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
