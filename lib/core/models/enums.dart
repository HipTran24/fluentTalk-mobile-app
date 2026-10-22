/// Common Enums across FluentTalk
/// Compliant with ESP-PLAN-001 Section 5 and Appendix A2, A5
enum UserLevel {
  a0('A0', 'Starter', 'Từ vựng & câu sinh hoạt cơ bản'),
  a1('A1', 'Beginner', 'Hỏi/đáp nhu cầu thường ngày'),
  a2('A2', 'Elementary', 'Giao tiếp mua sắm, du lịch, chỉ đường'),
  b1('B1', 'Intermediate', 'Diễn đạt ý kiến, thảo luận kinh nghiệm'),
  b2('B2', 'Upper-Int', 'Thuyết phục, trao đổi công việc linh hoạt'),
  c1('C1', 'Advanced', 'Ngữ cảnh học thuật, chuyên sâu'),
  c2('C2', 'Proficient', 'Lưu loát, tự nhiên như người bản xứ');

  final String code;
  final String label;
  final String description;

  const UserLevel(this.code, this.label, this.description);

  static UserLevel fromString(String? val) {
    return UserLevel.values.firstWhere(
      (e) =>
          e.code.toUpperCase() == val?.toUpperCase() ||
          e.name.toUpperCase() == val?.toUpperCase(),
      orElse: () => UserLevel.a1,
    );
  }
}

enum SessionMode {
  text('Ask & Listen', 'Gõ câu hỏi text, nghe Tom phát âm phản hồi'),
  guided('Guided Speaking', 'Luyện nói từng lượt theo kịch bản định hướng'),
  realtime('Realtime Call', 'Cuộc gọi đàm thoại 2 chiều thời gian thực');

  final String title;
  final String description;

  const SessionMode(this.title, this.description);
}

enum RubricDimension {
  fluency('Fluency & Coherence', 'Độ trôi chảy & mạch lạc'),
  lexical('Lexical Resource', 'Vốn từ vựng & độ chính xác'),
  grammar('Grammatical Range', 'Ngữ pháp & cấu trúc câu'),
  pronunciation('Pronunciation', 'Phát âm, trọng âm & ngữ điệu');

  final String labelEn;
  final String labelVi;

  const RubricDimension(this.labelEn, this.labelVi);
}

enum LearningGoalType {
  daily('Giao tiếp hàng ngày'),
  work('Công việc & Họp hành'),
  travel('Du lịch nước ngoài'),
  ielts('Luyện thi IELTS Speaking'),
  interview('Phỏng vấn xin việc');

  final String title;

  const LearningGoalType(this.title);
}

enum SessionStatus {
  active,
  completed,
  abandoned,
}
