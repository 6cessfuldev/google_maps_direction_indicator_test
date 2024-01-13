import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'services/calculate_service.dart';

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
      home: const GoogleMapWithDirectionIndicator(
          width: 400, height: 700, indicatorColor: Colors.blue),
    );
  }
}

class GoogleMapWithDirectionIndicator extends StatefulWidget {
  const GoogleMapWithDirectionIndicator({
    super.key,
    this.width,
    this.height,
    this.indicatorColor = Colors.blue,
  });

  final double? width;
  final double? height;
  final Color indicatorColor;

  @override
  State<GoogleMapWithDirectionIndicator> createState() =>
      _GoogleMapWithDirectionIndicatorState();
}

class _GoogleMapWithDirectionIndicatorState
    extends State<GoogleMapWithDirectionIndicator> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  final locations = const [
    LatLng(37.42796133580664, -122.085749655912),
    // LatLng(37.41796133580674, -122.085749655922),
    // LatLng(37.43796133580684, -122.085749655932),
    // LatLng(37.42796133580694, -122.095749655942),
    // LatLng(37.42796133580654, -122.075749655952),
  ];

  late Set<Marker> markers;
  bool isMarkIn = false;
  List<OffsetWithAngle> _indicatorOffsetList = [];
  Size directionIndicatorSize = const Size(50, 50);

  late CalculateService _service;
  @override
  void initState() {
    super.initState();
    markers = locations
        .map((e) => Marker(
            markerId: MarkerId(locations.indexOf(e).toString()), position: e))
        .toSet();
  }

  renderIndicator() async {
    List<OffsetWithAngle> offsets = await _service.calculateOffsets(
        _controller, locations, directionIndicatorSize);
    if (mounted) {
      setState(() {
        _indicatorOffsetList = offsets;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: widget.height,
          width: widget.width,
          child: LayoutBuilder(builder: (context, constraints) {
            _service = CalculateService(
                constraints.constrainWidth(), constraints.constrainHeight());

            return Stack(
              children: [
                GoogleMap(
                  tiltGesturesEnabled: false,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  mapType: MapType.normal,
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  onCameraMove: (_) {
                    renderIndicator();
                  },
                  markers: markers,
                ),
                if (markers.isNotEmpty)
                  ..._indicatorOffsetList.map<Widget>((el) {
                    return Positioned(
                      left: el.offset.dx,
                      top: el.offset.dy,
                      child: IgnorePointer(
                        ignoring: true,
                        child: Transform.rotate(
                          // angle: 0,
                          angle: -el.angle * math.pi / 180,
                          child: Image.asset(
                            'assets/images/arrow.png',
                            color: widget.indicatorColor,
                            height: directionIndicatorSize.height,
                            width: directionIndicatorSize.width,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            );
          }),
        ),
      ),
    );
  }
}
