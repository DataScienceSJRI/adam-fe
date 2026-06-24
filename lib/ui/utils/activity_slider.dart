import 'package:flutter/material.dart';

class ActivitySliderCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final double minutes;
  final Set<int> selectedDays;
  final ValueChanged<double> onMinutesChanged;
  final ValueChanged<Set<int>> onDaysChanged;

  const ActivitySliderCard({
    super.key,
    required this.title,
    required this.icon,
    required this.minutes,
    required this.selectedDays,
    required this.onMinutesChanged,
    required this.onDaysChanged,
  });

  List<String> get days => const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  State<ActivitySliderCard> createState() => _ActivitySliderCardState();
}

class _ActivitySliderCardState extends State<ActivitySliderCard> {
  late double _currentMinutes;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _currentMinutes = widget.minutes;
    _selectedDays = Set<int>.from(widget.selectedDays);
  }

  @override
  void didUpdateWidget(covariant ActivitySliderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDays != oldWidget.selectedDays) {
      _selectedDays = Set<int>.from(widget.selectedDays);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: Theme.of(context).primaryColorDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                "${_currentMinutes.toInt()} min",
                style: TextStyle(
                  color: Theme.of(context).primaryColorDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.grey.shade300,
              inactiveTrackColor: Colors.grey.shade300,
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              thumbColor: Theme.of(context).primaryColorDark,
            ),
            child: Slider(
              value: _currentMinutes,
              min: 0,
              max: 60,
              label: _currentMinutes.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _currentMinutes = value;
                });
              },
              onChangeEnd: (value) {
                widget.onMinutesChanged(value);
              },
            ),
          ),
          if (_currentMinutes > 0) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "DAYS PER WEEK",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.days.length, (index) {
                final isSelected = _selectedDays.contains(index);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected
                          ? _selectedDays.remove(index)
                          : _selectedDays.add(index);
                    });
                    widget.onDaysChanged(_selectedDays);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColorDark
                            : Colors.grey.shade300,
                      ),
                      color: isSelected
                          ? Theme.of(context).primaryColorDark
                          : Colors.transparent,
                    ),
                    child: Text(
                      widget.days[index],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
