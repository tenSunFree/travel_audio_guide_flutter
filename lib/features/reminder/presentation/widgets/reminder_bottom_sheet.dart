import 'package:flutter/material.dart';

class ReminderBottomSheetResult {
  const ReminderBottomSheetResult({
    required this.targetTime,
    required this.remindBeforeSeconds,
  });

  final DateTime targetTime;
  final int remindBeforeSeconds;
}

class ReminderBottomSheet extends StatefulWidget {
  const ReminderBottomSheet({
    required this.initialTargetTime,
    super.key,
    this.minTargetTime,
    this.maxTargetTime,
  });

  final DateTime initialTargetTime;
  final DateTime? minTargetTime;
  final DateTime? maxTargetTime;

  @override
  State<ReminderBottomSheet> createState() => _ReminderBottomSheetState();
}

class _ReminderBottomSheetState extends State<ReminderBottomSheet> {
  late DateTime _targetTime;
  int _remindBeforeSeconds = 0;
  bool _showCustom = false;
  int _customHours = 0;
  int _customMinutes = 0;
  int _customSeconds = 0;

  static const List<(String, int)> _presets = [
    ('準時', 0),
    ('5 分鐘前', 5 * 60),
    ('15 分鐘前', 15 * 60),
    ('30 分鐘前', 30 * 60),
    ('1 小時前', 60 * 60),
    ('1 天前', 24 * 60 * 60),
  ];

  @override
  void initState() {
    super.initState();
    _targetTime = widget.initialTargetTime;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '加入提醒',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            const Text('提醒目標時間', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month),
                    const SizedBox(width: 12),
                    Text(_formatDateTime(_targetTime)),
                    const Spacer(),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('提前提醒', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._presets.map(
                  (preset) => ChoiceChip(
                    label: Text(preset.$1),
                    selected: !_showCustom && _remindBeforeSeconds == preset.$2,
                    onSelected: (_) {
                      setState(() {
                        _showCustom = false;
                        _remindBeforeSeconds = preset.$2;
                      });
                    },
                  ),
                ),
                ChoiceChip(
                  label: const Text('自訂'),
                  selected: _showCustom,
                  onSelected: (_) {
                    setState(() {
                      _showCustom = true;
                      _updateCustomSeconds();
                    });
                  },
                ),
              ],
            ),
            if (_showCustom) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '小時',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _customHours = int.tryParse(value) ?? 0;
                        _updateCustomSeconds();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '分鐘',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _customMinutes = int.tryParse(value) ?? 0;
                        _updateCustomSeconds();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '秒',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _customSeconds = int.tryParse(value) ?? 0;
                        _updateCustomSeconds();
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        ReminderBottomSheetResult(
                          targetTime: _targetTime,
                          remindBeforeSeconds: _remindBeforeSeconds,
                        ),
                      );
                    },
                    child: const Text('儲存提醒'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateCustomSeconds() {
    _remindBeforeSeconds =
        _customHours * 3600 + _customMinutes * 60 + _customSeconds;
    setState(() {});
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final firstDate = widget.minTargetTime ?? now;
    final lastDate =
        widget.maxTargetTime ?? now.add(const Duration(days: 365 * 2));
    final date = await showDatePicker(
      context: context,
      initialDate: _targetTime,
      firstDate: DateTime(firstDate.year, firstDate.month, firstDate.day),
      lastDate: DateTime(lastDate.year, lastDate.month, lastDate.day),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_targetTime),
    );
    if (time == null) return;
    setState(() {
      _targetTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _formatDateTime(DateTime time) {
    return '${time.year}/'
        '${time.month.toString().padLeft(2, '0')}/'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
