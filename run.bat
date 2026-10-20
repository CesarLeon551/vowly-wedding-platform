@echo off
REM Puerto fijo (5000) necesario para que el redirect_uri de Spotify OAuth
REM funcione siempre igual — Spotify exige coincidencia EXACTA de la URL.
REM SPOTIFY_CLIENT_ID no es secreto (solo el Client Secret lo es) — se
REM necesita en el cliente para armar la URL de autorización.


flutter run -d web-server --web-hostname=localhost --web-port=5000 --dart-define=STORAGE_WORKER_URL=https://vowly-storage-worker.vowly-storage-worker.workers.dev --dart-define=33b692c63a974b46840d1f491eb35b69 --dart-define=SPOTIFY_CLIENT_ID=33b692c63a974b46840d1f491eb35b69



##flutter run -d chrome --web-port=5000 --dart-define=STORAGE_WORKER_URL=https://vowly-storage-worker.vowly-storage-worker.workers.dev --dart-define=SPOTIFY_CLIENT_ID=33b692c63a974b46840d1f491eb35b69
