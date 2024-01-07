import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  final locations = const [
    LatLng(37.42796133580664, -122.085749655912),
    LatLng(37.41796133580674, -122.085749655922),
    LatLng(37.43796133580684, -122.085749655932),
    LatLng(37.42796133580694, -122.095749655942),
    LatLng(37.42796133580654, -122.075749655952),
  ];

  late Set<Marker> markers;
  // late CameraPosition _cameraPosition;
  late double _screenWidth;
  late double _screenHeight;
  bool isMarkIn = false;
  List<OffsetWithAngle> _indicatorOffsetList = [];

  @override
  void initState() {
    super.initState();
    markers = locations
        .map((e) => Marker(
            markerId: MarkerId(locations.indexOf(e).toString()), position: e))
        .toSet();
  }

  Future isLatLngInBounds(List<LatLng> listLatLng) async {
    final GoogleMapController controller = await _controller.future;
    LatLngBounds bounds = await controller.getVisibleRegion();
    final LatLng mapCenterLatLng = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2.0,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2.0);
    List<LatLng> list = listLatLng
        .where((latLng) => !(latLng.latitude >= bounds.southwest.latitude &&
            latLng.latitude <= bounds.northeast.latitude &&
            latLng.longitude >= bounds.southwest.longitude &&
            latLng.longitude <= bounds.northeast.longitude))
        .toList();

    if (list.isNotEmpty && mounted) {
      List<OffsetWithAngle> offsetList = list
          .map((e) => calculateIndicatorPosition(e, mapCenterLatLng))
          .toList();
      setState(() {
        _indicatorOffsetList = offsetList;
      });
    } else {
      setState(() {
        _indicatorOffsetList = [];
      });
    }
  }

  double calculateAngle(LatLng centerLatLng, LatLng markerLatLng) {
    double deltaY = centerLatLng.latitude - markerLatLng.latitude;
    double deltaX = centerLatLng.longitude - markerLatLng.longitude;
    debugPrint('X : $deltaX, Y : $deltaY');
    return math.atan2(deltaY, deltaX) * 180 / math.pi; //
  }

  OffsetWithAngle calculateIndicatorPosition(
      LatLng centerLatLng, LatLng markerLatLng) {
    double angle = calculateAngle(centerLatLng, markerLatLng);

    // 화면의 중심을 기준으로 계산
    double centerX = _screenWidth / 2;
    double centerY = _screenHeight / 2;

    double x, y;

    // 각도에 따라 수평 또는 수직 방향 결정
    if (angle >= -45 && angle <= 45) {
      // 수직 방향 (상하단 경계)
      x = _screenWidth - 20; // 우측 또는 좌측 경계
      y = centerY - centerX * math.tan(angle * math.pi / 180);
    } else if (angle >= 135 || angle <= -135) {
      x = 0; // 우측 또는 좌측 경계
      y = centerY + centerX * math.tan(angle * math.pi / 180);
    } else if (angle < 135 && angle > 45) {
      y = 0; // 상단 또는 하단 경계
      x = centerX + centerY / math.tan(angle * math.pi / 180);
    } else {
      // 수평 방향 (좌우측 경계)
      y = _screenHeight - 20; // 상단 또는 하단 경계
      x = centerX - centerY / math.tan(angle * math.pi / 180);
    }

    debugPrint('x : $x , y : $y');
    return OffsetWithAngle(Offset(x, y), angle);
  }

  @override
  Widget build(BuildContext context) {
    Size directionIndicatorSize = const Size(20, 20);

    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        _screenHeight = constraints.constrainHeight();
        _screenWidth = constraints.constrainWidth();

        return Stack(
          children: [
            GoogleMap(
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              mapType: MapType.hybrid,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onCameraMove: (position) {
                // _cameraPosition = position;
                isLatLngInBounds(locations);
              },
              markers: markers,
            ),
            ..._indicatorOffsetList.map<Widget>((el) {
              return Positioned(
                left: el.offset.dx,
                top: el.offset.dy,
                child: IgnorePointer(
                  ignoring: true,
                  child: Transform.rotate(
                    angle: -el.angle * math.pi / 180,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.asset('assets/images/arrow.png'),
                    ),
                  ),
                ),
              );
            }).toList()
          ],
        );
      }),
    );
  }
}

class OffsetWithAngle {
  Offset offset;
  double angle;

  OffsetWithAngle(this.offset, this.angle);
}