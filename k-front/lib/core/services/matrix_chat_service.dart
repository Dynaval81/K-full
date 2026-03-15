import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:knoty/data/models/chat_room.dart';
import 'package:knoty/data/models/message_model.dart';

/// Matrix Synapse client service.
class MatrixChatService {
  static const String _matrixBase =
      'https://hypermax.duckdns.org/_matrix/client/v3';
  static const String _matrixTokenKey = 'matrix_token';
  static const Duration _timeout = Duration(seconds: 35);

  final _storage = const FlutterSecureStorage();

  String? _syncToken;
  Timer? _syncTimer;
  bool _isSyncing = false;         // FIX #3: предотвращаем параллельные sync
  int _failCount = 0;              // FIX #3: exponential backoff

  // User context для фильтрации
  String? userSchool;
  String? userSchoolClass;
  String? matrixUserId;

  void setUserContext({String? school, String? schoolClass, String? userId}) {
    userSchool = school;
    userSchoolClass = schoolClass;
    matrixUserId = userId;
  }

  final _roomsController = StreamController<List<ChatRoom>>.broadcast();
  final _messagesController = StreamController<List<MessageModel>>.broadcast();

  Stream<List<ChatRoom>> get roomsStream => _roomsController.stream;
  Stream<List<MessageModel>> get messagesStream => _messagesController.stream;

  Future<String?> get _token => _storage.read(key: _matrixTokenKey);

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ─── SYNC ─────────────────────────────────────────────────────────────────

  void startSync() {
    stopSync();
    _failCount = 0;
    _scheduleSync(delay: Duration.zero);
  }

  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isSyncing = false;
  }

  // FIX #3: не рекурсия, а Timer + флаг + exponential backoff
  void _scheduleSync({Duration? delay}) {
    _syncTimer?.cancel();
    _syncTimer = Timer(delay ?? Duration.zero, _doSync);
  }

  Future<void> _doSync() async {
    if (_isSyncing) return; // уже идёт sync — пропускаем
    _isSyncing = true;

    try {
      final token = await _token;
      if (token == null) {
        _isSyncing = false;
        return;
      }

      final uri =
          Uri.parse('$_matrixBase/sync').replace(queryParameters: {
        'timeout': '30000',
        if (_syncToken != null) 'since': _syncToken!,
      });

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // FIX #7: обрабатываем сначала, обновляем токен только после успеха
        final nextBatch = data['next_batch']?.toString();
        _processSyncResponse(data);
        _syncToken = nextBatch; // обновляем только если processing прошёл без ошибок
        _failCount = 0;
      } else {
        _failCount++;
      }
    } catch (_) {
      _failCount++;
    } finally {
      _isSyncing = false;
    }

    // Exponential backoff: 500ms → 1s → 2s → 4s → max 30s
    if (_syncTimer != null) {
      // stopSync был вызван пока шёл sync — не планируем следующий
      return;
    }
    final backoff = Duration(
      milliseconds: min(500 * pow(2, _failCount).toInt(), 30000),
    );
    _scheduleSync(delay: _failCount > 0 ? backoff : const Duration(milliseconds: 500));
  }

  void _processSyncResponse(Map<String, dynamic> data) {
    final rooms =
        data['rooms']?['join'] as Map<String, dynamic>? ?? {};
    final chatRooms = <ChatRoom>[];
    final messages = <MessageModel>[];

    for (final entry in rooms.entries) {
      final roomId = entry.key;
      final roomData = entry.value as Map<String, dynamic>;

      String? roomName;
      String? roomType;
      String? schoolId, schoolName, classId, className;

      final stateEvents = roomData['state']?['events'] as List? ?? [];
      for (final event in stateEvents) {
        final type = event['type']?.toString() ?? '';
        if (type == 'm.room.name') {
          roomName = event['content']?['name']?.toString();
        } else if (type == 'm.room.join_rules') {
          roomType = event['content']?['join_rule']?.toString();
        } else if (type == 'knoty.school') {
          schoolId = event['content']?['school_id']?.toString();
          schoolName = event['content']?['school_name']?.toString();
          classId = event['content']?['class_id']?.toString();
          className = event['content']?['class_name']?.toString();
        }
      }

      final timeline = roomData['timeline']?['events'] as List? ?? [];
      String? lastMsg;
      DateTime? lastTime;

      for (final event in timeline.reversed) {
        if (event['type'] == 'm.room.message') {
          lastMsg = event['content']?['body']?.toString();
          lastTime = DateTime.fromMillisecondsSinceEpoch(
              (event['origin_server_ts'] as int?) ?? 0);

          messages.add(MessageModel(
            id: event['event_id']?.toString() ?? '',
            text: lastMsg ?? '',
            chatId: roomId,
            senderId: event['sender']?.toString() ?? '',
            isMe: event['sender'] == matrixUserId,
            timestamp: lastTime,
            status: MessageStatus.sent,
          ));
          break;
        }
      }

      final unread = (roomData['unread_notifications']
              ?['notification_count'] as int?) ??
          0;

      final chatType = _detectChatType(roomId, roomType, roomName, schoolId);

      // FIX #7: строгая фильтрация школьных чатов
      if (chatType.requiresVerification) {
        // Если у нас нет данных о школе юзера — не показываем школьные чаты
        if (userSchool == null) continue;
        // Если у комнаты есть schoolId — проверяем точное совпадение
        if (schoolId != null && schoolId != userSchool) continue;
        // Если нет schoolId — проверяем по имени (менее надёжно)
        if (schoolId == null &&
            schoolName != null &&
            !schoolName.toLowerCase().contains(userSchool!.toLowerCase())) {
          continue;
        }
      }

      chatRooms.add(ChatRoom(
        id: roomId,
        name: roomName ?? roomId,
        type: chatType,
        unread: unread,
        lastMessage: lastMsg,
        lastActivity: lastTime,
        schoolId: schoolId,
        schoolName: schoolName,
        classId: classId,
        className: className,
      ));
    }

    if (chatRooms.isNotEmpty) _roomsController.add(chatRooms);
    if (messages.isNotEmpty) _messagesController.add(messages);
  }

  // FIX #6: явный тип из metadata приоритетнее имени
  ChatType _detectChatType(
      String roomId, String? joinRule, String? name, String? schoolId) {
    // Если комната привязана к школе — это школьная
    if (schoolId != null) {
      if (name != null) {
        final lower = name.toLowerCase();
        if (lower.contains('klasse') || lower.contains('class')) {
          return ChatType.classGroup;
        }
      }
      return ChatType.schoolGroup;
    }

    // Fallback по имени (менее надёжно, только если нет metadata)
    if (name != null) {
      final lower = name.toLowerCase();
      if (lower.contains('klasse') || lower.contains('class')) {
        return ChatType.classGroup;
      }
      if (lower.contains('schule') || lower.contains('school') ||
          lower.contains('ag-') || lower.contains('interesse')) {
        return ChatType.schoolGroup;
      }
    }

    return ChatType.personal;
  }

  // ─── ИСТОРИЯ ──────────────────────────────────────────────────────────────

  Future<List<MessageModel>> loadHistory(String roomId,
      {String? currentUserId, int limit = 50}) async {
    try {
      final token = await _token;
      if (token == null) return [];

      final uri = Uri.parse(
              '$_matrixBase/rooms/${Uri.encodeComponent(roomId)}/messages')
          .replace(queryParameters: {
        'dir': 'b',
        'limit': '$limit',
      });

      final response =
          await http.get(uri, headers: _headers(token)).timeout(_timeout);

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final chunk = data['chunk'] as List? ?? [];

      return chunk
          .where((e) => e['type'] == 'm.room.message')
          .map((e) => MessageModel(
                id: e['event_id']?.toString() ?? '',
                text: e['content']?['body']?.toString() ?? '',
                chatId: roomId,
                senderId: e['sender']?.toString() ?? '',
                isMe: currentUserId != null &&
                    e['sender'] == currentUserId,
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                    (e['origin_server_ts'] as int?) ?? 0),
                status: MessageStatus.sent,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── ОТПРАВКА ─────────────────────────────────────────────────────────────

  Future<bool> sendMessage(String roomId, String text) async {
    try {
      final token = await _token;
      if (token == null) return false;

      final txnId = DateTime.now().millisecondsSinceEpoch.toString();
      final uri = Uri.parse(
          '$_matrixBase/rooms/${Uri.encodeComponent(roomId)}/send/m.room.message/$txnId');

      final response = await http
          .put(
            uri,
            headers: _headers(token),
            body: jsonEncode({'msgtype': 'm.text', 'body': text}),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── CLEANUP ──────────────────────────────────────────────────────────────

  // FIX #8: полная очистка ресурсов
  void dispose() {
    stopSync();
    // FIX #2: закрываем контроллеры только если открыты
    if (!_roomsController.isClosed) _roomsController.close();
    if (!_messagesController.isClosed) _messagesController.close();
  }

  /// Пользовательское сообщение об ошибке без внутренних деталей
  static String _sanitizeError(Object e) {
    if (e is SocketException) return 'Keine Internetverbindung';
    if (e is TimeoutException) return 'Zeitüberschreitung';
    return 'Verbindungsfehler';
  }
}