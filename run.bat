@echo off
REM Corre la app con la URL del Worker ya configurada.
REM Si cambias de Worker, actualiza la URL de abajo.

flutter run -d chrome --dart-define=STORAGE_WORKER_URL=https://vowly-storage-worker.vowly-storage-worker.workers.dev