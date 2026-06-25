import 'package:flutter/material.dart';

import '../models/business.dart';
import '../services/business_service.dart';

class BusinessHoursSettingsPage extends StatefulWidget {
  const BusinessHoursSettingsPage({
    super.key,
    required this.business,
    required this.isDhivehi,
  });

  final Business business;
  final bool isDhivehi;

  @override
  State<BusinessHoursSettingsPage> createState() =>
      _BusinessHoursSettingsPageState();
}

class _BusinessHoursSettingsPageState extends State<BusinessHoursSettingsPage> {
  late bool _openingEnabled;
  late bool _temporarilyClosed;
  late TimeOfDay _openingTime;
  late TimeOfDay _closingTime;
  late Set<String> _openDays;
  bool _saving = false;

  static const List<_DayOption> _days = [
    _DayOption('mon', 'Mon', 'ހޯމަ'),
    _DayOption('tue', 'Tue', 'އަންގާރަ'),
    _DayOption('wed', 'Wed', 'ބުދަ'),
    _DayOption('thu', 'Thu', 'ބުރާސްފަތި'),
    _DayOption('fri', 'Fri', 'ހުކުރު'),
    _DayOption('sat', 'Sat', 'ހޮނިހިރު'),
    _DayOption('sun', 'Sun', 'އާދީއްތަ'),
  ];

  String text(String english, String dhivehi) {
    return widget.isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: widget.isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  void initState() {
    super.initState();
    _openingEnabled = widget.business.openingEnabled;
    _temporarilyClosed = widget.business.temporarilyClosed;
    _openingTime = _parseTime(widget.business.openingTime) ??
        const TimeOfDay(hour: 8, minute: 0);
    _closingTime = _parseTime(widget.business.closingTime) ??
        const TimeOfDay(hour: 22, minute: 0);
    _openDays = widget.business.openDays.toSet();
    if (_openDays.isEmpty) {
      _openDays = _days.map((day) => day.key).toSet();
    }
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime({required bool opening}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: opening ? _openingTime : _closingTime,
    );
    if (selected == null) return;
    setState(() {
      if (opening) {
        _openingTime = selected;
      } else {
        _closingTime = selected;
      }
    });
  }

  Future<void> _save() async {
    if (_openingEnabled && !_temporarilyClosed && _openDays.isEmpty) {
      _showError(text(
        'Choose at least one open day.',
        'ހުޅުވާ ދުވަހެއް ހޮވާ.',
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      await BusinessService.instance.updateBusinessOpeningHours(
        business: widget.business,
        openingEnabled: _openingEnabled,
        openingTime: _formatTime(_openingTime),
        closingTime: _formatTime(_closingTime),
        openDays: _days
            .where((day) => _openDays.contains(day.key))
            .map((day) => day.key)
            .toList(),
        temporarilyClosed: _temporarilyClosed,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text('Opening hours updated.', 'ހުޅުވާ ގަޑި އަޕްޑޭޓްކުރެވިއްޖެ.'),
            style: style(color: Colors.white),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message, style: style(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('Opening Hours', 'ހުޅުވާ ގަޑި'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _openingEnabled,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _openingEnabled = value),
                      secondary: const Icon(Icons.schedule_rounded),
                      title: Text(
                        text('Show opening hours', 'ހުޅުވާ ގަޑި ދައްކާ'),
                        style: style(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        text(
                          'If this is off, clients will only see the shop as open.',
                          'މިއެއް އޮފްނަމަ، ކްލައިންޓަށް ފިހާރަ ހުޅުވިފައިކަމަށް ފެނޭނެ.',
                        ),
                        style: style(fontSize: 12, height: 1.35),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _temporarilyClosed,
                      onChanged: _saving
                          ? null
                          : (value) =>
                              setState(() => _temporarilyClosed = value),
                      secondary: const Icon(Icons.pause_circle_rounded),
                      title: Text(
                        text('Temporarily closed', 'މިހާރު ބަންދު'),
                        style: style(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_openingEnabled && !_temporarilyClosed) ...[
                      const Divider(height: 30),
                      Text(
                        text('Open days', 'ހުޅުވާ ދުވަސްތައް'),
                        style: style(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _days.map((day) {
                          final selected = _openDays.contains(day.key);
                          return FilterChip(
                            selected: selected,
                            label: Text(day.label(widget.isDhivehi), style: style()),
                            onSelected: _saving
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value) {
                                        _openDays.add(day.key);
                                      } else {
                                        _openDays.remove(day.key);
                                      }
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _timeCard(
                              label: text('Opens', 'ހުޅުވާ'),
                              time: _openingTime,
                              icon: Icons.lock_open_rounded,
                              onTap: () => _pickTime(opening: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _timeCard(
                              label: text('Closes', 'ބަންދުވާ'),
                              time: _closingTime,
                              icon: Icons.lock_rounded,
                              onTap: () => _pickTime(opening: false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  text('Save Opening Hours', 'ހުޅުވާ ގަޑި ސޭވްކުރޭ'),
                  style: style(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeCard({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _saving ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 10),
            Text(label, style: style(fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(
              _formatTime(time),
              style: style(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayOption {
  const _DayOption(this.key, this.english, this.dhivehi);

  final String key;
  final String english;
  final String dhivehi;

  String label(bool isDhivehi) => isDhivehi ? dhivehi : english;
}
