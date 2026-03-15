// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get splashTagline => 'Объединяй свой школьный мир';

  @override
  String get loginTitle => 'Вход';

  @override
  String get loginSubtitle => 'Войди в свой аккаунт';

  @override
  String get loginMethodEmail => 'Email';

  @override
  String get loginHintEmail => 'Введи email';

  @override
  String get loginPasswordLabel => 'Пароль';

  @override
  String get loginPasswordHint => 'Введи пароль';

  @override
  String get loginEnterPassword => 'Введи пароль';

  @override
  String get loginButtonLogin => 'Войти';

  @override
  String get loginForgotPassword => 'Забыл пароль?';

  @override
  String get loginDividerOr => 'или';

  @override
  String get loginGoogle => 'Войти через Google';

  @override
  String get loginApple => 'Войти через Apple';

  @override
  String get loginGoogleSoon => 'Google Sign-In — скоро';

  @override
  String get loginAppleSoon => 'Apple Sign-In — скоро';

  @override
  String get loginNoAccount => 'Нет аккаунта? ';

  @override
  String get loginRegister => 'Зарегистрироваться';

  @override
  String get loginErrorEmpty => 'Введи email';

  @override
  String get loginErrorEmptyPassword => 'Введи пароль';

  @override
  String get loginErrorNetwork => 'Ошибка сети. Попробуй ещё раз.';

  @override
  String get loginErrorEmailVerification => 'Подтверди email перед входом';

  @override
  String get loginErrorGeneric => 'Ошибка входа. Попробуй ещё раз.';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get registerSubtitle => 'Создать аккаунт';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerEmailHint => 'Введи email';

  @override
  String get registerPasswordLabel => 'Пароль';

  @override
  String get registerPasswordHint => 'Минимум 6 символов';

  @override
  String get registerNicknameLabel => 'Никнейм (необязательно)';

  @override
  String get registerNicknameHint => 'Введи никнейм';

  @override
  String get registerButton => 'Создать аккаунт';

  @override
  String get registerHaveAccount => 'Уже есть аккаунт? ';

  @override
  String get registerLogin => 'Войти';

  @override
  String get dashboardTitle => 'Главная';

  @override
  String get dashboardSettings => 'Настройки';

  @override
  String get dashboardLogout => 'Выйти';

  @override
  String get dashboardReport => 'Сообщить об ошибке';

  @override
  String get dashboardReportHint => 'Опиши что не работает — мы разберёмся.';

  @override
  String get dashboardAppInfo => 'О приложении';

  @override
  String get dashboardVersionDetails => 'Детали версии';

  @override
  String get tabChats => 'Чаты';

  @override
  String get tabAi => 'ИИ-помощник';

  @override
  String get tabSchedule => 'Расписание';

  @override
  String get tabDashboard => 'Главная';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsThemeLight => 'Светлая';

  @override
  String get settingsThemeDark => 'Тёмная';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsLogout => 'Выйти';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get scheduleTitle => 'Расписание';

  @override
  String get scheduleComingSoon => 'Твоё расписание скоро появится.';

  @override
  String get pendingTitle => 'Аккаунт проверяется';

  @override
  String get pendingMessage => 'Твою заявку проверяет администратор школы.';

  @override
  String get pendingAvailable => 'Ты уже можешь общаться с друзьями!';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get comingSoonAi => 'ИИ-помощник в разработке';

  @override
  String get comingSoonChats => 'Чаты скоро появятся';

  @override
  String get errorNetwork => 'Ошибка сети';

  @override
  String get errorUnknown => 'Неизвестная ошибка';

  @override
  String get buttonOk => 'ОК';

  @override
  String get buttonCancel => 'Отмена';

  @override
  String get buttonSave => 'Сохранить';

  @override
  String get buttonClose => 'Закрыть';

  @override
  String get sandboxLimitChats => 'Доступно после верификации школы';

  @override
  String get sandboxLimitSchedule => 'Доступно после верификации школы';

  @override
  String get sandboxLimitPasswordVault => 'Доступно после привязки родителя';

  @override
  String get sandboxDailyLimitReached => 'Дневной лимит. До завтра!';

  @override
  String get curfewTitle => 'Спокойной ночи!';

  @override
  String get curfewMessage => 'Приложение заблокировано до утра.';

  @override
  String get loginPrimaryButton => 'Войти';

  @override
  String get chatUnknown => 'Неизвестно';

  @override
  String get chatTypeClass => 'Классовый чат';

  @override
  String get chatTypeSchool => 'Школьный чат';

  @override
  String get chatOnline => 'Онлайн';

  @override
  String get chatLastSeen => 'Был(а) онлайн';

  @override
  String get chatNoMessages => 'Нет сообщений';

  @override
  String get chatFirstMessage => 'Напиши первым!';

  @override
  String get chatNewMessages => 'Новые сообщения';

  @override
  String get chatCallVoice => 'Аудиозвонок';

  @override
  String get chatCallVideo => 'Видеозвонок';

  @override
  String get chatCallComingSoon => 'Звонки скоро появятся';

  @override
  String get chatDateToday => 'Сегодня';

  @override
  String get chatDateYesterday => 'Вчера';

  @override
  String get settingsTabsTitle => 'Вкладки';

  @override
  String get settingsTabChats => 'Чаты';

  @override
  String get settingsTabAi => 'ИИ-помощник';

  @override
  String get settingsTabSchool => 'Школа';

  @override
  String get settingsTabKind => 'Ребёнок';

  @override
  String get settingsTabClasses => 'Классы';

  @override
  String get settingsTabVerwaltung => 'Управление';

  @override
  String get splashHai3Label => 'HAI3 Design';

  @override
  String get dashboardDonationsText =>
      'Помоги нам сделать Knoty бесплатным и независимым.';

  @override
  String get dashboardDonations => 'Поддержать Knoty';

  @override
  String get dashboardElementsStore => 'Магазин';

  @override
  String get dashboardReportPlaceholder => 'Описать проблему...';

  @override
  String get dashboardReportSend => 'Отправить';

  @override
  String get dashboardReportSent => 'Отчёт отправлен. Спасибо!';

  @override
  String get dashboardTabAi => 'ИИ-помощник';

  @override
  String get dashboardTabChats => 'Чаты';

  @override
  String get dashboardTabVpn => 'VPN';

  @override
  String get schoolTitle => 'Школа';

  @override
  String get schoolCodeEmpty => 'Введи код школы';

  @override
  String get schoolCodeInvalid => 'Неверный код школы';

  @override
  String get schoolNotVerifiedTitle => 'Ещё не верифицирован';

  @override
  String get schoolNotVerifiedSubtitle =>
      'Твой аккаунт ждёт подтверждения администратора школы.';

  @override
  String get schoolCodeHint => 'SCH-XXXX';

  @override
  String get schoolCodeRedeem => 'Активировать код';

  @override
  String schoolWaitingFrom(Object school) {
    return 'Ожидание подтверждения от $school';
  }

  @override
  String get schoolWaitingConfirmation => 'Ожидание подтверждения';

  @override
  String get schoolStatClass => 'Класс';

  @override
  String get schoolStatStatus => 'Статус';

  @override
  String get schoolStatActive => 'Активен';

  @override
  String get schoolStatNew => 'Новый';

  @override
  String get schoolServicesTitle => 'Школьные сервисы';

  @override
  String get schoolTimetable => 'Расписание';

  @override
  String get schoolAnnouncements => 'Объявления';

  @override
  String get schoolDocuments => 'Документы';

  @override
  String get schoolHomework => 'Домашние задания';

  @override
  String get schoolGrades => 'Оценки';

  @override
  String get schoolEvents => 'Мероприятия';

  @override
  String get schoolUpcomingTitle => 'Скоро';

  @override
  String schoolComingSoon(Object name) {
    return '$name скоро появится';
  }

  @override
  String get schoolVerifiedBadge => 'Верифицирован';

  @override
  String get parentTitle => 'Ребёнок';

  @override
  String get lockedNoChildTitle => 'Ребёнок не привязан';

  @override
  String get lockedNoChildSubtitle =>
      'Введи KN-номер ребёнка, чтобы связать аккаунты.';

  @override
  String get teacherClassesTitle => 'Мои классы';

  @override
  String get lockedTeacherTitle => 'Пока недоступно';

  @override
  String get lockedTeacherSubtitle =>
      'Управление классами появится после верификации школы.';

  @override
  String get teacherClassesComingSoon => 'Классы скоро появятся';

  @override
  String get verwaltungTitle => 'Управление';

  @override
  String get verwaltungActivateUsers => 'Активировать пользователей';

  @override
  String get verwaltungActivateUsersSubtitle =>
      'Проверить и активировать ожидающие регистрации';

  @override
  String get verwaltungGenerateCodes => 'Генерировать коды';

  @override
  String get verwaltungGenerateCodesSubtitle =>
      'Создать коды доступа для учителей и учеников';

  @override
  String get verwaltungUserList => 'Список пользователей';

  @override
  String get verwaltungUserListSubtitle =>
      'Просматривать и управлять пользователями школы';

  @override
  String get verwaltungSuperAdminHint =>
      'У тебя есть суперадмин-доступ ко всем школам.';

  @override
  String get lockedDefaultTitle => 'Функция заблокирована';

  @override
  String get lockedDefaultSubtitle =>
      'Эта функция недоступна для твоего аккаунта.';

  @override
  String get msgCopied => 'Сообщение скопировано';

  @override
  String get msgReportTitle => 'Пожаловаться';

  @override
  String get msgReportConfirm => 'Пожаловаться на это сообщение?';

  @override
  String get msgReportCancel => 'Отмена';

  @override
  String get msgReportSend => 'Пожаловаться';

  @override
  String get msgReported => 'Сообщение отправлено';

  @override
  String get msgReactionPicker => 'Выбрать реакцию';

  @override
  String get msgActionReply => 'Ответить';

  @override
  String get msgActionCopy => 'Копировать';

  @override
  String get msgActionForward => 'Переслать';

  @override
  String get msgActionPin => 'Закрепить';

  @override
  String get msgActionEdit => 'Редактировать';

  @override
  String get msgActionDelete => 'Удалить';

  @override
  String get msgActionRemove => 'Убрать';

  @override
  String get msgActionReport => 'Пожаловаться';

  @override
  String get registerWhoAreYou => 'Кто ты?';

  @override
  String get registerChooseRole => 'Выбери роль, чтобы продолжить';

  @override
  String get registerContinue => 'Продолжить';

  @override
  String get registerFirstName => 'Имя';

  @override
  String get registerFirstNameHint => 'Иван';

  @override
  String get registerLastName => 'Фамилия';

  @override
  String get registerLastNameHint => 'Иванов';

  @override
  String get registerRoleStudent => 'Ученик';

  @override
  String get registerRoleStudentSubtitle => 'Я ученик или ученица';

  @override
  String get registerRoleParent => 'Родитель';

  @override
  String get registerRoleParentSubtitle => 'Я мама или папа';

  @override
  String get registerRoleTeacher => 'Учитель';

  @override
  String get registerRoleTeacherSubtitle => 'Я учитель или учительница';

  @override
  String get registerSubtitleStudent => 'Создать аккаунт ученика';

  @override
  String get registerSubtitleParent => 'Создать аккаунт родителя';

  @override
  String get registerSubtitleTeacher => 'Создать аккаунт учителя';

  @override
  String get registerSchool => 'Школа';

  @override
  String get registerSchoolLoading => 'Загрузка школ...';

  @override
  String get registerSchoolHint => 'Введи название школы...';

  @override
  String get registerSchoolCodeUsed => 'Используется код активации';

  @override
  String get registerClass => 'Класс';

  @override
  String get registerClassHint => 'напр. 5а';

  @override
  String get registerHasActivationCode =>
      'У меня есть код активации (KNOTY-XXXX-XXXX)';

  @override
  String get registerActivationCodeLabel => 'Код активации';

  @override
  String get registerActivationCodeHint => 'KNOTY-XXXX-XXXX';

  @override
  String get registerKnChildLabel => 'KN-номер ребёнка';

  @override
  String get registerKnChildHint => 'KN-12345';

  @override
  String get registerInfoStudent =>
      'Твой аккаунт будет проверен администратором школы.';

  @override
  String get registerInfoTeacher =>
      'Твой аккаунт будет верифицирован администратором школы.';

  @override
  String get registerInfoParent =>
      'Введи KN-номер ребёнка. Его можно найти в приложении Knoty ребёнка.';

  @override
  String get registerErrorFirstName => 'Введи имя';

  @override
  String get registerErrorLastName => 'Введи фамилию';

  @override
  String get registerErrorSchool => 'Выбери школу';

  @override
  String get registerErrorActivationCode => 'Введи код активации';

  @override
  String get registerErrorKnChild => 'Введи KN-номер ребёнка';

  @override
  String get registerErrorNoInternet => 'Нет подключения к интернету';

  @override
  String get registerErrorNameDigitsOnly =>
      'Имя и фамилия не могут состоять только из цифр';

  @override
  String get registerSuccessWelcome => 'Добро пожаловать!';

  @override
  String get registerSuccessKnotyIdLabel => 'Твой Knoty-ID';

  @override
  String get registerSuccessRememberHint =>
      'Запомни этот номер — он нужен для входа';

  @override
  String get registerSuccessButton => 'Начать';

  @override
  String get chatsFilterAll => 'Все';

  @override
  String get chatsFilterPrivate => 'Личные';

  @override
  String get chatsFilterGroups => 'Группы';

  @override
  String get chatsFilterSchool => 'Школа';

  @override
  String get chatsEmptyAll => 'Нет чатов';

  @override
  String get chatsEmptyPrivate => 'Нет личных чатов';

  @override
  String get chatsEmptyGroups => 'Нет групп';

  @override
  String get chatsEmptySchool => 'Нет школьных чатов';

  @override
  String get aiEmptyTitle => 'Knoty ИИ-ассистент';

  @override
  String get aiEmptySubtitle => 'Задай мне вопрос — я с удовольствием помогу.';

  @override
  String get aiThinking => 'Думаю...';

  @override
  String get profileChangePhoto => 'Изменить фото профиля';

  @override
  String get profileMySchool => 'Моя школа';

  @override
  String get profileQrCode => 'QR-код';

  @override
  String get profileNotifications => 'Уведомления';

  @override
  String get profileSupport => 'Поддержка';

  @override
  String get chatTimeNow => 'Только что';

  @override
  String get chatTimeMin => 'мин.';

  @override
  String get loginIdentifierHint => '@Никнейм, Knoty-ID или email';

  @override
  String get profileRequestChange => 'Запросить изменение';

  @override
  String get profileEdit => 'Редактировать профиль';

  @override
  String get profileSchoolChange => 'Запросить смену школы';

  @override
  String get schoolNow => 'Сейчас';

  @override
  String get schoolNextLesson => 'Следующий урок';

  @override
  String get schoolBreak => 'Перемена';

  @override
  String get schoolRoom => 'Кабинет';

  @override
  String get schoolMinLeft => 'мин осталось';

  @override
  String get schoolClubs => 'Кружки';

  @override
  String get schoolCafeteria => 'Столовая';

  @override
  String get schoolScheduleToday => 'Сегодня';

  @override
  String get schoolAfterHours => 'Уроки закончились';

  @override
  String get schoolNoSchedule => 'Нет занятий';

  @override
  String get schoolTeacherLabel => 'Учитель';

  @override
  String get schoolWeekView => 'Неделя';

  @override
  String get schoolTeachersTitle => 'Учителя';

  @override
  String get schoolQrTitle => 'Мой QR-код';

  @override
  String get schoolQrHint => 'Покажи этот код администратору школы';

  @override
  String get schoolNotesTitle => 'Заметки к уроку';

  @override
  String get schoolNotesAdd => 'Добавить заметку';

  @override
  String get schoolNotesHint => 'Напиши заметку...';

  @override
  String get schoolNotesSave => 'Сохранить';

  @override
  String get schoolAvgLabel => 'Среднее';

  @override
  String get schoolOpenHoursLabel => 'Открыто 11:30–14:00';

  @override
  String get schoolCafeteriaMenuToday => 'Меню сегодня';

  @override
  String get schoolGradeTopic => 'Тема';

  @override
  String get schoolGradeDate => 'Дата';

  @override
  String get schoolTeacherContact => 'Контакт';

  @override
  String schoolHomeworkOpen(int count) {
    return '$count заданий';
  }

  @override
  String schoolAnnouncementsNew(int count) {
    return '$count новых';
  }

  @override
  String schoolDocumentsCount(int count) {
    return '$count файлов';
  }

  @override
  String schoolClubsActive(int count) {
    return '$count активных';
  }

  @override
  String aiGreeting(String name) {
    return 'Готов к школе, $name?';
  }

  @override
  String aiGreetingMorning(String name) {
    return 'Доброе утро, $name!';
  }

  @override
  String aiGreetingEvening(String name) {
    return 'Домашка готова, $name?';
  }

  @override
  String get aiSurpriseMe => 'Удиви меня школьным вопросом!';

  @override
  String get aiHubSubtitle => 'Твоя ИИ-студия';

  @override
  String get aiChatTitle => 'Спросить ассистента';

  @override
  String get aiChatSubtitle => 'Учебный партнёр';

  @override
  String get aiStickerTitle => 'Лаборатория стикеров';

  @override
  String get aiStickerSubtitle => 'Текст в картинку';

  @override
  String get aiPhotoTitle => 'Магия фото';

  @override
  String get aiPhotoSubtitle => 'Редактировать и улучшить';

  @override
  String get aiChipExplain => 'Объяснить тему';

  @override
  String get aiChipGrammar => 'Проверить грамматику';

  @override
  String get aiChipSummarize => 'Резюме';

  @override
  String get aiChipMath => 'Помощь по математике';

  @override
  String get aiInputHint => 'Спроси что-нибудь...';

  @override
  String get aiStyleAnime => 'Аниме';

  @override
  String get aiStyle3d => '3D-рендер';

  @override
  String get aiStyleComic => 'Комикс';

  @override
  String get aiStylePixel => 'Пиксель-арт';

  @override
  String get aiStyleRealist => 'Реализм';

  @override
  String get aiImprovePrompt => 'Улучшить промпт';

  @override
  String get aiGenerate => 'Сгенерировать';

  @override
  String get aiPaintingLabel => 'Рисую твою фантазию...';

  @override
  String get aiRemoveBg => 'Удалить фон';

  @override
  String get aiEnhance => 'Улучшить';

  @override
  String get aiStylize => 'ИИ-стилизация';

  @override
  String get aiSendAsSticker => 'Отправить как стикер';

  @override
  String get aiUploadPhoto => 'Загрузить фото';

  @override
  String get aiStickerInputHint => 'Опиши свой стикер...';

  @override
  String get aiProcessing => 'Обработка...';

  @override
  String get aiNewChat => 'Новый чат';

  @override
  String get aiAiLabel => 'ИИ';

  @override
  String get aiAuraActive => 'ИИ активен';

  @override
  String get navTabAi => 'ИИ';

  @override
  String get navTabSchool => 'Школа';

  @override
  String get aiStop => 'Стоп';

  @override
  String get aiParentGreetingMorning => 'Доброе утро! Как дела у вас?';

  @override
  String get aiParentGreetingEvening => 'Добрый вечер! Всё хорошо в семье?';

  @override
  String get aiParentGreetingDay => 'Привет! Чем могу помочь?';

  @override
  String get aiParentTile1Title => 'Советник';

  @override
  String get aiParentTile1Subtitle => 'Советы и рекомендации';

  @override
  String get aiParentTile2Title => 'Идеи прогулок';

  @override
  String get aiParentTile2Subtitle => 'С семьёй';

  @override
  String get aiParentTile3Title => 'Написать письмо';

  @override
  String get aiParentTile3Subtitle => 'В школу и учителям';

  @override
  String get aiParentChipTip => 'Совет по воспитанию';

  @override
  String get aiParentChipOuting => 'Идеи прогулок';

  @override
  String get aiParentChipLetter => 'Написать письмо';

  @override
  String get aiParentChipStress => 'Стресс в школе';

  @override
  String get aiParentEmptyTitle => 'Ассистент для родителей';

  @override
  String get aiParentEmptySubtitle =>
      'Помогу с воспитанием, прогулками\nи общением со школой.';

  @override
  String get parentAddChild => 'Добавить ребёнка';

  @override
  String get parentEmergencyActivateTitle => 'Активировать блокировку?';

  @override
  String get parentEmergencyDeactivateTitle => 'Снять блокировку?';

  @override
  String get parentEmergencyActivateMsg =>
      'Приложение будет заблокировано немедленно.';

  @override
  String get parentEmergencyDeactivateMsg =>
      'Ребёнок снова сможет использовать приложение.';

  @override
  String get parentEmergencyActivateBtn => 'Заблокировать';

  @override
  String get parentEmergencyDeactivateBtn => 'Снять';

  @override
  String get parentStatusPending => 'Ожидает';

  @override
  String get parentStatusLinked => 'Привязан';

  @override
  String get parentAttendanceAtSchool => 'В школе';

  @override
  String get parentAttendanceAbsent => 'Отсутствует';

  @override
  String get parentAttendanceUnknown => 'Неизвестно';

  @override
  String get parentSectionAttendance => 'Посещаемость';

  @override
  String get parentSectionScreenTime => 'Экранное время сегодня';

  @override
  String get parentSectionGrades => 'Последние оценки';

  @override
  String get parentSectionControls => 'Родительский контроль';

  @override
  String get parentDailyLimitLabel => 'Дневной лимит';

  @override
  String get parentEveningBlockLabel => 'Вечерняя блокировка';

  @override
  String get parentEveningBlockDesc => 'Блокировка с 21:00';

  @override
  String get parentEmergencyLockActivate =>
      'Активировать экстренную блокировку';

  @override
  String get parentEmergencyLockDeactivate => 'Снять экстренную блокировку';

  @override
  String get parentPendingTitle => 'Ожидает подтверждения';

  @override
  String get parentPendingSubtitle => 'Подтверждение от ребёнка ожидается.';

  @override
  String get parentWithdrawRequest => 'Отозвать запрос';

  @override
  String get parentLinkChildTitle => 'Привязать ребёнка';

  @override
  String get parentLinkButton => 'Привязать';

  @override
  String get parentKnFormat => 'Формат: KN-12345';

  @override
  String get parentSchoolEventsTitle => 'Предстоящие события';

  @override
  String get parentSchoolContactsTitle => 'Контакты';

  @override
  String get parentSchoolLettersTitle => 'Письма для родителей';

  @override
  String get parentSchoolCommitteeTitle => 'Родительский комитет';

  @override
  String get parentSchoolCommitteeChat => 'Чат комитета';

  @override
  String get parentSchoolCommitteeVotes => 'Голосования и решения';

  @override
  String get parentRoleBadge => 'Родитель';

  @override
  String get parentSchoolMySchool => 'Моя школа';

  @override
  String aiTeacherGreetingMorning(String name) {
    return 'Доброе утро, $name!';
  }

  @override
  String aiTeacherGreetingDay(String name) {
    return 'Привет, $name! Что подготовить?';
  }

  @override
  String aiTeacherGreetingEvening(String name) {
    return 'Добрый вечер, $name! Ещё что-то планируем?';
  }

  @override
  String get aiTeacherTile1Title => 'Создать тест';

  @override
  String get aiTeacherTile1Subtitle => 'ИИ генерирует вопросы и ответы';

  @override
  String get aiTeacherTile2Title => 'План урока';

  @override
  String get aiTeacherTile2Subtitle => 'Методично и структурированно';

  @override
  String get aiTeacherTile3Title => 'Проверить работы';

  @override
  String get aiTeacherTile3Subtitle => 'Найти ошибки по описанию';

  @override
  String get aiTeacherChipTest => 'Создать тест по теме';

  @override
  String get aiTeacherChipPlan => 'Составить план урока';

  @override
  String get aiTeacherChipCheck => 'Оценить работу ученика';

  @override
  String get aiTeacherChipIdea => 'Предложить идею урока';

  @override
  String get aiTeacherToolsTitle => 'KI-Werkzeuge';

  @override
  String get aiTeacherToolsSubtitle => 'Diktat · Quiz · Eltern-E-Mail';

  @override
  String get aiTeacherToolsSheetSubtitle =>
      'Werkzeug auswählen — KI erledigt den Rest';

  @override
  String get aiTeacherVoiceReportLabel => 'Diktat zum Bericht';

  @override
  String get aiTeacherVoiceReportSub => 'Sprachnotizen → fertiger Bericht';

  @override
  String get aiTeacherVoiceReportPrefill =>
      'Erstelle einen strukturierten Bericht aus folgenden Sprachnotizen:';

  @override
  String get aiTeacherQuizGenLabel => 'Quiz-Generator';

  @override
  String get aiTeacherQuizGenSub => 'Thema → Aufgaben & Antworten';

  @override
  String get aiTeacherQuizGenPrefill =>
      'Erstelle einen Quiz mit 10 Fragen zum Thema:';

  @override
  String get aiTeacherParentEmailLabel => 'Eltern-E-Mail';

  @override
  String get aiTeacherParentEmailSub => 'Anlass → fertige E-Mail';

  @override
  String get aiTeacherParentEmailPrefill =>
      'Schreibe eine professionelle E-Mail an die Eltern über:';

  @override
  String get teacherJournalSubjectMath => 'Математика';

  @override
  String get teacherJournalSubjectGerman => 'Немецкий';

  @override
  String get teacherJournalSubjectEnglish => 'Английский';

  @override
  String get teacherGrade1Label => 'Отлично';

  @override
  String get teacherGrade2Label => 'Хорошо';

  @override
  String get teacherGrade3Label => 'Удовлетворительно';

  @override
  String get teacherGrade4Label => 'Достаточно';

  @override
  String get teacherGrade5Label => 'Плохо';

  @override
  String get teacherGrade6Label => 'Неудовл.';

  @override
  String get teacherMarkAbsent => 'Отсутствует';

  @override
  String get teacherGradeDialogTitle => 'Выставить оценку';

  @override
  String get teacherGradeAdded => 'Оценка сохранена';

  @override
  String get teacherNoStudents => 'Нет учеников в этом классе';

  @override
  String get teacherSelectClass => 'Выбрать класс';

  @override
  String get teacherGradeTypeOral => 'Устно';

  @override
  String get teacherGradeTypeWritten => 'Письменно';

  @override
  String get teacherGradeTypeTest => 'Контрольная';

  @override
  String get teacherGradeTypeHomework => 'Домашнее задание';

  @override
  String get teacherGradeDate => 'Дата';

  @override
  String get teacherGradeTypeLabel => 'Тип';

  @override
  String get teacherGradeSubjectLabel => 'Предмет';

  @override
  String get teacherGradeToday => 'Сегодня';

  @override
  String get teacherGradeYesterday => 'Вчера';

  @override
  String teacherGradeFor(String name) {
    return 'Оценка для $name';
  }

  @override
  String get teacherSchoolMySchedule => 'Моё расписание';

  @override
  String get teacherSchoolMyClasses => 'Мои классы';

  @override
  String get teacherSchoolColleagues => 'Коллеги';

  @override
  String get teacherSchoolNextClass => 'Следующий урок';

  @override
  String get teacherSchoolNowTeaching => 'Сейчас';

  @override
  String get teacherSchoolFreeNow => 'Окно';

  @override
  String get teacherSchoolRoleBadge => 'Учитель';

  @override
  String teacherSchoolStudents(int count) {
    return '$count учеников';
  }
}
