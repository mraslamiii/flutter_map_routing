import 'dart:math' as Math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class _ProjectedPoint {
  late CustomPoint<num> projectedCoordinates;
  late num distanceFromStart;
}

class ProjectedPointList {
  List<LatLng>? _pointList;
  List<_ProjectedPoint>? _points;
  late num _totalProjectedLength;
  late Crs _crs;

  ProjectedPointList(List<LatLng> pointList, {Crs? crs}) {
    _pointList = pointList;
    _project(crs ?? Epsg3857());
  }

  num get totalProjectedLength => _totalProjectedLength;

  set crs(Crs crs) {
    if (_crs == crs) return;
    _project(crs);
  }

  Crs get crs => _crs;

  set pointList(List<LatLng> pointList) {
    _pointList = pointList;
    _project(_crs);
  }

  List<LatLng> get pointList => _pointList!;

  void _project(Crs crs) {
    var projectedPoints = _pointList
        ?.map((coords) => _ProjectedPoint()
          ..projectedCoordinates = crs.projection.project(coords)
          ..distanceFromStart = 0.0)
        .toList();
    var entireLength = 0.0;
    for (var c = 1; c < projectedPoints!.length; c++) {
      entireLength += _distance(projectedPoints[c - 1].projectedCoordinates,
          projectedPoints[c].projectedCoordinates);
      projectedPoints[c].distanceFromStart = entireLength;
    }
    _totalProjectedLength = entireLength;
    _points = projectedPoints;
    _crs = crs;
  }

  List<LatLng>? portion(double portion) {
    if (portion == 0) return [];
    if (portion == 1) return _pointList;
    var requestedLength = portion * _totalProjectedLength;

    var nextPointIndex = _points
        ?.indexWhere((point) => point.distanceFromStart >= requestedLength);

    var newArr = _pointList?.sublist(0, nextPointIndex);
    if (_points![nextPointIndex!].distanceFromStart > requestedLength) {
      var previousPoint = _points![nextPointIndex - 1];
      var nextPoint = _points![nextPointIndex];
      newArr?.add(_crs.projection.unproject(_pointBetween(
          previousPoint.projectedCoordinates,
          nextPoint.projectedCoordinates,
          requestedLength - previousPoint.distanceFromStart)));
    }
    return newArr;
  }

// List<CustomPoint> projdPortion(double portion) {
//   var requestedLength = portion * _totalProjectedLength;

//   var nextPointIndex = _points
//       .indexWhere((point) => point.distanceFromStart >= requestedLength);
//   var newArr = _points
//       .sublist(0, nextPointIndex + 1)
//       .map((e) => e.projectedCoordinates)
//       .toList();
//   if (_points[nextPointIndex].distanceFromStart > requestedLength) {
//     var previousPoint = _points[nextPointIndex - 1];
//     var nextPoint = _points[nextPointIndex];
//     newArr.add(_pointBetween(
//         previousPoint.projectedCoordinates,
//         nextPoint.projectedCoordinates,
//         requestedLength - previousPoint.distanceFromStart));
//   }
//   return newArr;
// }
}

double _distance(CustomPoint pointA, CustomPoint pointB) {
  return Math.sqrt(
      Math.pow(pointA.x - pointB.x, 2) + Math.pow(pointA.y - pointB.y, 2));
}

CustomPoint _pointBetween(
    CustomPoint pointA, CustomPoint pointB, num distanceFromPointA) {
  var distanceBetweenPoints = _distance(pointA, pointB);
  var newX = pointA.x +
      (distanceFromPointA / distanceBetweenPoints) * (pointB.x - pointA.x);
  var newY = pointA.y +
      (distanceFromPointA / distanceBetweenPoints) * (pointB.y - pointA.y);
  return CustomPoint(newX, newY);
}
