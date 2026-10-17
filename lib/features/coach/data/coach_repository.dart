import '../../../core/models/coach_memory.dart';
import '../../../core/models/enums.dart';

abstract class CoachRepository {
  Future<List<WeaknessItem>> getIdentifiedWeaknesses();
  Future<RemedialDrill> getDrillById(String drillId);
  Future<List<WeeklyPlanItem>> getWeeklyPlan();
  Future<bool> markPlanItemCompleted(String planId);
}

class MockCoachRepository implements CoachRepository {
  final List<WeeklyPlanItem> _weeklyPlan = [
    const WeeklyPlanItem(
      id: 'plan_01',
      dayIndex: 1,
      dayName: 'Thứ Hai',
      title: 'Luyện tình huống: Gọi món tại nhà hàng Ý',
      activityType: 'Kịch bản • 5 phút',
      estimatedMinutes: 5,
      isCompleted: true,
      isToday: false,
    ),
    const WeeklyPlanItem(
      id: 'plan_02',
      dayIndex: 2,
      dayName: 'Thứ Ba',
      title: 'Drill phản xạ: Sửa lỗi thì Quá khứ đơn',
      activityType: 'Micro-Drill • 3 phút',
      estimatedMinutes: 3,
      isCompleted: false,
      isToday: true,
    ),
    const WeeklyPlanItem(
      id: 'plan_03',
      dayIndex: 3,
      dayName: 'Thứ Tư',
      title: 'Cuộc gọi tự do: Bàn về du lịch và kỳ nghỉ',
      activityType: 'Realtime Call • 7 phút',
      estimatedMinutes: 7,
      isCompleted: false,
      isToday: false,
    ),
    const WeeklyPlanItem(
      id: 'plan_04',
      dayIndex: 4,
      dayName: 'Thứ Năm',
      title: 'Ôn tập 10 cụm từ vựng nhà hàng & ẩm thực',
      activityType: 'Sổ tay từ vựng • 4 phút',
      estimatedMinutes: 4,
      isCompleted: false,
      isToday: false,
    ),
    const WeeklyPlanItem(
      id: 'plan_05',
      dayIndex: 5,
      dayName: 'Thứ Sáu',
      title: 'Luyện tình huống: Phỏng vấn xin việc',
      activityType: 'Kịch bản • 8 phút',
      estimatedMinutes: 8,
      isCompleted: false,
      isToday: false,
    ),
    const WeeklyPlanItem(
      id: 'plan_06',
      dayIndex: 6,
      dayName: 'Thứ Bảy',
      title: 'Drill phát âm: Trọng âm từ đuôi -tion, -sion',
      activityType: 'Micro-Drill • 3 phút',
      estimatedMinutes: 3,
      isCompleted: false,
      isToday: false,
    ),
    const WeeklyPlanItem(
      id: 'plan_07',
      dayIndex: 7,
      dayName: 'Chủ Nhật',
      title: 'Tổng kết tuần & Kiểm tra tiến độ với Coach Emma',
      activityType: 'Đánh giá tuần • 6 phút',
      estimatedMinutes: 6,
      isCompleted: false,
      isToday: false,
    ),
  ];

  @override
  Future<List<WeaknessItem>> getIdentifiedWeaknesses() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return [
      WeaknessItem(
        id: 'w_01',
        category: 'Ngữ pháp',
        description: 'Thì Quá khứ đơn (Past Simple regular verbs)',
        evidence: 'Quên chia động từ quá khứ ở 4/6 phiên gần nhất ("Yesterday I go" thay vì "went").',
        recurrenceCount: 4,
        impact: 0.85,
        confidence: 0.92,
        lastObservedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      WeaknessItem(
        id: 'w_02',
        category: 'Từ vựng & Liên kết',
        description: 'Từ nối câu (Connectors & Transition Words)',
        evidence: 'Lặp lại "and", "so" quá 12 lần; cần bổ sung "however", "therefore", "besides".',
        recurrenceCount: 3,
        impact: 0.65,
        confidence: 0.88,
        lastObservedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      WeaknessItem(
        id: 'w_03',
        category: 'Phát âm',
        description: 'Trọng âm từ kết thúc bằng đuôi -tion, -sion',
        evidence: 'Nhấn sai trọng âm từ "decision", "situation" ở phiên hội thoại sân bay.',
        recurrenceCount: 2,
        impact: 0.60,
        confidence: 0.85,
        lastObservedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  @override
  Future<RemedialDrill> getDrillById(String drillId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (drillId.contains('stress')) {
      return const RemedialDrill(
        id: 'drill_stress',
        title: 'Luyện trọng âm từ đuôi -tion / -sion',
        objective: 'Nhấn mạnh vào âm tiết ngay trước đuôi -tion / -sion',
        weaknessCategory: 'Phát âm',
        level: UserLevel.a2,
        taskType: 'listen_repeat',
        estimatedMinutes: 3,
        targetPhrase: 'It was a very difficult decision for our company.',
        audioPromptUrl: 'drill_stress_audio.mp3',
      );
    }

    if (drillId.contains('connectors')) {
      return const RemedialDrill(
        id: 'drill_connectors',
        title: 'Luyện sử dụng từ nối "However" và "Therefore"',
        objective: 'Nói lại câu diễn đạt tính tương phản một cách tự nhiên',
        weaknessCategory: 'Từ vựng & Liên kết',
        level: UserLevel.b1,
        taskType: 'listen_repeat',
        estimatedMinutes: 3,
        targetPhrase: 'I wanted to travel; however, the weather was not ideal.',
        audioPromptUrl: 'drill_connectors_audio.mp3',
      );
    }

    // Mặc định: drill_past_tense
    return const RemedialDrill(
      id: 'drill_past_tense',
      title: 'Sửa lỗi thì Quá khứ đơn (Past Simple)',
      objective: 'Chuyển đổi câu hiện tại sang quá khứ đơn chuẩn xác',
      weaknessCategory: 'Ngữ pháp',
      level: UserLevel.a2,
      taskType: 'listen_repeat',
      estimatedMinutes: 3,
      targetPhrase: 'Yesterday, I went to the supermarket and bought some groceries.',
      audioPromptUrl: 'drill_past_audio.mp3',
    );
  }

  @override
  Future<List<WeeklyPlanItem>> getWeeklyPlan() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_weeklyPlan);
  }

  @override
  Future<bool> markPlanItemCompleted(String planId) async {
    final idx = _weeklyPlan.indexWhere((p) => p.id == planId);
    if (idx != -1) {
      final old = _weeklyPlan[idx];
      _weeklyPlan[idx] = WeeklyPlanItem(
        id: old.id,
        dayIndex: old.dayIndex,
        dayName: old.dayName,
        title: old.title,
        activityType: old.activityType,
        estimatedMinutes: old.estimatedMinutes,
        isCompleted: true,
        isToday: old.isToday,
      );
      return true;
    }
    return false;
  }
}
