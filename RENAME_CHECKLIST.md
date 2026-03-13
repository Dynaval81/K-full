# Knoty — Rename & Setup Checklist

## 1. pubspec.yaml
- `name: vtalk_app` → `name: knoty`
- description → "Knoty — Bildungs-Messenger für Schüler"
- Удалить зависимости VPN: flutter_singbox, и подобные

## 2. android/app/build.gradle
- `applicationId "com.example.vtalk_app"` → `applicationId "de.knoty.app"`
- Убрать flavor `ru`, оставить только `de`

## 3. AndroidManifest.xml
- `android:label="vtalk_app"` → `android:label="Knoty"`
- Секция queries: убрать VPN-специфичное, добавить:
```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="https"/>
  </intent>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:mimeType="application/pdf"/>
  </intent>
  <intent>
    <action android:name="android.intent.action.PROCESS_TEXT"/>
    <data android:mimeType="text/plain"/>
  </intent>
</queries>
```

## 4. Android kotlin пакет
- Папку `kotlin/com/example/vtalk_app/` → `kotlin/de/knoty/app/`
- В MainActivity.kt: `package com.example.vtalk_app` → `package de.knoty.app`

## 5. Все .dart файлы
- `import 'package:vtalk_app/...` → `import 'package:knoty/...`

## 6. Удалить VPN файлы полностью
- lib/features/vpn/ или lib/screens/vpn/ — всё удалить
- vpn_controller.dart, vpn_screen.dart, vpn_panel.dart
- vpn_service.dart, server_model.dart
- Убрать VPN таб из BottomNavigationBar
- Убрать VPN зависимости из pubspec.yaml

## 7. Структура — feature-first переезд
```
lib/screens/ → lib/features/
lib/screens/auth/     → lib/features/auth/
lib/screens/chat/     → lib/features/messenger/
lib/screens/settings/ → lib/features/settings/
```
Новые папки создать:
- lib/features/schedule/
- lib/features/password_vault/
- lib/features/admin/
- lib/core/models/
- lib/core/services/
- lib/core/utils/

## 8. Новые файлы создать
- lib/core/models/user_role.dart        (UserRole enum + VerificationLevel)
- lib/core/models/user_limits.dart      (UserLimits model)
- lib/core/services/permission_service.dart
- lib/core/services/ai_service.dart     (abstract interface)
- lib/core/utils/format_utils.dart      (DE форматы)
- lib/core/utils/storage_migration_utils.dart (очистка vtalk ключей)

## 9. main.dart
- Вызвать StorageMigrationUtils.cleanLegacyKeys() до инициализации
- Получить GlobalSettings с бэкенда при старте

## 10. Splash screen
- Убрать старый vtalk splash
- Новый: логотип Knoty, белый фон #FFFFFF, акцент #E6B800

## 11. l10n настройка
- Создать l10n.yaml с `arb-dir: lib/l10n`, `template-arb-file: app_de.arb`
- Создать lib/l10n/app_de.arb (основной)
- Создать lib/l10n/app_en.arb (fallback)
- Переименовать/удалить app_ru.arb

## 12. Финальная проверка
```
flutter pub get
flutter build apk --debug
```
Убедиться что нет импортов vtalk_app и нет VPN кода.
