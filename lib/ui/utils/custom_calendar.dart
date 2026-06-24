// import 'package:flutter/material.dart';
//
// class CustomCalendar extends StatefulWidget {
//   final DateTime initialDate;
//   final Function(DateTime selectedDate)? onDateSelected;
//
//   const CustomCalendar({
//     super.key,
//     required this.initialDate,
//     this.onDateSelected,
//   });
//
//   @override
//   State<CustomCalendar> createState() => _CustomCalendarState();
// }
//
// class _CustomCalendarState extends State<CustomCalendar> {
//   late DateTime selectedDate;
//   late DateTime weekStartDate;
//
//   @override
//   void initState() {
//     super.initState();
//     selectedDate = widget.initialDate;
//     weekStartDate = selectedDate.subtract(
//       Duration(days: selectedDate.weekday - 1),
//     );
//   }
//
//   List<DateTime> get weekDays =>
//       List.generate(7, (i) => weekStartDate.add(Duration(days: i)));
//
//   String getMonthName(int month) {
//     const months = [
//       '',
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December',
//     ];
//
//     return months[month];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               getMonthName(selectedDate.month),
//               style: const TextStyle(
//                 fontSize: 15,
//                 color: Colors.black87,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//
//             const Spacer(),
//
//             IconButton(
//               onPressed: () {
//                 setState(() {
//                   weekStartDate = weekStartDate.subtract(
//                     const Duration(days: 7),
//                   );
//
//                   selectedDate = weekStartDate;
//                 });
//
//                 widget.onDateSelected?.call(selectedDate);
//               },
//               icon: const Icon(Icons.chevron_left),
//             ),
//
//             IconButton(
//               onPressed: () {
//                 setState(() {
//                   weekStartDate = weekStartDate.add(const Duration(days: 7));
//
//                   selectedDate = weekStartDate;
//                 });
//
//                 widget.onDateSelected?.call(selectedDate);
//               },
//               icon: const Icon(Icons.chevron_right),
//             ),
//           ],
//         ),
//
//         const SizedBox(height: 8),
//
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: weekDays.map((date) {
//             final isSelected =
//                 date.year == selectedDate.year &&
//                 date.month == selectedDate.month &&
//                 date.day == selectedDate.day;
//
//             return GestureDetector(
//               onTap: () {
//                 setState(() {
//                   selectedDate = date;
//                 });
//
//                 widget.onDateSelected?.call(date);
//               },
//               child: Container(
//                 width: 42,
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 decoration: BoxDecoration(
//                   color: isSelected
//                       ? const Color(0xFFDDF4EB)
//                       : Colors.transparent,
//                   borderRadius: BorderRadius.circular(10),
//                   border: isSelected
//                       ? Border.all(color: const Color(0xFF008C5E))
//                       : null,
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       [
//                         'Mon',
//                         'Tue',
//                         'Wed',
//                         'Thu',
//                         'Fri',
//                         'Sat',
//                         'Sun',
//                       ][date.weekday - 1],
//                       style: const TextStyle(
//                         fontSize: 11,
//                         color: Colors.black54,
//                       ),
//                     ),
//
//                     const SizedBox(height: 6),
//
//                     Text(
//                       date.day.toString(),
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                         color: isSelected
//                             ? const Color(0xFF008C5E)
//                             : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
// }
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

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get minDate => today.subtract(const Duration(days: 7));

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  @override
  void initState() {
    super.initState();

    final initial = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );

    // Clamp initial date within allowed range
    if (initial.isAfter(today)) {
      selectedDate = today;
    } else if (initial.isBefore(minDate)) {
      selectedDate = minDate;
    } else {
      selectedDate = initial;
    }

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
    final previousWeekStart =
    weekStartDate.subtract(const Duration(days: 7));
    final nextWeekStart = weekStartDate.add(const Duration(days: 7));

    final canGoPrevious =
        previousWeekStart.add(const Duration(days: 6)).isAfter(minDate) ||
            isSameDay(
              previousWeekStart.add(const Duration(days: 6)),
              minDate,
            );

    final canGoNext =
        nextWeekStart.isBefore(today) ||
            isSameDay(nextWeekStart, today);

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

            /// Previous Week
            IconButton(
              onPressed: canGoPrevious
                  ? () {
                setState(() {
                  weekStartDate = previousWeekStart;

                  if (selectedDate.isBefore(weekStartDate)) {
                    selectedDate = weekStartDate;
                  }
                });

                widget.onDateSelected?.call(selectedDate);
              }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),

            /// Next Week
            IconButton(
              onPressed: canGoNext
                  ? () {
                setState(() {
                  weekStartDate = nextWeekStart;

                  if (weekStartDate.isAfter(today)) {
                    weekStartDate = today.subtract(
                      Duration(days: today.weekday - 1),
                    );
                  }

                  if (selectedDate.isBefore(weekStartDate) ||
                      selectedDate.isAfter(
                        weekStartDate.add(
                          const Duration(days: 6),
                        ),
                      )) {
                    selectedDate = today;
                  }
                });

                widget.onDateSelected?.call(selectedDate);
              }
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays.map((date) {
            final isSelected = isSameDay(date, selectedDate);

            final isDisabled =
                date.isBefore(minDate) || date.isAfter(today);

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                setState(() {
                  selectedDate = date;
                });

                widget.onDateSelected?.call(date);
              },
              child: Opacity(
                opacity: isDisabled ? 0.4 : 1,
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
                          'Sun',
                        ][date.weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          color: isDisabled
                              ? Colors.grey
                              : Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDisabled
                              ? Colors.grey
                              : isSelected
                              ? const Color(0xFF008C5E)
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}