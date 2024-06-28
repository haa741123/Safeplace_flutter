import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]) // Locking orientation to portrait
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<InitializationStatus> _initGoogleMobileAds() {
    return MobileAds.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    _initGoogleMobileAds(); // Ensure ad initialization
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
  int _gpsButtonClickCount = 0;
  InterstitialAd? _interstitialAd;

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
          title: Text('위치 정보 권한 요청'),
          content: Text('Safeplace에서 혼잡도 정보를 제공하기 위해 사용자의 위치를 조회하려고 합니다'),
          actions: <Widget>[
            TextButton(
              child: Text('허용'),
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

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // 실제 광고 단위 ID로 교체 필요
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _moveToHome();
            },
          );

          setState(() {
            _interstitialAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd?.show();
      _interstitialAd = null; // Reset the ad instance after showing
      _gpsButtonClickCount = 0; // Reset the click count
    } else {
      _moveToHome();
    }
  }

  void _moveToHome() {
    Navigator.of(context).pop(); // Example action to move to the home screen
  }

  void _handleGpsButtonClick() {
    _gpsButtonClickCount++;
    if (_gpsButtonClickCount >= 3) {
      _loadInterstitialAd();
      _showInterstitialAd();
    } else {
      _sendCurrentLocation();
    }
  }

  Future<void> _sendCurrentLocation() async {
    try {
      var position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      print("Sending current location: Latitude = ${position.latitude}, Longitude = ${position.longitude}");

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
            Column(
              children: [
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri('https://xn--4k0b046bf8b.shop/')
                    ),
                    initialSettings: InAppWebViewSettings(
                      disableContextMenu: true, // Disable context menu
                      useShouldOverrideUrlLoading: true, // Disable URL loading on tap
                      supportZoom: false, // Disable zoom
                      javaScriptCanOpenWindowsAutomatically: false, // Disable JavaScript opening new windows
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      return NavigationActionPolicy.CANCEL;
                    },
                    onLoadStop: (controller, url) async {
                      await _webViewController.evaluateJavascript(source: """
                        document.body.style.webkitUserSelect = 'none';
                        document.body.style.khtmlUserSelect = 'none';
                        document.body.style.mozUserSelect = 'none';
                        document.body.style.msUserSelect = 'none';
                        document.body.style.userSelect = 'none';
                      """);
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
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 56,
                height: 56,
                child: IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  onPressed: _handleGpsButtonClick,
                  tooltip: '현재 위치',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
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
      request: const AdRequest(),
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
