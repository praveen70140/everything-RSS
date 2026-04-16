# Everything RSS UX Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce cognitive load and make Everything RSS feel like a coherent reader by fixing drawer overload, technical setup flows, destructive action recovery, editorial typography, and media-player visual consistency.

**Architecture:** Keep the existing Flutter/Riverpod structure and improve UX in focused passes. Extract small helpers only where they remove repeated validation, error copy, or card typography logic. Avoid a broad navigation rewrite; restructure the drawer and settings flow inside the current screen model first.

**Tech Stack:** Flutter, Dart, Riverpod, Material widgets, existing `AppColors`, existing local database/repository services, current widget tests.

---

## Scope

Fix all critique findings:

- Drawer overload and weak progressive disclosure.
- Technical/permissive feed, parser, and third-party server setup.
- Inconsistent destructive actions and raw error recovery.
- Inconsistent content-card typography and spacing.
- Mini player visual mismatch.
- Empty/loading/error states that do not guide next action.

Do not redesign the product identity from scratch. Preserve core workflows: feed reading, feed selection, saved items, archive/to-do triage, discovery, OPML import/export, media playback, reader mode, and downloads.

## File Map

- Modify `lib/features/feeds/presentation/widgets/feeds_drawer.dart`
  - Split reader navigation from management actions.
  - Improve add-feed/add-folder sheets.
  - Improve discovery/server dependency messaging.
  - Add plain labels and reduce all-caps noise.

- Modify `lib/features/feeds/presentation/pages/feeds_page.dart`
  - Improve empty/error states.
  - Keep swipe triage undo.
  - Align feed title/copy casing with calmer reader tone.

- Modify `lib/features/feeds/presentation/pages/saved_feeds_page.dart`
  - Add undo for saved-item deletion.
  - Improve empty states.
  - Reuse normalized card behavior.

- Modify `lib/features/feeds/presentation/pages/third_party_servers_page.dart`
  - Add URL validation, server test feedback, delete confirmation/undo.
  - Rewrite technical copy for proxy types.

- Modify `lib/features/feeds/presentation/pages/app_settings_page.dart`
  - Validate Mercury Parser URL.
  - Rename/reframe reader parser setup as advanced full-text extraction.
  - Improve save/error feedback.

- Modify `lib/features/feeds/presentation/pages/feed_settings_page.dart`
  - Align settings typography and save feedback with the rest of the app.

- Modify `lib/features/feeds/presentation/pages/article_detail_page.dart`
  - Improve reader-mode errors and recovery.
  - Keep typography controls but simplify labels.

- Modify content cards:
  - `lib/features/feeds/presentation/widgets/content_cards/article_tile.dart`
  - `lib/features/feeds/presentation/widgets/content_cards/dense_article_tile.dart`
  - `lib/features/feeds/presentation/widgets/content_cards/photo_card.dart`
  - `lib/features/feeds/presentation/widgets/content_cards/video_card.dart`
  - `lib/features/feeds/presentation/widgets/content_cards/audio_tile.dart`
  - `lib/features/feeds/presentation/widgets/content_cards/download_button.dart`

- Modify `lib/features/media/presentation/widgets/mini_player.dart`
  - Use `AppColors` and calmer surface treatment.
  - Add tooltips where missing.

- Consider creating:
  - `lib/features/feeds/presentation/utils/url_validation.dart`
  - `lib/features/feeds/presentation/widgets/feedback/empty_state.dart`
  - `lib/features/feeds/presentation/widgets/feedback/error_state.dart`
  - `lib/features/feeds/presentation/widgets/content_cards/feed_card_styles.dart`

- Update/add tests:
  - `test/widget_test.dart`
  - Existing focused tests if relevant: `test_article_detail.dart`, `test_selection.dart`, `test_selection_api.dart`
  - Add widget tests only where behavior is stable and testable without network.

## Task 1: Add Shared UX Helpers

- [ ] Create `url_validation.dart` with helpers for:
  - `normalizeHttpUrl(String input)`
  - `isValidHttpUrl(String input)`
  - `isLikelyFeedUrl(String input)`
  - Return plain validation messages: empty input, missing host, unsupported scheme.

- [ ] Create reusable empty/error widgets:
  - `EmptyState(icon, title, message, actionLabel, onAction)`
  - `ErrorState(icon, title, message, actionLabel, onAction, details)`
  - Keep details optional and collapsed/secondary so raw errors do not dominate.

- [ ] Add unit tests for URL validation:
  - Empty string fails.
  - `example.com/feed.xml` normalizes to `https://example.com/feed.xml`.
  - `ftp://example.com/feed.xml` fails.
  - `https://rsshub.app` passes.

- [ ] Run:
  - `flutter test test/widget_test.dart`
  - `dart analyze`

## Task 2: Rework Drawer Information Architecture

- [ ] In `feeds_drawer.dart`, reorganize the drawer into these sections:
  - Header: app/feed navigation identity.
  - Reading: All Feeds, To Do, Archive.
  - Sources: feed/folder list.
  - Manage: Add Feed, Add Folder, Discover, Third-Party Servers, App Settings.

- [ ] Keep only the primary reading actions visually prominent.

- [ ] Move Add Feed/Add Folder from equal top-level button blocks into a management row or list section lower in the drawer.

- [ ] Replace shouty labels:
  - `FEEDS` -> `Feeds`
  - `FEED` -> `Feed`
  - `FOLDER` -> `Folder`
  - `TO-DO` -> `To do`
  - `ARCHIVE` -> `Archive`

- [ ] Add a compact section label style instead of repeated all-caps labels.

- [ ] Keep feed drag/drop behavior intact and verify folders still expand and persist.

- [ ] Widget/manual checks:
  - Open drawer.
  - Select All Feeds.
  - Select a feed.
  - Open saved To Do and Archive.
  - Add a folder.
  - Drag a feed into and out of a folder.

## Task 3: Clarify Feed, Discovery, and Server Setup

- [ ] Update Add Feed sheet:
  - Validate URL before closing the sheet.
  - Show inline error text for invalid URL.
  - Use copy: `Feed URL`, `Paste an RSS, Atom, or website feed link.`
  - Keep success behavior: save feed, clear field, load the feed.

- [ ] Update Discover flow:
  - If no third-party servers exist, show a dialog or bottom sheet with direct action `Add server` instead of a snackbar-only dead end.
  - Rename `Discover / Search` to `Discover feeds`.
  - Explain server selection in one sentence.

- [ ] Update Third-Party Servers:
  - Rename screen copy around server types:
    - `yt-dlp-RSS Proxy` -> `Video/audio feed server`
    - `RSSHub Proxy` -> `RSSHub source server`
  - Keep stored values (`ytdlp`, `rsshub`) unchanged.
  - Validate URL before network request.
  - Show progress while testing/saving.
  - For network failure, show actionable copy: `Could not reach this server. Check the URL and try again.`

- [ ] Update App Settings:
  - Rename `Mercury Parser URL` section to `Full-text extraction`.
  - Mark it as advanced copy without hiding it.
  - Validate URL before saving.
  - Give success and failure snackbars with specific next action.

- [ ] Tests:
  - Unit test URL validation helpers.
  - Widget test Add Feed invalid URL keeps sheet open and shows error if feasible.

## Task 4: Standardize Destructive Action Recovery

- [ ] In `saved_feeds_page.dart`, change swipe delete to optimistic remove with undo snackbar:
  - Remove item from local state immediately.
  - Show `Removed from To do` or `Removed from Archive`.
  - If undo tapped, restore local item and do not delete from DB.
  - If snackbar closes without undo, delete from DB.

- [ ] In `third_party_servers_page.dart`, protect server deletion:
  - Prefer confirmation dialog for server delete because it affects discovery infrastructure.
  - Dialog copy: `Remove this server? Discovery that depends on it will stop working.`

- [ ] In `download_button.dart`, keep confirm dialog for deleting downloaded files.
  - Update copy to clarify it removes the local file, not the feed item.

- [ ] In `feeds_page.dart`, keep existing archive/to-do undo behavior.
  - Normalize snackbar copy with saved-item removal.

- [ ] Manual checks:
  - Swipe current feed item to To do, undo.
  - Swipe saved item delete, undo.
  - Swipe saved item delete, wait, confirm it is gone.
  - Delete a server and cancel.
  - Delete a downloaded file and cancel.

## Task 5: Improve Error and Empty States

- [ ] Replace `No items found in feed.` with:
  - Title: `No items here`
  - Message: `Refresh this feed or choose another source from the drawer.`
  - Action: `Refresh`

- [ ] Replace `No saved items here.` with status-specific states:
  - To do: `Nothing saved for later`
  - Archive: `Archive is empty`
  - Include guidance about swiping feed items.

- [ ] Replace raw feed load error presentation:
  - Title: `Feed could not load`
  - Message: `Check the feed URL or try refreshing.`
  - Action: `Try again`
  - Details: raw error in secondary text only if needed.

- [ ] Replace Reader Mode errors:
  - Title: `Full text unavailable`
  - Message: `The extraction server could not fetch this article. You can continue with the RSS summary or open the original page.`
  - Actions: `Show summary`, `Open original`

- [ ] Verify error state contrast and touch targets.

## Task 6: Normalize Feed Card Typography

- [ ] Create shared card style constants in `feed_card_styles.dart`:
  - Metadata style.
  - Main title style.
  - Dense title style.
  - Subtitle style.
  - Horizontal and vertical spacing.

- [ ] Remove negative `letterSpacing: -1` from feed-card titles.

- [ ] Keep visual distinction:
  - Main text/article/photo/video title: 22-24px equivalent.
  - Dense article title: 18-20px equivalent.
  - Metadata: avoid 10px; use at least 12px where possible.

- [ ] Apply styles to:
  - `ArticleTile`
  - `DenseArticleTile`
  - `PhotoCard`
  - `VideoCard`
  - `AudioTile`

- [ ] Keep media-specific layout:
  - Photos and videos can keep image/thumbnail treatment.
  - Audio can keep playback affordance.

- [ ] Manual visual checks:
  - Mixed feed with article, image, video, audio.
  - Read vs unread states.
  - Long titles and long author names.

## Task 7: Polish Mini Player

- [ ] Replace `Theme.of(context).cardColor` with `AppColors.surface0` or `AppColors.mantle` depending on contrast.

- [ ] Replace generic grey/black styling with `AppColors` tokens.

- [ ] Add missing tooltips:
  - Play/pause.
  - Close player.
  - Open full player if exposed as a button or semantic label.

- [ ] Keep layout stable:
  - Height remains 72.
  - Artwork remains 48x48.
  - Text remains single-line ellipsis.

- [ ] Verify both audio and video mini player states:
  - Loading.
  - Playing.
  - Paused.
  - No artwork.

## Task 8: Reader and Settings Tone Pass

- [ ] In `article_detail_page.dart`, simplify the RSS-summary notice:
  - `Showing RSS summary. Use Reader Mode for full text.`

- [ ] Rename `Typography & Accessibility` to `Reading settings`.

- [ ] Keep font size and font family controls.

- [ ] In `feed_settings_page.dart`, align app bar/background/text styling with `AppTheme` and `AppColors`.

- [ ] Reduce repetitive snackbars for settings toggles if they fire too often.
  - Save silently for immediate toggles.
  - Show confirmation only for explicit save actions.

## Task 9: Verification Pass

- [ ] Run static checks:
  - `dart format lib test`
  - `dart analyze`
  - `flutter test`

- [ ] Run targeted manual flows on a device/emulator or desktop:
  - Empty feed.
  - Bad feed URL.
  - Valid feed URL.
  - Bad third-party server URL.
  - Valid RSSHub server URL.
  - Reader mode with missing parser.
  - Swipe To do/Archive with undo.
  - Saved item delete with undo.
  - Audio and video mini player.
  - Light and dark mode.

- [ ] Re-run critique:
  - `npm exec --yes --package=impeccable -- impeccable --json --fast lib/features/feeds/presentation`
  - Manual review against the original critique checklist.

## Expected Outcome

- Drawer first impression becomes reader-focused instead of admin-heavy.
- Setup flows prevent obvious broken states and explain technical terms.
- Destructive actions follow consistent rules.
- Feed cards read as one editorial system.
- Mini player feels native to the app.
- Empty and error states tell users what to do next.

## Suggested Commit Sequence

1. `feat: add feed url validation and feedback states`
2. `refactor: simplify feed drawer structure`
3. `feat: clarify feed and server setup flows`
4. `fix: standardize destructive action recovery`
5. `feat: improve empty and error states`
6. `style: normalize feed card typography`
7. `style: align mini player with app theme`
8. `test: cover ux validation helpers`
