import 'package:flutter/material.dart';

class CustomCalendar extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime selectedDate)? onDateSelected;

  const CustomCalendar({
    super.key,
    required this.initialDate,
    this.onDateSelected,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime selectedDate;
  late DateTime weekStartDate;

  @override
  void initState() {
    super.initState();

    selectedDate = widget.initialDate;

    weekStartDate = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
  }

  List<DateTime> get weekDays =>
      List.generate(7, (i) => weekStartDate.add(Duration(days: i)));

  String getMonthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              getMonthName(selectedDate.month),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            IconButton(
              onPressed: () {
                setState(() {
                  weekStartDate = weekStartDate.subtract(
                    const Duration(days: 7),
                  );

                  selectedDate = weekStartDate;
                });

                widget.onDateSelected?.call(selectedDate);
              },
              icon: const Icon(Icons.chevron_left),
            ),

            IconButton(
              onPressed: () {
                setState(() {
                  weekStartDate = weekStartDate.add(
                    const Duration(days: 7),
                  );

                  selectedDate = weekStartDate;
                });

                widget.onDateSelected?.call(selectedDate);
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays.map((date) {
            final isSelected =
                date.year == selectedDate.year &&
                    date.month == selectedDate.month &&
                    date.day == selectedDate.day;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedDate = date;
                });

                widget.onDateSelected?.call(date);
              },
              child: Container(
                width: 42,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFDDF4EB)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(
                    color: const Color(0xFF008C5E),
                  )
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ][date.weekday - 1],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF008C5E)
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}