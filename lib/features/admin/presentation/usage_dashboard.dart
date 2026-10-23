import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
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
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final totals = data['totals'] as Map;
    final daily = (data['daily'] as List).whereType<Map>().toList();
    final peak = daily.fold<double>(
        0, (v, day) => math.max(v, (day[metric] as num).toDouble()));
    final selected = daily.where((v) => v['date'] == selectedDate).firstOrNull;
    return ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          Wrap(spacing: 16, runSpacing: 16, children: [
            SizedBox(
                width: 200,
                child: DropdownButtonFormField<int>(
                    initialValue: widget.days,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Khoảng thời gian'),
                    items: [7, 14, 30]
                        .map((n) => DropdownMenuItem(
                            value: n, child: Text('$n ngày gần nhất')))
                        .toList(),
                    onChanged: (v) => widget.onDays(v!))),
            SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                    initialValue: widget.provider,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Provider'),
                    items: ['', 'gemini', 'openai', 'groq']
                        .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v.isEmpty ? 'Tất cả provider' : v)))
                        .toList(),
                    onChanged: (v) => widget.onProvider(v!))),
          ]),
          const SizedBox(height: 20),
          Text('${data['from']} → ${data['to']} · Giờ Việt Nam (UTC+7)',
              style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          AcademicGrid(minWidth: 220, children: [
            for (final item in [
              ('Token đã xác nhận', 'totalTokens'),
              ('Token đầu vào', 'inputTokens'),
              ('Token đầu ra', 'outputTokens'),
              ('Yêu cầu chat', 'requests')
            ])
              AcademicPanel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(number(totals[item.$2]),
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(item.$1)
                  ])),
          ]),
          const SizedBox(height: 20),
          AcademicPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Sử dụng theo ngày',
                    style:
                        TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                        initialValue: metric,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Chỉ số biểu đồ'),
                        items: metrics.entries
                            .map((e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => metric = v!))),
                const SizedBox(height: 20),
                Text('Mức cao nhất: ${number(peak)}',
                    style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 12),
                SizedBox(
                    height: 260,
                    child: LayoutBuilder(
                        builder: (context, c) => SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                                width:
                                    math.max(c.maxWidth, daily.length * 58.0),
                                child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (final day in daily)
                                        Expanded(
                                            child: Tooltip(
                                                message:
                                                    '${day['date']}: ${number(day[metric])} ${metrics[metric]}',
                                                child: InkWell(
                                                    onTap: () => setState(() =>
                                                        selectedDate =
                                                            day['date']
                                                                as String),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Semantics(
                                                        label:
                                                            '${day['date']}, ${metrics[metric]}: ${number(day[metric])}',
                                                        button: true,
                                                        child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Flexible(
                                                                  child: Align(
                                                                      alignment:
                                                                          Alignment
                                                                              .bottomCenter,
                                                                      child: Container(
                                                                          width:
                                                                              28,
                                                                          height: peak == 0
                                                                              ? 0
                                                                              : ((day[metric] as num) / peak * 180).clamp(0, 180).toDouble(),
                                                                          decoration: BoxDecoration(color: selectedDate == day['date'] ? AppColors.textPrimary : AppColors.primary, borderRadius: const BorderRadius.vertical(top: Radius.circular(7)))))),
                                                              Container(
                                                                  height: 1,
                                                                  color: const Color(
                                                                      0xFFE2E8F0)),
                                                              const SizedBox(
                                                                  height: 10),
                                                              Text(
                                                                  (day['date']
                                                                          as String)
                                                                      .substring(
                                                                          5)
                                                                      .split(
                                                                          '-')
                                                                      .reversed
                                                                      .join(
                                                                          '/'),
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          11)),
                                                              const SizedBox(
                                                                  height: 12),
                                                            ]))))),
                                    ]))))),
                if (selected != null) ...[
                  const SizedBox(height: 16),
                  Text(
                      '${selected['date']} · ${number(selected['totalTokens'])} token · ${number(selected['requests'])} yêu cầu · ${number(selected['errors'])} lỗi · ${number(selected['unknownUsage'])} chưa có số token',
                      style: const TextStyle(height: 1.6)),
                ],
                const SizedBox(height: 12),
                const Text(
                    'Chạm cột để xem chi tiết. Cuộn ngang khi xem nhiều ngày.',
                    style: TextStyle(color: AppColors.textMuted)),
              ])),
          const SizedBox(height: 16),
          AcademicPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    'Yêu cầu lỗi: ${number(totals['errors'])} · Chưa có metadata token: ${number(totals['unknownUsage'])} · Kiểm tra kết nối: ${number(totals['checks'])}',
                    style: const TextStyle(height: 1.7)),
                const SizedBox(height: 12),
                Text(
                    'Token cache: ${number(totals['cachedTokens'])} · Token suy luận: ${number(totals['reasoningTokens'])}',
                    style: const TextStyle(height: 1.7)),
                const SizedBox(height: 12),
                const Text(
                    'Cache và suy luận là các phần token provider báo riêng, không cộng thêm lần nữa vào tổng. Tổng token có thể gồm phần khác ngoài đầu vào và đầu ra hiển thị.'),
                const SizedBox(height: 12),
                Text('${data['coverage']}',
                    style: const TextStyle(
                        color: AppColors.textMuted, height: 1.7)),
              ])),
          const AcademicHeading('Theo provider và model',
              'Token từ các yêu cầu qua backend trong khoảng thời gian đã chọn.'),
          if ((data['models'] as List).isEmpty)
            const AcademicPanel(
                child: Text('Chưa có yêu cầu được ghi nhận trong khoảng này.')),
          for (final model in (data['models'] as List).whereType<Map>())
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AcademicPanel(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${model['provider']} · ${model['model']}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                          '${number(model['totalTokens'])} token · ${number(model['requests'])} yêu cầu · ${number(model['errors'])} lỗi · ${number(model['unknownUsage'])} chưa có số token',
                          style: const TextStyle(height: 1.7)),
                    ]))),
        ]);
  }
}
