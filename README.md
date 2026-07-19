# Lexia

Flutter client for learning Destination vocabulary — flashcards, exams, and AI coach.

> Brand UI: **Lexia** · Package / DB: `worduno` · **Báo cáo tổng thể:** [docs/Lexia_Project_Report.md](docs/Lexia_Project_Report.md)

## Architecture

MVVM by feature:

```
lib/
├── app/          # Shell, Navigator 2.0, DI
├── core/         # Network, database, theme, TTS, widgets
├── shared/       # vocabulary (API + SQLite cache), word_state (local)
└── features/     # home, learning, exam, coach, dashboard, onboarding, profile
```

| Layer | Responsibility | Example |
|-------|----------------|---------|
| **presentation** | Page + ViewModel | `LevelListPage`, `LevelListViewModel` |
| **application** | Use cases / services | `IExamService`, `ExamServiceImpl` |
| **domain** | Entities + repository contracts | `Term`, `IVocabularyRepository` |
| **data** | DTO, Mapper, DataSource, Repository impl | API / SQLite |

### Rules

- Page does **not** call API directly.
- ViewModel does **not** use DTO.
- Service / Repository always split **interface + impl**.
- Do **not** import another feature's `data/` folder.

## Stack

- **State:** `provider` + `ChangeNotifier`
- **DI:** `get_it`
- **HTTP:** `dio` (+ `connectivity_plus`)
- **Local DB:** `sqflite` — file `worduno.db`, schema **v6**
- **Prefs:** `shared_preferences` (onboarding, streak, last unit, banners)
- **Navigation:** Navigator 2.0
- **TTS:** `flutter_tts` via `ITtsService`

## Backend

Vocabulary API: [destination-vocabulary-api.onrender.com/docs](https://destination-vocabulary-api.onrender.com/docs)

| Endpoint | Purpose |
|----------|---------|
| `GET /api` | Levels |
| `GET /api/{level}/units` | Units |
| `GET /api/{level}/units/{unit_name}` | Terms |
| `POST /api/exam/cloze` | Cloze AI |
| `POST /api/exam/evaluate-sentence` | Sentence Writing AI |
| `POST /api/coach/explain` | Coach explain |
| `POST /api/coach/evaluate` | Coach evaluate |

Vocabulary is **cache-first** (SQLite tables `vocabulary_*`), then fetched from API. Progress / exam / coach history remain local-only.

## Getting started

```bash
flutter pub get
flutter run
```

First run creates `worduno.db` (word state, exam history, coach feedback, vocabulary cache). First launch may show onboarding (`has_seen_onboarding`).

## Feature map

| Feature | Scope |
|---------|-------|
| `onboarding` | First-run slides (SharedPreferences) |
| `home` | Gateway: streak, daily learn, continue last unit, level progress |
| Study browse | Level → Unit → Term (on **Học tập** tab) |
| `learning` | Full-screen flashcard session |
| `exam` | Config, session, result; history via Profile |
| `coach` | Explain → write → evaluate; history via Profile |
| `dashboard` | Progress & stats |
| `profile` | Hub → Exam History / Coach History |
| `shared/word_state` | Star / Know / Learning |
| `shared/vocabulary` | API + local cache |

## Navigation

Bottom tabs: **Trang chủ · Học tập · Thống kê · Hồ sơ**

```
Trang chủ     → Home gateway
Học tập       → Level → Unit → Term → Learn / Exam / Coach
Thống kê      → Dashboard
Hồ sơ         → Exam History | Coach History (+ nested coach routes)
```

Deep links: `/`, `/study`, `/dashboard`, `/profile`.

Use `AppNavigationNotifier` (via `context.read`) — do not call `Navigator.push` from Pages unless extending the router.

## Documentation

| Document | Description |
|----------|-------------|
| [docs/Lexia_Project_Report.md](docs/Lexia_Project_Report.md) | Báo cáo tổng thể nộp / trình bày |
| [docs/report.md](docs/report.md) | Báo cáo kỹ thuật (kiến trúc, UC, ERD) |
| [docs/specs.md](docs/specs.md) | SRS |
| [docs/Lexia_UI_Text_Spec.md](docs/Lexia_UI_Text_Spec.md) | UI text / sitemap |
| [docs/huong_dan_doc_hieu_du_an_mvvm.md](docs/huong_dan_doc_hieu_du_an_mvvm.md) | Hướng dẫn đọc code MVVM |
| [docs/test_report.md](docs/test_report.md) | Báo cáo kiểm thử |
| [docs/manual_test_checklist.txt](docs/manual_test_checklist.txt) | Checklist test thủ công |

## Tests

```bash
flutter test
```

Coverage: Learn session, word-state persistence, vocabulary cache, exam grading/flow, navigation, widget flows.
