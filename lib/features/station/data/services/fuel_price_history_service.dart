import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../map/data/models/fuel_station.dart';
import '../models/fuel_price_history_point.dart';

enum FuelPriceHistoryPeriod {
  sevenDays(label: '7 días', days: 7, anchorStepDays: 1, maxRequests: 7),
  thirtyDays(label: '30 días', days: 30, anchorStepDays: 3, maxRequests: 20),
  threeMonths(label: '3 meses', days: 90, anchorStepDays: 7, maxRequests: 24),
  oneYear(label: '1 año', days: 365, anchorStepDays: 14, maxRequests: 40);

  const FuelPriceHistoryPeriod({
    required this.label,
    required this.days,
    required this.anchorStepDays,
    required this.maxRequests,
  });

  final String label;
  final int days;
  final int anchorStepDays;
  final int maxRequests;
}

abstract class FuelPriceHistoryDataSource {
  Future<double?> fetchPrice({
    required FuelStation station,
    required FuelType fuelType,
    required DateTime date,
  });

  void dispose();
}

class OfficialFuelPriceHistoryDataSource implements FuelPriceHistoryDataSource {
  OfficialFuelPriceHistoryDataSource({http.Client? client})
    : _client = client ?? http.Client();

  static const _baseUrl =
      'https://sedeaplicaciones.minetur.gob.es/'
      'ServiciosRESTCarburantes/PreciosCarburantes/'
      'EstacionesTerrestresHist/FiltroMunicipio';

  final http.Client _client;

  @override
  Future<double?> fetchPrice({
    required FuelStation station,
    required FuelType fuelType,
    required DateTime date,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/${_formatApiDate(date)}/${station.municipalityId}',
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Historical prices returned HTTP ${response.statusCode}',
        uri,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final rawStations =
        decoded['ListaEESSPrecio'] as List<dynamic>? ?? const [];

    for (final rawStation in rawStations) {
      if (rawStation is! Map<String, dynamic> ||
          rawStation['IDEESS']?.toString() != station.id) {
        continue;
      }

      return _parsePrice(rawStation[_priceField(fuelType)]);
    }

    return null;
  }

  static String _formatApiDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }

  static String _priceField(FuelType fuelType) {
    return switch (fuelType) {
      FuelType.gasoline95 => 'Precio Gasolina 95 E5',
      FuelType.gasoline98 => 'Precio Gasolina 98 E5',
      FuelType.diesel => 'Precio Gasoleo A',
      FuelType.premiumDiesel => 'Precio Gasoleo Premium',
      FuelType.lpg => 'Precio Gases licuados del petróleo',
    };
  }

  static double? _parsePrice(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return double.tryParse(text.replaceAll(',', '.'));
  }

  @override
  void dispose() => _client.close();
}

class FuelPriceHistoryService {
  FuelPriceHistoryService({
    FuelPriceHistoryDataSource? dataSource,
    DateTime Function()? now,
  }) : _dataSource = dataSource ?? OfficialFuelPriceHistoryDataSource(),
       _now = now ?? DateTime.now;

  final FuelPriceHistoryDataSource _dataSource;
  final DateTime Function() _now;

  // Shared by every detail screen for the lifetime of the application process.
  static final Map<_HistoryCacheKey, FuelPriceHistoryPoint?> _memoryCache = {};
  static final Map<_HistoryCacheKey, Future<FuelPriceHistoryPoint?>>
  _requestsInFlight = {};

  Future<List<FuelPriceHistoryPoint>> fetchHistory({
    required FuelStation station,
    required FuelType fuelType,
    required FuelPriceHistoryPeriod period,
  }) async {
    if (station.municipalityId.isEmpty) {
      return [];
    }

    final today = _dateOnly(_now());
    final end = today.subtract(const Duration(days: 1));
    final start = end.subtract(Duration(days: period.days - 1));
    final requestedDates = _anchorDates(start, end, period.anchorStepDays);
    final pointsByDate = <DateTime, FuelPriceHistoryPoint?>{};

    await _loadDates(
      dates: requestedDates,
      station: station,
      fuelType: fuelType,
      pointsByDate: pointsByDate,
    );

    // Refine only intervals where sampled prices changed. This spends the
    // remaining request budget around relevant changes instead of uniformly
    // discarding detail. Seven days already requests every date.
    while (pointsByDate.length < period.maxRequests) {
      final candidates = _refinementCandidates(pointsByDate)
          .where((date) => !pointsByDate.containsKey(date))
          .take(period.maxRequests - pointsByDate.length)
          .toList();
      if (candidates.isEmpty) {
        break;
      }
      await _loadDates(
        dates: candidates,
        station: station,
        fuelType: fuelType,
        pointsByDate: pointsByDate,
      );
    }

    final points =
        pointsByDate.values.whereType<FuelPriceHistoryPoint>().toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  Future<void> _loadDates({
    required List<DateTime> dates,
    required FuelStation station,
    required FuelType fuelType,
    required Map<DateTime, FuelPriceHistoryPoint?> pointsByDate,
  }) async {
    // Small batches avoid flooding the official endpoint on long periods.
    for (var start = 0; start < dates.length; start += 4) {
      final end = (start + 4).clamp(0, dates.length);
      final batch = dates.sublist(start, end);
      final results = await Future.wait(
        batch.map(
          (date) =>
              _fetchPoint(station: station, fuelType: fuelType, date: date),
        ),
      );
      for (var index = 0; index < batch.length; index++) {
        pointsByDate[batch[index]] = results[index];
      }
    }
  }

  Future<FuelPriceHistoryPoint?> _fetchPoint({
    required FuelStation station,
    required FuelType fuelType,
    required DateTime date,
  }) async {
    final key = _HistoryCacheKey(station.id, fuelType, date);
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    final existingRequest = _requestsInFlight[key];
    if (existingRequest != null) {
      return existingRequest;
    }

    final request = _dataSource
        .fetchPrice(station: station, fuelType: fuelType, date: date)
        .then((price) {
          final point = price == null
              ? null
              : FuelPriceHistoryPoint(date: date, price: price);
          _memoryCache[key] = point;
          return point;
        });
    _requestsInFlight[key] = request;

    try {
      return await request;
    } finally {
      _requestsInFlight.remove(key);
    }
  }

  static List<DateTime> _anchorDates(
    DateTime start,
    DateTime end,
    int stepDays,
  ) {
    final dates = <DateTime>[];
    for (
      var date = start;
      !date.isAfter(end);
      date = date.add(Duration(days: stepDays))
    ) {
      dates.add(date);
    }
    if (dates.isEmpty || dates.last != end) {
      dates.add(end);
    }
    return dates;
  }

  static List<DateTime> _refinementCandidates(
    Map<DateTime, FuelPriceHistoryPoint?> values,
  ) {
    final dates = values.keys.toList()..sort();
    final candidates = <({DateTime date, double relevance})>[];

    for (var index = 0; index < dates.length - 1; index++) {
      final leftDate = dates[index];
      final rightDate = dates[index + 1];
      final gap = rightDate.difference(leftDate).inDays;
      final left = values[leftDate];
      final right = values[rightDate];
      if (gap <= 1 || left == null || right == null) {
        continue;
      }
      final change = (right.price - left.price).abs();
      if (change < 0.0005) {
        continue;
      }
      candidates.add((
        date: leftDate.add(Duration(days: gap ~/ 2)),
        relevance: change,
      ));
    }

    candidates.sort((a, b) => b.relevance.compareTo(a.relevance));
    return candidates.map((candidate) => candidate.date).toList();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static void clearMemoryCacheForTesting() {
    _memoryCache.clear();
    _requestsInFlight.clear();
  }

  void dispose() => _dataSource.dispose();
}

class _HistoryCacheKey {
  const _HistoryCacheKey(this.stationId, this.fuelType, this.date);

  final String stationId;
  final FuelType fuelType;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is _HistoryCacheKey &&
      stationId == other.stationId &&
      fuelType == other.fuelType &&
      date == other.date;

  @override
  int get hashCode => Object.hash(stationId, fuelType, date);
}
