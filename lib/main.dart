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
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      setState(() {
        _permissionsRequested = true;
      });
    } else {
      _requestPermissionOnStartup();
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
    if (permission == LocationPermission.deniedForever) {
      _showDeniedForeverDialog();
    }
  }

  void _showDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('권한 거부됨'),
        content: Text('권한이 영구적으로 거부되었습니다.'),
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
              Navigator.of(context).pop();
              _requestPermissions();
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
                url: WebUri('https://xn--4k0b046bf8b.shop/'),
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
