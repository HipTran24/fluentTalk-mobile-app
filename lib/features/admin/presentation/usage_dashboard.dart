import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../connected/presentation/academic_widgets.dart';

class UsageDashboard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int days;
  final String provider;
  final ValueChanged<int> onDays;
  final ValueChanged<String> onProvider;
  const UsageDashboard(
      {super.key,
      required this.data,
      required this.days,
      required this.provider,
      required this.onDays,
      required this.onProvider});
  @override
  State<UsageDashboard> createState() => _UsageDashboardState();
}

class _UsageDashboardState extends State<UsageDashboard> {
  String metric = 'totalTokens';
  String? selectedDate;
  static const metrics = {
    'totalTokens': 'Tổng token',
    'inputTokens': 'Token đầu vào',
    'outputTokens': 'Token đầu ra',
    'requests': 'Số yêu cầu'
  };

  String number(Object? value) =>
      NumberFormat.decimalPattern('vi').format(value is num ? value : 0);

  Color _providerColor(String? p) {
    switch (p?.toLowerCase()) {
      case 'gemini':
        return const Color(0xFF4285F4);
      case 'openai':
        return const Color(0xFF10A37F);
      case 'groq':
        return const Color(0xFFF55036);
      default:
        return const Color(0xFF818CF8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final totals = data['totals'] as Map;
    final daily = (data['daily'] as List).whereType<Map>().toList();
    final peak = daily.fold<double>(
        0, (v, day) => math.max(v, (day[metric] as num).toDouble()));
    final selected = daily.where((v) => v['date'] == selectedDate).firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        // Filter controls
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int>(
                initialValue: widget.days,
                isExpanded: true,
                dropdownColor: const Color(0xFF0F172A),
                decoration: const InputDecoration(
                  labelText: 'Khoảng thời gian',
                  prefixIcon: Icon(Icons.date_range_outlined,
                      size: 18, color: Color(0xFF818CF8)),
                ),
                items: [7, 14, 30]
                    .map((n) => DropdownMenuItem(
                          value: n,
                          child: Text(
                            '$n ngày gần nhất',
                            style: const TextStyle(color: Color(0xFFF8FAFC)),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => widget.onDays(v!),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                initialValue: widget.provider,
                isExpanded: true,
                dropdownColor: const Color(0xFF0F172A),
                decoration: const InputDecoration(
                  labelText: 'Provider',
                  prefixIcon: Icon(Icons.hub_outlined,
                      size: 18, color: Color(0xFF818CF8)),
                ),
                items: ['', 'gemini', 'openai', 'groq']
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            v.isEmpty ? 'Tất cả provider' : v,
                            style: const TextStyle(color: Color(0xFFF8FAFC)),
                          ),
                        ))
                    .toList(),
                onChanged: (v) => widget.onProvider(v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${data['from']} → ${data['to']} · Giờ Việt Nam (UTC+7)',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // 4 KPI Cards
        AcademicGrid(
          minWidth: 230,
          children: [
            for (final item in [
              (
                'Token đã xác nhận',
                'totalTokens',
                Icons.toll_rounded,
                const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                const Color(0xFF818CF8)
              ),
              (
                'Token đầu vào',
                'inputTokens',
                Icons.arrow_downward_rounded,
                const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                const Color(0xFF38BDF8)
              ),
              (
                'Token đầu ra',
                'outputTokens',
                Icons.arrow_upward_rounded,
                const [Color(0xFF10B981), Color(0xFF059669)],
                const Color(0xFF34D399)
              ),
              (
                'Yêu cầu chat',
                'requests',
                Icons.chat_bubble_outline_rounded,
                const [Color(0xFFF59E0B), Color(0xFFD97706)],
                const Color(0xFFFBBF24)
              ),
            ])
              AcademicPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: item.$4,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: item.$5.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(item.$3, color: Colors.white, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'METRIC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      number(totals[item.$2]),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF8FAFC),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$1,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Chart Card
        AcademicPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B4B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: Color(0xFF818CF8), size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sử dụng theo ngày',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF8FAFC),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Biểu đồ trực quan lượng token và yêu cầu theo dòng thời gian',
                          style:
                              TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      initialValue: metric,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0F172A),
                      decoration:
                          const InputDecoration(labelText: 'Chỉ số biểu đồ'),
                      items: metrics.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  e.value,
                                  style:
                                      const TextStyle(color: Color(0xFFF8FAFC)),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => metric = v!),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D121F),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.north_east_rounded,
                            size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          'Mức cao nhất: ${number(peak)}',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Chart area
              Container(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: SizedBox(
                  height: 260,
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: math.max(c.maxWidth, daily.length * 64.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final day in daily)
                              Expanded(
                                child: Tooltip(
                                  message:
                                      '${day['date']}: ${number(day[metric])} ${metrics[metric]}',
                                  child: InkWell(
                                    onTap: () => setState(() =>
                                        selectedDate = day['date'] as String),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Semantics(
                                      label:
                                          '${day['date']}, ${metrics[metric]}: ${number(day[metric])}',
                                      button: true,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: Align(
                                              alignment:
                                                  Alignment.bottomCenter,
                                              child: Container(
                                                width: 32,
                                                height: peak == 0
                                                    ? 4
                                                    : ((day[metric] as num) /
                                                            peak *
                                                            180)
                                                        .clamp(4, 180)
                                                        .toDouble(),
                                                decoration: BoxDecoration(
                                                  gradient: selectedDate ==
                                                          day['date']
                                                      ? const LinearGradient(
                                                          colors: [
                                                            Color(0xFF00D2FF),
                                                            Color(0xFF6366F1)
                                                          ],
                                                          begin: Alignment
                                                              .bottomCenter,
                                                          end: Alignment
                                                              .topCenter,
                                                        )
                                                      : const LinearGradient(
                                                          colors: [
                                                            Color(0xFF4338CA),
                                                            Color(0xFF818CF8)
                                                          ],
                                                          begin: Alignment
                                                              .bottomCenter,
                                                          end: Alignment
                                                              .topCenter,
                                                        ),
                                                  borderRadius:
                                                      const BorderRadius
                                                          .vertical(
                                                    top: Radius.circular(8),
                                                  ),
                                                  boxShadow: selectedDate ==
                                                          day['date']
                                                      ? [
                                                          BoxShadow(
                                                            color: const Color(
                                                                    0xFF00D2FF)
                                                                .withValues(
                                                                    alpha: 0.5),
                                                            blurRadius: 10,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          )
                                                        ]
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 1,
                                            color: const Color(0xFF1E293B),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            (day['date'] as String)
                                                .substring(5)
                                                .split('-')
                                                .reversed
                                                .join('/'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: selectedDate ==
                                                      day['date']
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: selectedDate ==
                                                      day['date']
                                                  ? const Color(0xFF00D2FF)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (selected != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D121F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: Color(0xFF00D2FF)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${selected['date']} · ${number(selected['totalTokens'])} token · ${number(selected['requests'])} yêu cầu · ${number(selected['errors'])} lỗi · ${number(selected['unknownUsage'])} chưa có số token',
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Chạm cột để xem chi tiết. Cuộn ngang khi xem nhiều ngày.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Metadata breakdown
        AcademicPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chi tiết hệ thống & Token phụ trợ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Yêu cầu lỗi: ${number(totals['errors'])} · Chưa có metadata token: ${number(totals['unknownUsage'])} · Kiểm tra kết nối: ${number(totals['checks'])}',
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  height: 1.7,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Token cache: ${number(totals['cachedTokens'])} · Token suy luận: ${number(totals['reasoningTokens'])}',
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  height: 1.7,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D121F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cache và suy luận là các phần token provider báo riêng, không cộng thêm lần nữa vào tổng. Tổng token có thể gồm phần khác ngoài đầu vào và đầu ra hiển thị.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data['coverage']}',
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        height: 1.5,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const AcademicHeading(
          'Theo provider và model',
          'Token từ các yêu cầu qua backend trong khoảng thời gian đã chọn.',
        ),

        if ((data['models'] as List).isEmpty)
          const AcademicPanel(
            child: Text(
              'Chưa có yêu cầu được ghi nhận trong khoảng này.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),

        for (final model in (data['models'] as List).whereType<Map>())
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AcademicPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _providerColor(model['provider'] as String?)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _providerColor(model['provider'] as String?)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${model['provider']}'.toUpperCase(),
                          style: TextStyle(
                            color: _providerColor(model['provider'] as String?),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D121F),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: Text(
                          '${model['model']}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Color(0xFF38BDF8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${number(model['totalTokens'])} token · ${number(model['requests'])} yêu cầu · ${number(model['errors'])} lỗi · ${number(model['unknownUsage'])} chưa có số token',
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      height: 1.6,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
