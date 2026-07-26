import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/enums/attraction_sort_filter_enums.dart';

void main() {
  group('AttractionSortOrder', () {
    test('每個選項都有對應的 label', () {
      for (final order in AttractionSortOrder.values) {
        expect(order.label, isNotEmpty);
      }
    });
  });

  group('AttractionTimeSlotFilter', () {
    test('label 與 queryValue 對應所有選項（含 all）', () {
      for (final slot in AttractionTimeSlotFilter.values) {
        expect(slot.label, isNotEmpty);
        expect(
          slot.queryValue,
          isNotEmpty,
        ); // all -> 'all', confirming it's not an empty string
      }
    });

    test('fromQuery 可以還原每個合法字串', () {
      expect(
        AttractionTimeSlotFilter.fromQuery('morning'),
        AttractionTimeSlotFilter.morning,
      );
      expect(
        AttractionTimeSlotFilter.fromQuery('afternoon'),
        AttractionTimeSlotFilter.afternoon,
      );
      expect(
        AttractionTimeSlotFilter.fromQuery('evening'),
        AttractionTimeSlotFilter.evening,
      );
      expect(
        AttractionTimeSlotFilter.fromQuery('night'),
        AttractionTimeSlotFilter.night,
      );
    });

    test('fromQuery 對未知或 null 值回傳 all', () {
      expect(
        AttractionTimeSlotFilter.fromQuery(null),
        AttractionTimeSlotFilter.all,
      );
      expect(
        AttractionTimeSlotFilter.fromQuery('xxx'),
        AttractionTimeSlotFilter.all,
      );
    });
  });
}
