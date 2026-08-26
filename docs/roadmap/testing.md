# Roadmap — Testing Hardening

> Actual `grep "test(" 50` vs claimed `75`; `test/unit/card_data_extractor_test.dart:11` 3 trivial (`isNotNull`), `_stripFencesLenient:53` + `_parseLenient:89` + `_mapToCardData 16-way` untested; prompt tests only string containment.

## Plan (separate doc)

1. `card_data_extractor_roundtrip_test` — 16 JSON fixtures × `N/A` + `sparse` fallback → `CardData` → `toJson` (mirror Android `project_context:9322`).
2. `generation_prompt_manager_snapshot` + `card_prompt_manager_snapshot` goldens.
3. `web_scraper_service_dio_test` mock `ApiClient` via `DioAdapter`.
4. `football_ocr_parser_test`.
5. Lift to 75+; `flutter test --coverage` green.

