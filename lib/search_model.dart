import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:map_flutter/place_model.dart';


class SearchModel extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<Place> _suggestions = [];

  List<Place> get suggestions => _suggestions;

  String _query = '';

  String get query => _query;

  Future<void> onQueryChanged(String query) async {
    if (query == _query) {
      return;
    }

    _query = query;
    _isLoading = true;
    notifyListeners();

    if (query.isEmpty) {
      // _suggestions = history;
    } else {
      final http.Response response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=jsonv2'));
      final dynamic body = json.decode(utf8.decode(response.bodyBytes));
      try {
        _suggestions =
            List<Place>.from(body.map((model) => Place.fromJson(model)));
      } catch (e) {
        print(e);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    // _suggestions = history;
    notifyListeners();
  }
}
