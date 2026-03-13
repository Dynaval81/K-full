# Knoty — Registration Flow (FINAL)

## Уровни верификации

| Уровень | Enum | Как получить |
|---------|------|-------------|
| Песочница | `sandbox` | Авто после регистрации без кода |
| Школьный | `schoolVerified` | Код активации ИЛИ одобрение admin |
| Полный | `fullyVerified` | Привязка родителя + одобрение admin |

---

## Что доступно в sandbox (сразу после регистрации)
✅ Личные чаты 1-на-1
✅ Личные группы (создаёт сам, добавляет своих контактов)
✅ ИИ ассистент (лимит из GlobalSettings, default 10 запросов/день)
✅ Профиль

🔒 Школьные группы — "Nach Schulverifizierung verfügbar"
🔒 Расписание — "Nach Schulverifizierung verfügbar"
🔒 Хранилище паролей — "Nach Elternverknüpfung verfügbar"

Лимит времени: из GlobalSettings (default 30 мин/день)

---

## Путь А: Ученик с кодом (мгновенный доступ)
1. Открывает приложение → экран регистрации
2. Нажимает "Ich habe einen Aktivierungscode"
3. Вводит код KNOTY-XXXX-XXXX
4. Приложение показывает: "Code gültig — Goethe Gymnasium, Klasse 5B. Stimmt das?"
5. Подтверждает → заполняет имя, email, пароль
6. Статус сразу: schoolVerified ✅
7. Школьные группы и расписание открываются мгновенно

## Путь Б: Ученик без кода (ожидание)
1. Регистрация: имя, email, пароль, выбирает школу из списка, класс
2. Статус: sandbox
3. Экран: "Deine Anfrage wird geprüft. Du kannst bereits mit Freunden chatten!"
4. school_admin или app_admin одобряет в Knoty Admin
5. Push: "Dein Konto wurde aktiviert! Willkommen in der Klasse 5B 🎉"
6. Статус: schoolVerified

## Путь В: Родитель
1. Регистрация: имя, email, пароль, роль = Elternteil
2. Вводит ID ребёнка или email-приглашение от школы
3. Статус: sandbox (видит только профиль)
4. school_admin/app_admin одобряет связку
5. Статус: fullyVerified
6. Открывается: дашборд ребёнка, управление лимитами

## Путь Г: Учитель
1. Регистрация: имя, email, пароль, роль = Lehrer, школа, предмет
2. Статус: sandbox
3. Ручное одобрение school_admin
4. Статус: schoolVerified (teacher)
5. Открывается: управление классом, расписание, модерация

---

## app_admin на старте (без школ)
Пока школ нет — app_admin заменяет school_admin:
- Видит всех pending пользователей в Knoty Admin
- Одобряет учеников (→ schoolVerified)
- Одобряет родителей и связки (→ fullyVerified)
- Генерирует активационные коды
- Настраивает GlobalSettings (лимиты песочницы и т.д.)

---

## Активационные коды
Формат: KNOTY-XXXX-XXXX (без I, O, 1, 0)
- Одноразовые
- Привязаны к школе + классу + роли
- Срок действия: настраивается в GlobalSettings (default 90 дней)
- Школа генерирует пачкой через Knoty Admin
