# ADR 0001: Local-first, no backend for the MVP

Status: accepted.

Context: free to run forever, usable on cheap phones with poor connectivity, and safe for children.

Decision: static Flutter web/Android app; content as bundled JSON; progress stored on the device.
No accounts and no personal data.

Consequences: zero hosting cost and no child-data liability. No cross-device sync or teacher dashboards
yet; add an optional sync service later behind a clean interface (ProgressStore).
