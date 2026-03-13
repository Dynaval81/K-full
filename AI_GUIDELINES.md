# AI_GUIDELINES.md — Knoty (HAI3 Canon v3 — FINAL)

## Что такое Knoty
Knoty — образовательный мессенджер для школьников Германии.
Платформа: Android (MVP). iOS — следующий этап.
Все данные на немецких серверах. Полное соответствие GDPR обязательно.
Веб-панель администратора: Knoty Admin (отдельный веб-проект, не Flutter).

---

## Стек и архитектура

### Framework
- Flutter (Stable channel), только Android для MVP.

### State Management
- ТОЛЬКО `provider`. Riverpod, bloc, get_it, signals — ЗАПРЕЩЕНЫ.

### Navigation
- PageView + BottomNavigationBar, свайпы между 4-5 вкладками.

### Feature-first архитектура
```
lib/
  features/
    auth/          ← регистрация, логин, pending screen
    messenger/     ← личные чаты + личные группы + классовые группы
    schedule/      ← расписание (демо-заглушка v1)
    ai_assistant/  ← ИИ помощник (interface-based)
    password_vault/← хранилище паролей (только fullyVerified)
    school/        ← школьные группы, классы
    admin/         ← управление (только schoolAdmin/appAdmin)
  core/
    models/        ← UserModel, UserRole, VerificationLevel, UserLimits
    services/      ← PermissionService, UsageTrackingService, AiService (abstract)
    utils/         ← FormatUtils (DE форматы), StorageMigrationUtils
  presentation/
    widgets/       ← Atomic Design: atoms / molecules / organisms
```

### Feature Toggling
- PermissionService определяет видимость каждого модуля.
- Заблокированные модули показываются с иконкой замка 🔒 и подписью.
- Родитель управляет лимитами ребёнка через PermissionService.

### Imports
- Только абсолютные: `package:knoty/...` Относительные — ЗАПРЕЩЕНЫ.

---

## Ролевая модель

```dart
enum UserRole { student, parent, teacher, schoolAdmin, appAdmin }

enum VerificationLevel { sandbox, schoolVerified, fullyVerified }
```

**Никаких булевых флагов** (isTeacher, isAdmin и т.п.) — только enum.

### UserRole геттеры
```dart
extension UserRoleX on UserRole {
  bool get canManageSchedule => this == teacher || this == schoolAdmin || this == appAdmin;
  bool get hasParentalControl => this == parent;
  bool get canApproveUsers    => this == schoolAdmin || this == appAdmin;
  bool get canAccessAllModules=> this == appAdmin;
  bool get canGenerateCodes   => this == schoolAdmin || this == appAdmin;
  bool get canEditGlobalSettings => this == appAdmin;
}
```

### Доступ по уровням верификации

| Модуль | sandbox | schoolVerified | fullyVerified |
|--------|---------|----------------|---------------|
| Личные чаты 1-на-1 | ✅ | ✅ | ✅ |
| Личные группы (свои контакты) | ✅ | ✅ | ✅ |
| ИИ ассистент (лимит) | ✅ (лимит) | ✅ (лимит) | ✅ (лимит родителя) |
| Школьные группы / классы | 🔒 | ✅ | ✅ |
| Расписание | 🔒 | ✅ | ✅ |
| Хранилище паролей | 🔒 | 🔒 | ✅ |

---

## Регистрация — три пути

### Путь А: Ученик с кодом (мгновенный)
1. Регистрация: имя, email, пароль
2. Вводит код `KNOTY-XXXX-XXXX`
3. Бэкенд: код валиден → verificationLevel = schoolVerified, schoolId+classId из кода
4. Код становится использованным (одноразовый)
5. Сразу открываются школьные группы и расписание

### Путь Б: Ученик без кода (ожидание)
1. Регистрация: имя, email, пароль, школа (из списка), класс
2. verificationLevel = sandbox
3. Экран: "Deine Anfrage wird geprüft. Du kannst bereits chatten."
4. school_admin или app_admin одобряет → schoolVerified
5. Push: "Dein Konto wurde aktiviert!"

### Путь В: Родитель
1. Регистрация: имя, email, пароль, роль = parent
2. Вводит ID ребёнка или получает invite на email
3. sandbox до одобрения school_admin/app_admin
4. После одобрения: fullyVerified, открывается дашборд ребёнка

### Путь Г: Учитель
1. Регистрация: имя, email, пароль, школа, предмет
2. sandbox → ручное одобрение school_admin
3. После: schoolVerified с ролью teacher

---

## Лимиты и GlobalSettings

Дефолтные лимиты настраиваются app_admin в Knoty Admin (не хардкодятся в клиенте).
Клиент получает актуальные лимиты с бэкенда при старте.

| Параметр | sandbox default | schoolVerified default |
|----------|-----------------|----------------------|
| dailyMinutes | 30 | 60 |
| dailyAiRequests | 10 | 30 |
| chatCurfewHour | null | null |

Родитель (fullyVerified) может менять лимиты для своего ребёнка.
app_admin может менять глобальные дефолты — применяются к новым пользователям.

---

## Pending State экран
Показывается если isApproved == false.
Текст: "Deine Anfrage wird vom Schuladministrator geprüft."
Показывать: имя школы, статус заявки, что уже доступно (личные чаты, базовый ИИ).
Не показывать чаты и модули пока isApproved != true (кроме личных чатов и личных групп).

---

## Очистка старых данных (StorageMigrationUtils)
При первом запуске Knoty проверить и удалить старые ключи vtalk_app:
- FlutterSecureStorage: очистить ключи с префиксом `vpn_`, `singbox_`, `server_`
- SharedPreferences: очистить `vpn_*`, `server_*`, `connection_*`
Реализовать в `core/utils/storage_migration_utils.dart`, вызвать из main.dart до инициализации.

---

## Interface-based AI сервис
```dart
abstract class AiService {
  Future<String> sendMessage(String prompt, {required String userId});
  Future<bool> checkLimit(String userId);
}
// Реализации: OpenAiService, AlephAlphaService (немецкая GDPR-совместимая модель)
```
Подменяется без изменения UI.

---

## Design System — HAI3 Airy Style (German Edition)

### Стиль
Минимализм, воздушность, много белого. Подходит детям и школе.
Шрифт: Roboto или Inter.

### Палитра
| Роль | HEX |
|------|-----|
| Background | #FFFFFF |
| Primary accent (gold) | #E6B800 |
| Danger only (red) | #CC0000 |
| Text primary | #1A1A1A |
| Text secondary | #6B6B6B |
| Surface / Card | #F5F5F5 |
| Border | #E0E0E0 |
| Success | #2E7D32 |
| Error | #B00020 |

### Размеры
- Border radius: минимум 24dp везде
- Padding внешний: минимум 20dp
- Заголовки: минимум 22px, текст: минимум 16px

### Ассеты
- Иконки: SVG только (flutter_svg). PNG/JPG — ЗАПРЕЩЕНЫ.
- Анимации: Lottie JSON
- Фото: CachedNetworkImage + fade-in

---

## GDPR-First (обязательно)
- Никакого PII в логах: ни имён, ни телефонов, ни email в debugPrint()/print()
- Логировать только: event_type, timestamp, anonymized user_id
- Все данные только на немецком сервере
- Все операции с данными пользователя только через защищённые сервисы

---

## Немецкие форматы (FormatUtils)
```dart
// Дата:    DD.MM.YYYY
// Время:   24ч — 14:30 (не 2:30 PM)
// Число:   запятая — 1,5 (не 1.5)
// Валюта:  12,50 €
```
Централизовано в `core/utils/format_utils.dart`.

---

## Локализация
- Немецкий (de) — единственный язык интерфейса
- Все строки через `AppLocalizations.of(context)!.key` — ОБЯЗАТЕЛЬНО
- Жёстко прописанный текст — ЗАПРЕЩЁН
- flutter_localizations + строгие .arb файлы (app_de.arb + app_en.arb как fallback)
- l10n.yaml настроен на пакет `knoty`
- Немецкие слова на 30-50% длиннее → всегда Flexible/Expanded в Row
- TextOverflow.ellipsis или maxLines везде
- Фиксированная ширина кнопок — ЗАПРЕЩЕНА
- Кириллица в коде и комментариях — ЗАПРЕЩЕНА

---

## Качество кода
- `dynamic` — ЗАПРЕЩЁН. Все типы явные.
- Мёртвый код и неиспользуемые импорты — удалять сразу.
- Все async — в try-catch с логами.
- Atomic Design: atoms/molecules/organisms в `presentation/widgets/`.

---

## Язык
- Код, переменные, комментарии: английский
- UI строки: немецкий (через .arb)
- AI общается с разработчиком: русский

---

## Что убрано из vtalk_app
- VPN полностью (экран, сервис, контроллер, модели, зависимости)
- Флейвор ru — только de
- Весь русскоязычный UI
- Старые ключи secure storage (очищаются при первом запуске)

---

## MVP модули (v1.0) — Android only
1. Auth (регистрация, логин, pending screen, код активации)
2. Мессенджер (личные чаты + личные группы + классовые группы)
3. ИИ ассистент (interface-based, с лимитами)
4. Расписание (демо-заглушка)
5. Хранилище паролей (только fullyVerified)

## Будущие модули
Репетиторы, Голосования, Новости школы, Кружки, iOS, Аналитика, Родительский контроль времени

---

## Дополнения по чатам (финальные)

### KN-номер
- У каждого пользователя есть KN-номер (формат: KN-XXXXXX)
- Отображается в профиле
- Используется для поиска вместо телефона/email
- Через KN-номер можно начать teacherStudent чат

### teacherStudent чат
- Учитель → ученик: напрямую (schoolVerified+)
- Ученик → учитель: через запрос на общение (требует одобрения)

### joinPolicy для групп
- `open` — вступить может любой schoolVerified
- `invite_only` — только по приглашению
- `request` — запрос + одобрение модератора
- personalGroup в sandbox: только invite_only (создатель приглашает)

### Комендантский час (chatCurfewHour)
- При наступлении часа — всё приложение блокируется экраном-заглушкой
- Текст: "Gute Nacht! Die App ist bis morgen früh gesperrt."
- Только родитель (fullyVerified) или appAdmin может установить
