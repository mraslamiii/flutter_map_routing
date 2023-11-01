import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ltlng;
import 'package:http/http.dart' as http;
import 'package:map_flutter/projected_point.dart';
import 'package:map_flutter/search_model.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

import 'line_anim.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<ltlng.LatLng> polylines = [];
  GeoJsonParser myGeoJson = GeoJsonParser();
  ProjectedPointList? projected;
  late MapController mapController;

  EasyAnimationController? animator = EasyAnimationController();

  late ProgressDialog _dialog;
  ltlng.LatLng? endPoint;
  ltlng.LatLng? startPoint;


  ///get  LocationPermission
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }


  ///close polyline

  closeDirections() {
    setState(() {
      polylines.clear();
      animator?.stop();
      startPoint = null;
      endPoint = null;
      projected = null;
    });
  }

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _determinePosition();
    _dialog = ProgressDialog(context: context);
  }



  ///this function use for get direction from 2 point
  ///https://map.project-osrm.org/
  ///https://openrouteservice.org/

  Future getRoute() async {
    _dialog.show(
        msg: 'Getting directions...',
        progressType: ProgressType.normal,
        backgroundColor: Color(0xff212121),
        progressValueColor: Color(0xff3550B4),
        progressBgColor: Colors.white70,
        msgColor: Colors.white,
        valueColor: Colors.white);
    var client = http.Client();
    try {
      Map<String, String> qParams = {
        'api_key': '5b3ce3597851110001cf62485c245aded2e14d149fb577f2e3b35e8e',
        'start': '${startPoint?.longitude},${startPoint?.latitude}',
        'end': '${endPoint?.longitude},${endPoint?.latitude}',
      };

      final uri = Uri.https(
          'api.openrouteservice.org', '/v2/directions/driving-car', qParams);
      final response = await http.get(uri, headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      });

      myGeoJson.parseGeoJsonAsString(response.body);

      projected = ProjectedPointList(myGeoJson.polylines.first.points);
      setState(() {
        _dialog.close();
        animator?.start(
            initialPortion: 0.0,
            finishedPortion: 1.0,
            animationDuration: Duration(seconds: 5),
            animationCurve: Curves.easeInOutCubic,
            onValueChange: (value) {
              setState(() {
                polylines = projected!.portion(value)!;
              });
            },
            onFinish: () {});
      });
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              onTap: (tapPosition, point) async {
                setState(() {
                  if (startPoint == null) {
                    startPoint = point;
                  } else {
                    endPoint = point;
                  }
                });

                if (startPoint != null && endPoint != null) {
                  await getRoute();
                }
              },
              initialCenter: ltlng.LatLng(36.310699, 59.599457),
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/hamidaslami2/clob8flgd012t01qsdwnf70md/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiaGFtaWRhc2xhbWkyIiwiYSI6ImNsbm9wcm5idjAyaWUya255enF0bmZyNnoifQ.eD-IuFdTBd9rDEgqyPyQEA',
              ),
              CurrentLocationLayer(
                followOnLocationUpdate: FollowOnLocationUpdate.once,
                turnOnHeadingUpdate: TurnOnHeadingUpdate.never,

                // indicators: LocationMarkerIndicators(),

                style: LocationMarkerStyle(
                  marker: Container(
                    decoration: BoxDecoration(boxShadow: [
                      BoxShadow(
                          color: Colors.grey.shade300,
                          spreadRadius: 5,
                          blurRadius: 5)
                    ], color: Colors.white, shape: BoxShape.circle),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.blueAccent, shape: BoxShape.circle),
                    ),
                  ),
                  markerSize: const Size.square(25),
                  accuracyCircleColor: Colors.blueAccent.withOpacity(0.1),
                  headingSectorColor: Colors.blueAccent.withOpacity(0.8),
                  headingSectorRadius: 50,
                ),
                moveAnimationDuration: Duration.zero, // disable animation
              ),
              if (polylines.isNotEmpty)
                PolylineLayer(polylineCulling: true, polylines: [
                  Polyline(
                      colorsStop: [0.0, 1.0],
                      strokeJoin: StrokeJoin.round,
                      strokeWidth: 8,
                      gradientColors: [Colors.green, Colors.green.shade700],
                      borderColor: Colors.black87,
                      strokeCap: StrokeCap.round,
                      points: polylines)
                ]),
              MarkerLayer(
                rotate: true,
                markers: [
                  Marker(
                    point: const ltlng.LatLng(36.318079, 59.588619),
                    width: 40,
                    height: 40,
                    child: marker(0),
                  ),
                  Marker(
                    rotate: true,
                    point: const ltlng.LatLng(36.317560, 59.596220),
                    width: 40,
                    height: 40,
                    child: marker(1),
                  ),
                  Marker(
                    rotate: true,
                    point: const ltlng.LatLng(36.315140, 59.582950),
                    width: 40,
                    height: 40,
                    child: marker(2),
                  ),
                  Marker(
                    rotate: true,
                    point: const ltlng.LatLng(36.313307, 59.584926),
                    width: 40,
                    height: 40,
                    child: marker(3),
                  ),
                  Marker(
                    rotate: true,
                    point: const ltlng.LatLng(36.306529, 59.592269),
                    width: 40,
                    height: 40,
                    child: marker(4),
                  ),
                ],
              ),
            ],
          ),
          buildFloatingSearchBar(),
          if (polylines.isNotEmpty)
            Positioned(
              left: 50,
              right: 50,
              bottom: 24,
              child: FilledButton(
                child: Text('Clear line'),
                onPressed: () {
                  closeDirections();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget marker(int index) {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade300, spreadRadius: 5, blurRadius: 5)
          ],
          color: Colors.grey.shade200,
          shape: BoxShape.circle),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: CircleAvatar(backgroundImage: NetworkImage(images[index])),
      ),
    );
  }
}

Random random = Random();

List<String> images = [
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
  'https://picsum.photos/id/${Random().nextInt(100)}/200/300',
];

class buildFloatingSearchBar extends StatefulWidget {
  const buildFloatingSearchBar({super.key});

  @override
  State<buildFloatingSearchBar> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<buildFloatingSearchBar> {
  final _counterModel = SearchModel();

  @override
  Widget build(BuildContext context) {
    return FloatingSearchBar(
      hint: 'Search...',
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      transitionDuration: const Duration(milliseconds: 800),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),

      openAxisAlignment: 0.0,
      width: 600,
      debounceDelay: const Duration(milliseconds: 500),
      onQueryChanged: (query) async {
        await _counterModel.onQueryChanged(query);
      },
      // Specify a custom transition to be used for
      // animating between opened and closed stated.
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            icon: const Icon(Icons.place),
            onPressed: () {},
          ),
        ),
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),
      ],
      builder: (context, transition) {
        return ListenableBuilder(
          listenable: _counterModel,
          builder: (context, child) => Container(
            color: Colors.white,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                  children: _counterModel.suggestions
                      .map((e) => GestureDetector(
                          child: ListTile(title: Text(e.display_name))))
                      .toList()),
            ),
          ),
        );
      },
    );
  }
}
