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
      title: 'SafeArea Example',
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
  int _selectedIndex = 0;
  bool _permissionsRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_permissionsRequested) {
      _permissionsRequested = true;
      // Schedule the permission dialog to be shown after the build process.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog(); 
      });
    }
  }

  Future<void> _requestPermissions() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      // Handle permanently denied permission.
      _showDeniedForeverDialog();
      return;
    }

    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void _showDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('권한 거부됨'),
        content: Text('권한이 거부되어 위치를 확인할 수 없습니다'),
        actions: <Widget>[
          TextButton(
            child: Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('위치 정보 권한 요청'),
        content: Text('Safeplace가 사용자의 위치를 확인하기 위해 위치 권한이 필요합니다'),
        actions: <Widget>[
          TextButton(
            child: Text('취소'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('확인'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog first
              _requestPermissions(); // Then request permissions
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri('https://xn--4k0b046bf8b.shop/'), // Correct URL parsing
              ),
              initialOptions: InAppWebViewGroupOptions(
                android: AndroidInAppWebViewOptions(useHybridComposition: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
