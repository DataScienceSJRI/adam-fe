import 'package:adam/ui/utils/custom_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:adam/data/models/weight_log_model.dart';
import 'package:adam/data/repositories/weight_log_repository.dart';
import 'package:adam/ui/utils/custom_snackbar.dart';
import 'package:adam/ui/utils/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeightLogScreen extends StatefulWidget {
  const WeightLogScreen({super.key});

  @override
  State<WeightLogScreen> createState() => _WeightLogScreenState();
}

class _WeightLogScreenState extends State<WeightLogScreen> {
  final WeightRepository _repository = WeightRepository();

  final TextEditingController _weightController = TextEditingController();

  List<WeightHistoryModel> _loggedWeights = [];

  bool _isLoadingLogs = true;

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadWeights();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadWeights() async {
    try {
      final data = await _repository.fetchWeights();

      if (!mounted) return;

      setState(() {
        _loggedWeights = data;
        _isLoadingLogs = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingLogs = false;
      });

      AppSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _saveWeight() async {
    if (_weightController.text.trim().isEmpty) {
      AppSnackBar.show(
        context,
        message: "Please enter weight",
        type: SnackBarType.error,
      );
      return;
    }

    try {
      await _repository.logWeight(
        WeightLogModel(
          weight: double.parse(_weightController.text),
          date: DateFormat('yyyy-MM-dd').format(selectedDate),
        ),
      );

      _weightController.clear();

      await _loadWeights();

      AppSnackBar.show(
        context,
        message: "Weight saved successfully",
        type: SnackBarType.success,
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
      );
    }
  }

  List<WeightHistoryModel> get _filteredWeights {
    final selected = DateFormat('yyyy-MM-dd').format(selectedDate);

    final filtered = _loggedWeights.where((item) {
      try {
        final itemDate = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime.parse(item.date));

        return itemDate == selected;
      } catch (_) {
        return false;
      }
    }).toList();

    filtered.sort(
          (a, b) => DateTime.parse(
        b.date,
      ).compareTo(DateTime.parse(a.date)),
    );

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FA),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Colors.black87,
            ),
          ),
        ),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Weight Tracker",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Track your weight journey",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                _loadWeights();
              },
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F5132)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomCalendar(
                initialDate: selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Log Weight",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "72.5",
                          suffixText: "kg",
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saveWeight,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F5132),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Save Weight",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// CHART
              if (_loggedWeights.length > 1) _buildWeightChart(),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Text(
                    "History",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F5132).withOpacity(.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_filteredWeights.length} entries",
                      style: const TextStyle(
                        color: Color(0xFF0F5132),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _isLoadingLogs
                  ? Center(child: Shimmer.list())
                  : _filteredWeights.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.monitor_weight_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "No weight logs yet",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredWeights.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _filteredWeights.reversed.toList()[index];

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.03),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 54,
                                width: 54,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF198754,
                                  ).withOpacity(.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.monitor_weight,
                                  color: Color(0xFF198754),
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${item.weight.toStringAsFixed(1)} kg",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        "dd MMM yyyy",
                                      ).format(DateTime.parse(item.date)),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              PopupMenuButton(
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text("Edit"),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text("Delete"),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditWeightDialog(item);
                                  } else {
                                    _deleteWeight(item);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    if (_loggedWeights.isEmpty) return const SizedBox();

    final latest = _loggedWeights.last.weight;
    final first = _loggedWeights.first.weight;
    final change = latest - first;

    final isLoss = change < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F5132), Color(0xFF198754)],
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.monitor_weight_rounded,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),

          Text(
            "${latest.toStringAsFixed(1)} kg",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              isLoss
                  ? "↓ ${change.abs().toStringAsFixed(1)} kg lost"
                  : "↑ ${change.toStringAsFixed(1)} kg gained",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    if (_loggedWeights.length < 2) {
      return const SizedBox();
    }

    final sortedWeights = [
      ..._loggedWeights,
    ]..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    final minWeight = sortedWeights
        .map((e) => e.weight)
        .reduce((a, b) => a < b ? a : b);

    final maxWeight = sortedWeights
        .map((e) => e.weight)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weight Trend",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: LineChart(
              LineChartData(
                minY: minWeight - 2,
                maxY: maxWeight + 2,

                gridData: FlGridData(show: true, drawVerticalLine: false),

                borderData: FlBorderData(show: false),

                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,

                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= sortedWeights.length) {
                          return const SizedBox();
                        }

                        final date = DateTime.parse(sortedWeights[index].date);

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('dd/MM').format(date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                lineBarsData: [
                  LineChartBarData(
                    spots: sortedWeights
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
                        .toList(),

                    isCurved: true,
                    barWidth: 4,

                    gradient: const LinearGradient(
                      colors: [Color(0xFF198754), Color(0xFF0F5132)],
                    ),

                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: const Color(0xFF198754),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),

                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF198754).withOpacity(.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWeight(WeightHistoryModel item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Weight"),
          content: const Text(
            "Are you sure you want to delete this weight entry?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _repository.deleteWeight(item.id);

      await _loadWeights();

      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: "Weight deleted successfully",
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
      );
    }
  }

  void _showEditWeightDialog(WeightHistoryModel item) {
    final weightController = TextEditingController(
      text: item.weight.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Edit Weight",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Weight",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: "72.5",
                      suffixText: "kg",
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final updatedWeight = double.parse(
                          weightController.text,
                        );

                        await _repository.editWeight(
                          weightId: item.id,
                          model: WeightLogModel(
                            weight: updatedWeight,
                            date: item.date,
                          ),
                        );

                        if (!mounted) return;

                        Navigator.pop(context);

                        await _loadWeights();

                        if (!mounted) return;

                        AppSnackBar.show(
                          this.context,
                          message: "Weight updated successfully",
                          type: SnackBarType.success,
                        );
                      } catch (e) {
                        if (!mounted) return;

                        AppSnackBar.show(
                          this.context,
                          message: e.toString(),
                          type: SnackBarType.error,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Update Weight",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
