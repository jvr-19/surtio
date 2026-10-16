import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:surtio/features/map/data/services/station_cache.dart';

void main() {
  test(
    'the disk cache preserves a complete snapshot and ignores corruption',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'surtio-cache-test-',
      );
      try {
        final store = FileStationCache(directoryPath: directory.path);
        final time = DateTime.utc(2026, 10, 13, 12);
        const payload = {
          'ListaEESSPrecio': [
            {'IDEESS': '1', 'Precio Gasolina 95 E5': '1,500'},
          ],
        };
        await store.write(SavedStationData(payload, time));
        final restored = await store.read();
        expect(restored!.queriedAt, time);
        expect(restored.payload, payload);
        await File(
          '${directory.path}/official-stations-v1.json',
        ).writeAsString('{broken');
        expect(await store.read(), isNull);
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
