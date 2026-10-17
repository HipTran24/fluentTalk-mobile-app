import 'package:flutter/material.dart';
import 'package:english_mobile_app/core/models/enums.dart';
import 'package:english_mobile_app/core/theme/app_colors.dart';
import 'package:english_mobile_app/core/theme/app_spacing.dart';
import 'package:english_mobile_app/features/admin/domain/models/admin_models.dart';

class ScenarioEditorDialog extends StatefulWidget {
  final AdminScenarioItem? initialScenario;
  final Function(AdminScenarioItem) onSave;

  const ScenarioEditorDialog({
    super.key,
    this.initialScenario,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    AdminScenarioItem? initialScenario,
    required Function(AdminScenarioItem) onSave,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ScenarioEditorDialog(
          initialScenario: initialScenario,
          onSave: onSave,
        ),
      );
    } else {
      return showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: const Color(0xFF131B2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ScenarioEditorDialog(
              initialScenario: initialScenario,
              onSave: onSave,
            ),
          ),
        ),
      );
    }
  }

  @override
  State<ScenarioEditorDialog> createState() => _ScenarioEditorDialogState();
}

class _ScenarioEditorDialogState extends State<ScenarioEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _aiRoleController;
  late final TextEditingController _userRoleController;
  late final TextEditingController _durationController;
  late final TextEditingController _keyPhrasesController;

  late String _topicId;
  late String _topicName;
  late UserLevel _level;
  late bool _isActive;

  final Map<String, String> _topics = {
    'travel': 'Du lịch & Khách sạn',
    'daily': 'Đời sống thường nhật',
    'career': 'Công việc & Phỏng vấn',
    'exam': 'Luyện thi chứng chỉ',
  };

  @override
  void initState() {
    super.initState();
    final init = widget.initialScenario;
    _titleController = TextEditingController(text: init?.title ?? '');
    _aiRoleController = TextEditingController(text: init?.aiRole ?? '');
    _userRoleController = TextEditingController(text: init?.userRole ?? '');
    _durationController = TextEditingController(text: (init?.estimatedMinutes ?? 5).toString());
    _keyPhrasesController = TextEditingController(text: init?.keyPhrases.join(', ') ?? '');

    _topicId = init?.topicId ?? 'daily';
    _topicName = _topics[_topicId] ?? 'Đời sống thường nhật';
    _level = init?.level ?? UserLevel.a2;
    _isActive = init?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _aiRoleController.dispose();
    _userRoleController.dispose();
    _durationController.dispose();
    _keyPhrasesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề kịch bản')),
      );
      return;
    }

    final phrases = _keyPhrasesController.text
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final scenario = AdminScenarioItem(
      id: widget.initialScenario?.id ?? 'sc_custom_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      topicId: _topicId,
      topicName: _topicName,
      level: _level,
      aiRole: _aiRoleController.text.trim().isNotEmpty
          ? _aiRoleController.text.trim()
          : 'AI Conversation Partner',
      userRole: _userRoleController.text.trim().isNotEmpty
          ? _userRoleController.text.trim()
          : 'Learner',
      estimatedMinutes: int.tryParse(_durationController.text) ?? 5,
      usageCount: widget.initialScenario?.usageCount ?? 0,
      avgScore: widget.initialScenario?.avgScore ?? 8.0,
      isActive: _isActive,
      keyPhrases: phrases.isNotEmpty ? phrases : ['greeting', 'follow-up question'],
    );

    widget.onSave(scenario);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialScenario != null;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.movie_edit, color: AppColors.primaryLight, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isEdit ? 'Chỉnh sửa Kịch bản CMS' : 'Thêm Kịch bản mới',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFF1E293B)),

            // Tiêu đề
            const Text('Tiêu đề tình huống:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFCBD5E1))),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                hintText: 'VD: Check-in tại khách sạn 5 sao...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                prefixIcon: const Icon(Icons.title, size: 20, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Chủ đề & Cấp độ CEFR
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chủ đề (Topic):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFCBD5E1))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _topicId,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                        ),
                        items: _topics.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _topicId = val;
                              _topicName = _topics[val]!;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trình độ CEFR:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFCBD5E1))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<UserLevel>(
                        value: _level,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                        ),
                        items: UserLevel.values
                            .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl.name.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _level = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Vai AI & Vai Học viên
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vai trò AI:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFCBD5E1))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _aiRoleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          hintText: 'VD: Lễ tân khách sạn',
                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          prefixIcon: const Icon(Icons.smart_toy_outlined, size: 20, color: Color(0xFF94A3B8)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vai trò Học viên:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFCBD5E1))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _userRoleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          hintText: 'VD: Khách du lịch',
                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF94A3B8)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Mẫu câu khóa (Key Phrases)
            const Text('Từ khóa gợi ý (ngăn cách bởi dấu phẩy):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFCBD5E1))),
            const SizedBox(height: 6),
            TextField(
              controller: _keyPhrasesController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                hintText: 'reservation under name, room on higher floor, breakfast included',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                prefixIcon: const Icon(Icons.lightbulb_outline, size: 20, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Thời lượng & Trạng thái xuất bản
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 160,
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      labelText: 'Thời lượng (phút)',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      prefixIcon: const Icon(Icons.timer_outlined, size: 20, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text('Kích hoạt kịch bản:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFCBD5E1))),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isActive,
                      activeColor: AppColors.accent,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy bỏ'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(isEdit ? 'Lưu thay đổi' : 'Tạo kịch bản'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
