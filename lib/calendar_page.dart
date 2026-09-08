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

  String get dateText {
    return DateFormat('dd-MM-yyyy').format(selectedDate);
  }

  bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  List<WorkEntry> get selectedWorks {
    return AppData.works
        .where((work) => sameDay(work.date, selectedDate))
        .toList();
  }

  List<Payment> get selectedPayments {
    return AppData.payments
        .where((payment) => sameDay(payment.date, selectedDate))
        .toList();
  }

  bool hasEntry(DateTime date) {
    return AppData.works.any(
          (work) => sameDay(work.date, date),
        ) ||
        AppData.payments.any(
          (payment) => sameDay(payment.date, date),
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

  // ==================================================
  // WORK ADD
  // ==================================================

  Future<void> addWork() async {
    if (AppData.workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('પહેલા કારીગર ઉમેરો'),
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AddWorkDialog(
          date: selectedDate,
        );
      },
    );

    if (result == true && mounted) {
      setState(() {});
      widget.onRefresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('કામ સફળતાપૂર્વક સેવ થયું'),
        ),
      );
    }
  }

  // ==================================================
  // PAYMENT ADD
  // ==================================================

  Future<void> addPayment() async {
    if (AppData.workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('પહેલા કારીગર ઉમેરો'),
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AddPaymentDialog(
          date: selectedDate,
        );
      },
    );

    if (result == true && mounted) {
      setState(() {});
      widget.onRefresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ઉપાડ સફળતાપૂર્વક સેવ થયો'),
        ),
      );
    }
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final monthName =
        DateFormat('MMMM yyyy').format(selectedDate);

    final firstDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      1,
    );

    final daysInMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    ).day;

    final firstWeekday = firstDay.weekday;

    final List<Widget> cells = [];

    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(
        selectedDate.year,
        selectedDate.month,
        day,
      );

      final selected = sameDay(
        date,
        selectedDate,
      );

      final exists = hasEntry(date);

      cells.add(
        InkWell(
          onTap: () => selectDate(date),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                  : exists
                      ? Colors.blue.withOpacity(0.10)
                      : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: selected
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                if (exists)
                  Container(
                    margin:
                        const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
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

          // CALENDAR
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

                  const Row(
                    children: [
                      WeekDay('સોમ'),
                      WeekDay('મંગળ'),
                      WeekDay('બુધ'),
                      WeekDay('ગુરુ'),
                      WeekDay('શુક્ર'),
                      WeekDay('શનિ'),
                      WeekDay('રવિ'),
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

          // SELECTED DATE
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
                      'પસંદ કરેલી તારીખ\n$dateText',
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

          // BUTTONS
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: addWork,
                  icon: const Icon(Icons.diamond),
                  label: const Text('કામ'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: addPayment,
                  icon: const Icon(Icons.payments),
                  label: const Text('ઉપાડ'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // WORK HISTORY
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
              (work) {
                return Card(
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
                );
              },
            ),

          const SizedBox(height: 15),

          // PAYMENT HISTORY
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
              (payment) {
                return Card(
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
                );
              },
            ),
        ],
      ),
    );
  }
}

// ======================================================
// WORK DIALOG
// ======================================================

class AddWorkDialog extends StatefulWidget {
  final DateTime date;

  const AddWorkDialog({
    super.key,
    required this.date,
  });

  @override
  State<AddWorkDialog> createState() =>
      _AddWorkDialogState();
}

class _AddWorkDialogState
    extends State<AddWorkDialog> {
  int selectedWorkerIndex = 0;

  final quantityController =
      TextEditingController();

  final rateController =
      TextEditingController();

  String error = '';

  @override
  void dispose() {
    quantityController.dispose();
    rateController.dispose();
    super.dispose();
  }

  Future<void> saveWork() async {
    final quantity =
        double.tryParse(
              quantityController.text.trim(),
            ) ??
            0;

    final rate =
        double.tryParse(
              rateController.text.trim(),
            ) ??
            0;

    if (quantity <= 0 || rate <= 0) {
      setState(() {
        error =
            'ક્વોન્ટિટી અને રેટ દાખલ કરો';
      });
      return;
    }

    if (AppData.workers.isEmpty) {
      setState(() {
        error = 'પહેલા કારીગર ઉમેરો';
      });
      return;
    }

    final worker =
        AppData.workers[selectedWorkerIndex];

    AppData.works.add(
      WorkEntry(
        worker: worker.name,
        date: widget.date,
        quantity: quantity,
        rate: rate,
      ),
    );

    AppData.recalculate();

    await AppData.save();

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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

    final total = quantity * rate;

    return AlertDialog(
      title: Text(
        'કામ ઉમેરો\n${DateFormat('dd-MM-yyyy').format(widget.date)}',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // WORKER SELECT
            InkWell(
              onTap: () async {
                final index =
                    await showDialog<int>(
                  context: context,
                  builder: (_) {
                    return SimpleDialog(
                      title: const Text(
                        'કારીગર પસંદ કરો',
                      ),
                      children: List.generate(
                        AppData.workers.length,
                        (index) {
                          return SimpleDialogOption(
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(index);
                            },
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Text(
                                    AppData
                                        .workers[index]
                                        .name,
                                  ),
                                ),
                                if (index ==
                                    selectedWorkerIndex)
                                  const Icon(
                                    Icons.check,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );

                if (index != null && mounted) {
                  setState(() {
                    selectedWorkerIndex = index;
                  });
                }
              },
              borderRadius:
                  BorderRadius.circular(8),
              child: InputDecorator(
                decoration:
                    const InputDecoration(
                  labelText: 'કારીગર',
                  border:
                      OutlineInputBorder(),
                  suffixIcon:
                      Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  AppData
                      .workers[
                          selectedWorkerIndex]
                      .name,
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration:
                  const InputDecoration(
                labelText: 'ક્વોન્ટિટી',
                border:
                    OutlineInputBorder(),
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
                setState(() {});
              },
              decoration:
                  const InputDecoration(
                labelText: 'રેટ',
                prefixText: '₹ ',
                border:
                    OutlineInputBorder(),
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

            if (error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('રદ કરો'),
        ),
        FilledButton(
          onPressed: saveWork,
          child: const Text('સેવ કરો'),
        ),
      ],
    );
  }
}

// ======================================================
// PAYMENT DIALOG
// ======================================================

class AddPaymentDialog extends StatefulWidget {
  final DateTime date;

  const AddPaymentDialog({
    super.key,
    required this.date,
  });

  @override
  State<AddPaymentDialog> createState() =>
      _AddPaymentDialogState();
}

class _AddPaymentDialogState
    extends State<AddPaymentDialog> {
  int selectedWorkerIndex = 0;

  final amountController =
      TextEditingController();

  String error = '';

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> savePayment() async {
    final amount =
        double.tryParse(
              amountController.text.trim(),
            ) ??
            0;

    if (amount <= 0) {
      setState(() {
        error =
            'ઉપાડની રકમ દાખલ કરો';
      });
      return;
    }

    if (AppData.workers.isEmpty) {
      setState(() {
        error = 'પહેલા કારીગર ઉમેરો';
      });
      return;
    }

    final worker =
        AppData.workers[selectedWorkerIndex];

    AppData.payments.add(
      Payment(
        worker: worker.name,
        date: widget.date,
        amount: amount,
      ),
    );

    AppData.recalculate();

    await AppData.save();

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'ઉપાડ ઉમેરો\n${DateFormat('dd-MM-yyyy').format(widget.date)}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WORKER SELECT
          InkWell(
            onTap: () async {
              final index =
                  await showDialog<int>(
                context: context,
                builder: (_) {
                  return SimpleDialog(
                    title: const Text(
                      'કારીગર પસંદ કરો',
                    ),
                    children: List.generate(
                      AppData.workers.length,
                      (index) {
                        return SimpleDialogOption(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(index);
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  AppData
                                      .workers[index]
                                      .name,
                                ),
                              ),
                              if (index ==
                                  selectedWorkerIndex)
                                const Icon(
                                  Icons.check,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );

              if (index != null && mounted) {
                setState(() {
                  selectedWorkerIndex = index;
                });
              }
            },
            borderRadius:
                BorderRadius.circular(8),
            child: InputDecorator(
              decoration:
                  const InputDecoration(
                labelText: 'કારીગર',
                border:
                    OutlineInputBorder(),
                suffixIcon:
                    Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                AppData
                    .workers[
                        selectedWorkerIndex]
                    .name,
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: amountController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration:
                const InputDecoration(
              labelText: 'ઉપાડની રકમ',
              prefixText: '₹ ',
              border:
                  OutlineInputBorder(),
            ),
          ),

          if (error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              error,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('રદ કરો'),
        ),
        FilledButton(
          onPressed: savePayment,
          child: const Text('સેવ કરો'),
        ),
      ],
    );
  }
}

// ======================================================
// WEEK DAYS
// ======================================================

class WeekDay extends StatelessWidget {
  final String text;

  const WeekDay(this.text, {super.key});

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
