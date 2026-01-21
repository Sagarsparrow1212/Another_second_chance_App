import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  DateTime selectedMonth = DateTime.now();

  // Example attendance data - replace with API data
  final Map<int, String> attendanceData = {
    1: 'present',
    2: 'present',
    3: 'present',
    4: 'weekoff',
    5: 'present',
    6: 'absent',
    7: 'present',
    8: 'present',
    9: 'present',
    10: 'present',
    11: 'weekoff',
    12: 'halfday',
    13: 'present',
    14: 'present',
    15: 'present',
    16: 'present',
    17: 'present',
    18: 'weekoff',
    19: 'present',
    20: 'present',
    21: 'present',
    22: 'present',
    23: 'present',
    24: 'present',
    25: 'weekoff',
    26: 'present',
    27: 'present',
    28: 'present',
    29: 'paidleave',
    30: 'present',
    31: 'present',
  };

  void changeMonth(int offset) {
    setState(() {
      final year = selectedMonth.year;
      final month = selectedMonth.month + offset;
      selectedMonth = DateTime(year, month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final year = selectedMonth.year;
    final month = selectedMonth.month;

    final firstDay = DateTime(year, month, 1);
    final totalDays = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDay.weekday;
    final startOffset = firstWeekday % 7;

    final innerContent = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight -
              32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSummaryGrid(),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Color(0xff101725),
                borderRadius: BorderRadius.circular(16),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.1),
                //     blurRadius: 20,
                //     spreadRadius: 0,
                //     offset: const Offset(0, 4),
                //   ),
                // ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month navigation bar
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF9966CC), // Purple
                            Color(0xFF87CEEB), // Sky Blue
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                            onPressed: () => changeMonth(-1),
                          ),
                          Text(
                            '${_getMonthName(month)} $year',
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                            onPressed: () => changeMonth(1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Weekday Headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _WeekdayHeader('Sun'),
                        _WeekdayHeader('Mon'),
                        _WeekdayHeader('Tue'),
                        _WeekdayHeader('Wed'),
                        _WeekdayHeader('Thu'),
                        _WeekdayHeader('Fri'),
                        _WeekdayHeader('Sat'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Calendar Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 5,
                            crossAxisSpacing: 5,
                            childAspectRatio: 1,
                          ),
                      itemCount: totalDays + startOffset,
                      itemBuilder: (context, index) {
                        if (index < startOffset) {
                          return const SizedBox();
                        }
                        final day = index - startOffset + 1;
                        final status = attendanceData[day];
                        return _buildDayCell(day, status, year, month);
                      },
                    ),
                    // const SizedBox(height: 20),
                    // Legend
                    _buildLegend(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget bodyWrapper;

    // Calculate required intrinsic height for the main "fixed" content
    final mediaQuery = MediaQuery.of(context);
    final verticalPadding = 16.0 * 2 + mediaQuery.padding.top + kToolbarHeight;
    final availableHeight = mediaQuery.size.height - verticalPadding;

    // Estimate height of the major content (summary grid + calendar card)
    // We want to only scroll if the content is taller than available height.
    // Otherwise, keep centered.
    // For simplicity, we use a LayoutBuilder and SingleChildScrollView/Align swap.

    bodyWrapper = LayoutBuilder(
      builder: (context, constraints) {
        // max height of content is ~summaryCards + spacing + card + spacing
        // We can hardcode an approximate minimum for the summary+calendar (it's very regular)
        // If total content height > constraints.maxHeight, use scroll; else, center directly

        // Estimate: summaryGrid ~70, spacing 16, card ~510, total ~600
        const minContentHeight = 600.0;

        if (constraints.maxHeight <= minContentHeight) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: innerContent,
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: innerContent,
          );
        }
      },
    );

    return Scaffold(
      // extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xff030712),
      appBar: AppBar(
        backgroundColor: const Color(0xff030712),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Attendance',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Track your daily attendance',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: bodyWrapper,
    );
  }

  Widget _buildSummaryGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        buildBalanceCard(
          item: BalanceItem(
            balance: 22,
            title: 'Present',
            cardColor: const Color(0xFF2BD9A8),
          ),
        ),
        buildBalanceCard(
          item: BalanceItem(
            balance: 2,
            title: 'Absent',
            cardColor: const Color(0xFFFF6B6B),
          ),
        ),
        buildBalanceCard(
          item: BalanceItem(
            balance: 1,
            title: 'Half Day',
            cardColor: const Color(0xFFFFC857),
          ),
        ),
        buildBalanceCard(
          item: BalanceItem(
            balance: 4,
            title: 'Week Off',
            cardColor: const Color(0xFF9CA3AF),
          ),
        ),
        buildBalanceCard(
          item: BalanceItem(
            balance: 3,
            title: 'Paid Leave',
            cardColor: const Color(0xFF6C8CFF),
          ),
        ),
      ],
    );
  }

  Widget buildBalanceCard({required BalanceItem item}) {
    return Container(
      width: 90,
      height: 58,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: item.cardColor!.withOpacity(0.1),
        border: Border.all(color: item.cardColor!.withOpacity(0.6), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.balance.toString(),
            style: TextStyle(
              fontFamily: 'Poppins',
              color: item.cardColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            item.title.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: item.cardColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day, String? status, int year, int month) {
    Color bgColor = Colors.grey.shade300;
    Color textColor = Colors.black87;

    switch (status) {
      case 'present':
        bgColor = Color(0xFF00d492);
        textColor = Colors.white;
        break;
      case 'absent':
        bgColor = Color(0xffff637e);
        textColor = Colors.white;
        break;
      case 'weekoff':
        bgColor = Color(0xffd1d5dc);
        textColor = Colors.white;
        break;
      case 'paidleave':
        bgColor = Color(0xff50a2ff);
        textColor = Colors.white;
        break;
      case 'halfday':
        bgColor = Color(0xffffb900);
        textColor = Colors.white;

      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.black87;
    }

    // Check if this day is after today
    final today = DateTime.now();
    final cellDate = DateTime(year, month, day);
    final isFutureDate = cellDate.isAfter(
      DateTime(today.year, today.month, today.day),
    );

    // Reduce opacity for future dates
    final bgAlpha = isFutureDate ? 0.00 : 0.35;
    final borderAlpha = isFutureDate ? 0.0 : 0.7;

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: bgColor.withValues(alpha: borderAlpha),
          width: 1,
        ),
        color: bgColor.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        day.toString().padLeft(2, '0'),
        style: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          // color: Color(0xFF004f3b),
          // color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(Colors.green, 'Present'),
        const SizedBox(width: 16),
        _LegendItem(Colors.red, 'Absent'),
        const SizedBox(width: 16),
        _LegendItem(Colors.grey.shade400, 'Week Off'),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}

class BalanceItem {
  int balance;
  String? title;
  Color? cardColor;

  BalanceItem({this.balance = 0, this.cardColor, this.title});
}

class _WeekdayHeader extends StatelessWidget {
  final String label;

  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}
