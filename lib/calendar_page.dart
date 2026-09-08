import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class CalendarPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const CalendarPage({
    super.key,
    required this.onRefresh,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedDate = DateTime(2026, 1, 1);

  String get selectedDateString {
    return DateFormat('dd-MM-yyyy').format(selectedDate);
  }

  // Check whether two dates are the same day.
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  List<WorkEntry> get selectedWorks {
    return AppData.works
        .where((work) => isSameDay(work.date, selectedDate))
        .toList();
  }

  List<Payment> get selectedPayments {
    return AppData.payments
        .where((payment) => isSameDay(payment.date, selectedDate))
        .toList();
  }

  bool hasEntry(DateTime date) {
    return AppData.works.any(
          (work) => isSameDay(work.date, date),
        ) ||
        AppData.payments.any(
          (payment) => isSameDay(payment.date, date),
        );
  }

  void selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  void previousMonth() {
    if (selectedDate.month == 1) return;

    setState(() {
      selectedDate = DateTime(
        2026,
        selectedDate.month - 1,
        1,
      );
    });
  }

  void nextMonth() {
    if (selectedDate.month == 12) return;

    setState(() {
      selectedDate = DateTime(
        2026,
        selectedDate.month + 1,
        1,
      );
    });
  }

  Future<void> addWorkForDate() async {
    if (AppData.workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('પહેલા કારીગર ઉમેરો'),
        ),
      );
      return;
    }

    String selectedWorker = AppData.workers.first.name;

    final quantityController = TextEditingController();
    final rateController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final quantity =
                double.tryParse(quantityController.text) ?? 0;

            final rate =
                double.tryParse(rateController.text) ?? 0;

            final total = quantity * rate;

            return AlertDialog(
              title: Text(
                'કામ ઉમેરો\n$selectedDateString',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedWorker,
                      decoration: const InputDecoration(
                        labelText: 'કારીગર',
                        border: OutlineInputBorder(),
                      ),
                      items: AppData.workers.map((worker) {
                        return DropdownMenuItem<String>(
                          value: worker.name,
                          child: Text(worker.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedWorker = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: quantityController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'ક્વોન્ટિટી',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: rateController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'રેટ',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      'કુલ: ₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('રદ કરો'),
                ),

                FilledButton(
                  onPressed: () async {
                    final quantity =
                        double.tryParse(
                              quantityController.text,
                            ) ??
                            0;

                    final rate =
                        double.tryParse(
                              rateController.text,
                            ) ??
                            0;

                    if (quantity <= 0 || rate <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('ક્વોન્ટિટી અને રેટ દાખલ કરો'),
                        ),
                      );
                      return;
                    }

                    AppData.works.add(
                      WorkEntry(
                        worker: selectedWorker,
                        date: selectedDate,
                        quantity: quantity,
                        rate: rate,
                      ),
                    );

                    AppData.recalculate();
                    await AppData.save();

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    widget.onRefresh();

                    setState(() {});
                  },
                  child: const Text('સેવ કરો'),
                ),
              ],
            );
          },
        );
      },
    );

    quantityController.dispose();
    rateController.dispose();
  }

  Future<void> addPaymentForDate() async {
    if (AppData.workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('પહેલા કારીગર ઉમેરો'),
        ),
      );
      return;
    }

    String selectedWorker = AppData.workers.first.name;

    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'ઉપાડ ઉમેરો\n$selectedDateString',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedWorker,
                    decoration: const InputDecoration(
                      labelText: 'કારીગર',
                      border: OutlineInputBorder(),
                    ),
                    items: AppData.workers.map((worker) {
                      return DropdownMenuItem<String>(
                        value: worker.name,
                        child: Text(worker.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedWorker = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'ઉપાડની રકમ',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('રદ કરો'),
                ),

                FilledButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(
                              amountController.text,
                            ) ??
                            0;

                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ઉપાડની રકમ દાખલ કરો'),
                        ),
                      );
                      return;
                    }

                    AppData.payments.add(
                      Payment(
                        worker: selectedWorker,
                        date: selectedDate,
                        amount: amount,
                      ),
                    );

                    AppData.recalculate();
                    await AppData.save();

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    widget.onRefresh();

                    setState(() {});
                  },
                  child: const Text('સેવ કરો'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthName =
        DateFormat('MMMM yyyy').format(selectedDate);

    final firstDay =
        DateTime(selectedDate.year, selectedDate.month, 1);

    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;

    final startWeekday = firstDay.weekday;

    final cells = <Widget>[];

    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(
        selectedDate.year,
        selectedDate.month,
        day,
      );

      final isSelected =
          date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;

      final entryExists = hasEntry(date);

      cells.add(
        GestureDetector(
          onTap: () => selectDate(date),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : entryExists
                      ? Colors.blue.withOpacity(0.10)
                      : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                if (entryExists)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.white
                          : Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '📅 2026 કેલેન્ડર',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: previousMonth,
                        icon: const Icon(
                          Icons.chevron_left,
                        ),
                      ),

                      Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      IconButton(
                        onPressed: nextMonth,
                        icon: const Icon(
                          Icons.chevron_right,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: const [
                      _WeekDay('સોમ'),
                      _WeekDay('મંગળ'),
                      _WeekDay('બુધ'),
                      _WeekDay('ગુરુ'),
                      _WeekDay('શુક્ર'),
                      _WeekDay('શનિ'),
                      _WeekDay('રવિ'),
                    ],
                  ),

                  const SizedBox(height: 6),

                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    children: cells,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.event,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'પસંદ કરેલી તારીખ\n$selectedDateString',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: addWorkForDate,
                  icon: const Icon(Icons.diamond),
                  label: const Text('કામ'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: FilledButton.icon(
                  onPressed: addPaymentForDate,
                  icon: const Icon(Icons.payments),
                  label: const Text('ઉપાડ'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Text(
            'આ તારીખનું કામ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          if (selectedWorks.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'આ તારીખે કોઈ કામની એન્ટ્રી નથી.',
                ),
              ),
            )
          else
            ...selectedWorks.map(
              (work) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.diamond),
                  ),
                  title: Text(work.worker),
                  subtitle: Text(
                    '${work.quantity} × ₹${work.rate}',
                  ),
                  trailing: Text(
                    '₹${work.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 15),

          const Text(
            'આ તારીખનો ઉપાડ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          if (selectedPayments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'આ તારીખે કોઈ ઉપાડની એન્ટ્રી નથી.',
                ),
              ),
            )
          else
            ...selectedPayments.map(
              (payment) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.payments),
                  ),
                  title: Text(payment.worker),
                  subtitle: Text(
                    DateFormat('dd-MM-yyyy')
                        .format(payment.date),
                  ),
                  trailing: Text(
                    '₹${payment.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  final String text;

  const _WeekDay(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
