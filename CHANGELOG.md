# Changelog

## 2.0.0

### New
- **Bottom navigation** with Home, Statistics and Settings tabs. Tabs keep their state and fade/scale between each other.
- **Streaks**: a day counts once you finish at least one mala on the active counter. Today's chanting can still save the streak until midnight. Current and best streaks show on Home and Statistics.
- **Daily goals** per counter (in malas), with an animated progress ring on Home and a goal bar on the counter screen.
- **Compact calendar**: Home shows just this week by default; tap the month name to expand to the full month. Days where you met your goal are tinted.
- **Statistics tab**: 7-day bar chart and 30-day line chart (fl_chart), totals, malas, daily average, best day, streaks, and a per-counter breakdown.
- **Volume button counting** (Android): volume up adds one, volume down removes one, without changing the volume.
- **Keep screen on** while the counter is open (wakelock_plus).
- **Counter symbols**: each counter gets a symbol (Om, Shri, Ganesha, Shiva, Krishna and more) and a colour, shown in lists, on Home and on the counter screen.
- **AMOLED black** theme option.
- **Onboarding**: a three-page introduction on first launch (can be replayed from Settings).
- Opening animation, back-button exit animation, and Hero transitions between Home and the counter.

### Improved
- One design system (`lib/theme/app_theme.dart`) for spacing, radii, typography and component styles across every screen, sheet and dialog.
- Reset day, delete counter and restore backup now ask for confirmation.
- Animations respect the system "reduce motion" setting.

### Fixed
- The Mantra, Conch and Damru sounds pointed at audio files that don't exist. Damru now uses `drum.mp3`; the other two were removed (saved choices fall back to Bell).
- Calendar cells no longer overflow when many counters are logged on the same day.
- Replaced the default widget test (which did not compile) with streak and data-migration tests.

### Data
- Existing counters, history and backups load unchanged. Counters keep their v1 calendar colour and start with the Om symbol and a 1-mala goal.
