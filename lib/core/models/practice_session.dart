import 'enums.dart';

/// Conversation Message Entity
class ConversationMessage {
  final String id;
  final String sessionId;
  final String role; // 'user' or 'ai'
  final String text;
  final String? audioUrl;
  final int sequenceNo;
  final DateTime createdAt;

  const ConversationMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.text,
    this.audioUrl,
    required this.sequenceNo,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAi => role == 'ai';

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      role: json['role'] as String,
      text: json['text'] as String,
      audioUrl: json['audio_url'] as String?,
      sequenceNo: json['sequence_no'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Correction detail on specific utterance
class CorrectionItem {
  final String original;
  final String suggested;
  final String explanationVi;
  final String type; // 'grammar', 'vocabulary', 'pronunciation'

  const CorrectionItem({
    required this.original,
    required this.suggested,
    required this.explanationVi,
    required this.type,
  });

  factory CorrectionItem.fromJson(Map<String, dynamic> json) {
    return CorrectionItem(
      original: json['original'] as String? ?? '',
      suggested: json['suggested'] as String? ?? '',
      explanationVi: json['explanation_vi'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
    );
  }
}

/// Practice Session Instance
class PracticeSession {
  final String id;
  final String userId;
  final String? scenarioId;
  final String? scenarioTitle;
  final SessionMode mode;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final int turnsCount;
  final double? estimatedScore;

  const PracticeSession({
    required this.id,
    required this.userId,
    this.scenarioId,
    this.scenarioTitle,
    required this.mode,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.turnsCount = 0,
    this.estimatedScore,
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scenarioId: json['scenario_id'] as String?,
      scenarioTitle: json['scenario_title'] as String?,
      mode: SessionMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => SessionMode.guided,
      ),
      status: SessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => SessionStatus.active,
      ),
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      turnsCount: json['turns_count'] as int? ?? 0,
      estimatedScore: (json['estimated_score'] as num?)?.toDouble(),
    );
  }
}
