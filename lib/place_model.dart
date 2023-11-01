///this model use in search
///https://nominatim.openstreetmap.org/ui/search.html

///api for get place for a query
///https://nominatim.org/release-docs/develop/api/Search/

/// you can use from this parameter for example :
/*
{
"address": {
"ISO3166-2-lvl4": "DE-BE",
"borough": "Mitte",
"city": "Berlin",
"country": "Deutschland",
"country_code": "de",
"neighbourhood": "Sprengelkiez",
"postcode": "13347",
"road": "Lindower Straße",
"shop": "Ditsch",
"suburb": "Wedding"
},
"addresstype": "shop",
"boundingbox": [
"52.5427201",
"52.5427654",
"13.3668619",
"13.3669442"
],
"category": "shop",
"display_name": "Ditsch, Lindower Straße, Sprengelkiez, Wedding, Mitte, Berlin, 13347, Deutschland",
"importance": 9.99999999995449e-06,
"lat": "52.54274275",
"licence": "Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright",
"lon": "13.36690305710228",
"name": "Ditsch",
"osm_id": 437595031,
"osm_type": "way",
"place_id": 204751033,
"place_rank": 30,
"type": "bakery"
}
*/

class Place {
  const Place({
    required this.name,
    required this.display_name,
  });

  factory Place.fromJson(Map<String, dynamic> map) {
    return Place(
      name: map['name'] as String? ?? '',
      display_name: map['display_name'] as String? ?? '',
    );
  }

  final String name;
  final String display_name;
}
