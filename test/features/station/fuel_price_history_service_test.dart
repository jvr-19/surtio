import 'package:flutter_test/flutter_test.dart';
import 'package:surtio/features/map/data/models/fuel_station.dart';
import 'package:surtio/features/station/data/services/fuel_price_history_service.dart';

void main() {
  setUp(FuelPriceHistoryService.clearMemoryCacheForTesting);

  test('reuses past daily values from the session cache', () async {
    final source = _FakeHistoryDataSource();
    final service = FuelPriceHistoryService(
      dataSource: source,
      now: () => DateTime(2026, 9, 29),
    );

    final first = await service.fetchHistory(
      station: _station,
      fuelType: FuelType.gasoline95,
      period: FuelPriceHistoryPeriod.sevenDays,
    );
    final second = await service.fetchHistory(
      station: _station,
      fuelType: FuelType.gasoline95,
      period: FuelPriceHistoryPeriod.sevenDays,
    );

    expect(first, hasLength(7));
    expect(second, hasLength(7));
    expect(source.calls, 7);
  });

  test('keeps fuel type as part of the cache key', () async {
    final source = _FakeHistoryDataSource();
    final service = FuelPriceHistoryService(
      dataSource: source,
      now: () => DateTime(2026, 9, 29),
    );

    await service.fetchHistory(
      station: _station,
      fuelType: FuelType.gasoline95,
      period: FuelPriceHistoryPeriod.sevenDays,
    );
    await service.fetchHistory(
      station: _station,
      fuelType: FuelType.diesel,
      period: FuelPriceHistoryPeriod.sevenDays,
    );

    expect(source.calls, 14);
  });

  test('bounds one-year requests instead of downloading every day', () async {
    final source = _FakeHistoryDataSource(
      price: (date) => 1.4 + (date.day % 5) / 100,
    );
    final service = FuelPriceHistoryService(
      dataSource: source,
      now: () => DateTime(2026, 9, 29),
    );

    final points = await service.fetchHistory(
      station: _station,
      fuelType: FuelType.gasoline95,
      period: FuelPriceHistoryPeriod.oneYear,
    );

    expect(points, isNotEmpty);
    expect(source.calls, lessThanOrEqualTo(40));
    expect(source.calls, lessThan(365));
  });
}

const _station = FuelStation(
  id: '123',
  name: 'Estación de prueba',
  address: 'Calle Prueba 1',
  municipality: 'Prueba',
  municipalityId: '99',
  province: 'Prueba',
  latitude: 28.1,
  longitude: -15.4,
  schedule: '',
  gasoline95Price: 1.5,
  dieselPrice: 1.4,
);

class _FakeHistoryDataSource implements FuelPriceHistoryDataSource {
  _FakeHistoryDataSource({double Function(DateTime)? price})
    : _price = price ?? ((_) => 1.5);

  final double Function(DateTime) _price;
  int calls = 0;

  @override
  Future<double?> fetchPrice({
    required FuelStation station,
    required FuelType fuelType,
    required DateTime date,
  }) async {
    calls++;
    return _price(date);
  }

  @override
  void dispose() {}
}
