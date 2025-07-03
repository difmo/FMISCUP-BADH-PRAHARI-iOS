class StationData {
  String _ID = '';
  String _Gauge = '';
  String _Discharge = '';
  String _TodayRain = '';
  String _DataDate = '';
  String _DataTime = '';
  String _StationID = '';
  String _isSync = '';

  // Constructor
  StationData({
    required String id,
    required String gauge,
    required String discharge,
    required String todayRain,
    required String dataDate,
    required String dataTime,
    required String stationID,
    required String isSync,
  }) {
    _ID = id;
    _Gauge = gauge;
    _Discharge = discharge;
    _TodayRain = todayRain;
    _DataDate = dataDate;
    _DataTime = dataTime;
    _StationID = stationID;
    _isSync = isSync;
  }
  StationData.server({
    required String id,
    required String gauge,
    required String discharge,
    required String todayRain,
    required String dataDate,
    required String dataTime,
    required String stationID,
  }) {
    _ID = id;
    _Gauge = gauge;
    _Discharge = discharge;
    _TodayRain = todayRain;
    _DataDate = dataDate;
    _DataTime = dataTime;
    _StationID = stationID;
  }

  // Getters
  String get id => _ID;
  String get gauge => _Gauge;
  String get discharge => _Discharge;
  String get todayRain => _TodayRain;
  String get dataDate => _DataDate;
  String get dataTime => _DataTime;
  String get stationID => _StationID;

  String get isSync => _isSync;

  // Setters
  set id(String value) => _ID = value;

  set gauge(String value) => _Gauge = value;

  set discharge(String value) => _Discharge = value;

  set todayRain(String value) => _TodayRain = value;

  set dataDate(String value) => _DataDate = value;

  set dataTime(String value) => _DataTime = value;

  set stationID(String value) => _StationID = value;

  set isSync(String value) => _isSync = value;

  // Convert to Map (for JSON or multipart/form)
  Map<String, String> toMap() {
    return {
      'ID': _ID,
      'Gauge': _Gauge,
      'Discharge': _Discharge,
      'TodayRain': _TodayRain,
      'DataDate': _DataDate,
      'DataTime': _DataTime,
      'StationID': _StationID,
      'isSync': _isSync,
    };
  }

  // Optional: Create from JSON
  factory StationData.fromJson(Map<String, dynamic> json) {
    return StationData.server(
      id: json['ID'] ?? '',
      gauge: json['Gauge'] ?? '',
      discharge: json['Discharge'] ?? '',
      todayRain: json['TodayRain'] ?? '',
      dataDate: json['DataDate'] ?? '',
      dataTime: json['DataTime'] ?? '',
      stationID: json['StationID'] ?? '',
    );
  }
}
