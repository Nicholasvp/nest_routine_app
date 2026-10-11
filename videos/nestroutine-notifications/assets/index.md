# Sourced assets — NestRoutine notifications

No external search or generation: every asset is user-supplied and was copied from the app repo (`../../assets/`). Nothing here was generated, cut out, or recolored.

| Role             | Frozen path                        | Kind         | Provenance                                                          | Treatment |
| ---------------- | ---------------------------------- | ------------ | ------------------------------------------------------------------- | --------- |
| home screen      | `assets/screenshots/home.png`      | app UI       | copied from `../../assets/screenshots/home.png`                      | none      |
| sleep screen     | `assets/screenshots/sleep.png`     | app UI       | copied from `../../assets/screenshots/sleep.png`                     | none      |
| feed screen      | `assets/screenshots/feed.png`      | app UI       | copied from `../../assets/screenshots/feed.png`                      | none      |
| diaper screen    | `assets/screenshots/diaper.png`    | app UI       | copied from `../../assets/screenshots/diaper.png`                    | none      |
| brand mark       | `assets/nest_routine_logo.png`     | logo         | copied from `../../assets/nest_routine_logo.png`                     | none      |
| Montserrat 400-800 | `assets/fonts/montserrat-*.woff2` | webfont      | Google Fonts latin subsets, downloaded and shipped locally for `@font-face` | none |

Unused from the repo: `assets/screenshots/history.png` (no beat needed a fourth screen).

## Asset notes (measured, not assumed)

- All four screenshots are **1206x2622** device captures. They are shown pixel-exact at
  **620x1348** inside a 624x1352 phone frame (the extra 4px is the frame's 2px rim, so the
  inner screen keeps the source aspect with zero crop or stretch).
- `nest_routine_logo.png` is **400x400 and fully opaque** — it carries its own baked purple
  gradient square. It is never cut out: it is used whole as the notification app badge
  (64x64, radius 18) and as the closing wordmark tile (96x96, radius 26).
- The badge is repeated in both notification cards and the lockup. Only the four screenshots
  are `<img>` nodes; the two repeated badge instances are CSS `background-image`, so media
  discovery never sees duplicate nodes (`duplicate_media_discovery_risk`).
- No SVG/vector logo source exists in the repo, so there is no draw-on / vectorize path.
- Copy is the app's real English notification strings (`lib/providers/notification_provider.dart`):
  "Nap time!" / "Baby may need to sleep in 15 minutes" and "Sleep window closing!" /
  "Baby may get overtired." — the notification times (6:45 PM → 7:02 PM) are authored to be
  consistent with a 15-minute head start.
