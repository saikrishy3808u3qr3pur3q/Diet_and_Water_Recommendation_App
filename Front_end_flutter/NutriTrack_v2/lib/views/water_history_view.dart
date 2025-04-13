import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class WaterHistoryView extends StatefulWidget {
  final List<Map<String, dynamic>> waterRecords;

  const WaterHistoryView({super.key, required this.waterRecords});

  @override
  State<WaterHistoryView> createState() => _WaterHistoryViewState();
}

class _WaterHistoryViewState extends State<WaterHistoryView> {
  DateTime _selectedDate = DateTime.now(); // Track selected month and year

  @override
  Widget build(BuildContext context) {
    // Get all days in the selected month and year
    final daysInMonth = _getDaysInMonth(_selectedDate);
    final dailyData = _groupRecordsByDay(widget.waterRecords, daysInMonth);

    // Get the increments of 5 (e.g., 1, 6, 11, 16, 21, 26)
    final increments = _getIncrementsOf5(daysInMonth);

    return Scaffold(
      backgroundColor: const Color(0xFF0D46CB), // Dark blue background
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dropdown for month and year selection
            _buildDateDropdown(),
            const SizedBox(height: 20),

            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F5ACE), // Lighter dark blue card
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 5000, // Set max Y to 5000 milliliters (5 liters)
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.blueAccent, // Tooltip background color
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final date = daysInMonth[group.x.toInt()];
                          final amount = rod.toY.toInt();
                          return BarTooltipItem(
                            "Day ${DateFormat('d').format(date)}\n${(amount / 1000).toStringAsFixed(1)} L",
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final date = daysInMonth[value.toInt()];
                            final day = date.day;
                            // Only show increments of 5
                            if (day % 5 == 1 || day == daysInMonth.last.day) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  day.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink(); // Hide other labels
                          },
                          reservedSize: 20, // Ensure enough space for labels
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${(value / 1000).toStringAsFixed(1)} L', // Convert to litres
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                          reservedSize: 40, // Ensure enough space for labels
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1000,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    barGroups: daysInMonth.map((date) {
                      final amount = dailyData[DateFormat('yyyy-MM-dd').format(date)] ?? 0;
                      return BarChartGroupData(
                        x: daysInMonth.indexOf(date),
                        barRods: [
                          BarChartRodData(
                            toY: amount > 5000 ? 5000 : amount, // Cap the bar height at 5000
                            color: _getBarColor(amount),
                            width: 12, // Make the bars thinner
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build dropdown for month and year selection
  Widget _buildDateDropdown() {
    final months = List.generate(12, (index) => index + 1); // 1-12 for months
    final years = List.generate(10, (index) => DateTime.now().year - 5 + index); // Last 5 years and next 5 years

    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Center the dropdowns
      children: [
        // Month Dropdown
        DropdownButton<int>(
          value: _selectedDate.month,
          onChanged: (value) {
            setState(() {
              _selectedDate = DateTime(_selectedDate.year, value!, 1);
            });
          },
          items: months.map((month) {
            return DropdownMenuItem<int>(
              value: month,
              child: Text(
                DateFormat('MMMM').format(DateTime(2023, month)), // Format month name
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
          dropdownColor: const Color(0xFF1F5ACE),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
          underline: Container(
            height: 2,
            color: Colors.cyanAccent,
          ),
        ),
        const SizedBox(width: 20),
        // Year Dropdown
        DropdownButton<int>(
          value: _selectedDate.year,
          onChanged: (value) {
            setState(() {
              _selectedDate = DateTime(value!, _selectedDate.month, 1);
            });
          },
          items: years.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(
                year.toString(),
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
          dropdownColor: const Color(0xFF1F5ACE),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
          underline: Container(
            height: 2,
            color: Colors.cyanAccent,
          ),
        ),
      ],
    );
  }

  // Get all days in the selected month and year
  List<DateTime> _getDaysInMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    final daysInMonth = <DateTime>[];

    for (var i = 0; i < lastDay.day; i++) {
      daysInMonth.add(DateTime(date.year, date.month, i + 1));
    }

    return daysInMonth;
  }

  // Get increments of 5 (e.g., 1, 6, 11, 16, 21, 26)
  List<DateTime> _getIncrementsOf5(List<DateTime> daysInMonth) {
    return daysInMonth.where((date) => date.day % 5 == 1 || date.day == daysInMonth.last.day).toList();
  }

  // Group records by day and pre-populate with 0 for missing days
  Map<String, double> _groupRecordsByDay(List<Map<String, dynamic>> records, List<DateTime> daysInMonth) {
    final Map<String, double> dailyData = {};

    // Initialize all days with 0
    for (var date in daysInMonth) {
      dailyData[DateFormat('yyyy-MM-dd').format(date)] = 0;
    }

    // Add actual records
    for (var record in records) {
      final date = DateFormat('yyyy-MM-dd').format(record['time']);
      if (dailyData.containsKey(date)) {
        dailyData[date] = (dailyData[date] ?? 0) + record['amount'];
      }
    }

    return dailyData;
  }

  Color _getBarColor(double value) {
    if (value >= 3000) {
      return Colors.greenAccent.shade400.withOpacity(0.6); // Pale green
    } else if (value >= 1500) {
      return Colors.blueAccent.shade400.withOpacity(0.6); // Pale blue
    } else {
      return Colors.redAccent.shade400.withOpacity(0.6); // Pale red
    }
  }
}