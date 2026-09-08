import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'calendar_page.dart';
void main() {
  runApp(const JenilDiamondApp());
}

class JenilDiamondApp extends StatelessWidget {
  const JenilDiamondApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JENIL DIAMOND',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      ),
      home: const HomePage(),
    );
  }
}

class Worker {
  String name;
  String mobile;
  double totalWork;
  double totalPaid;

  Worker({
    required this.name,
    required this.mobile,
    this.totalWork = 0,
    this.totalPaid = 0,
  });

  double get balance => totalWork - totalPaid;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'totalWork': totalWork,
      'totalPaid': totalPaid,
    };
  }

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      totalWork: (json['totalWork'] ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] ?? 0).toDouble(),
    );
  }
}

class WorkEntry {
  String worker;
  String date;
  double quantity;
  double rate;
  double total;

  WorkEntry({
    required this.worker,
    required this.date,
    required this.quantity,
    required this.rate,
  }) : total = quantity * rate;

  Map<String, dynamic> toJson() {
    return {
      'worker': worker,
      'date': date,
      'quantity': quantity,
      'rate': rate,
      'total': total,
    };
  }

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      worker: json['worker'] ?? '',
      date: json['date'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
    );
  }
}

class Payment {
  String worker;
  String date;
  double amount;

  Payment({
    required this.worker,
    required this.date,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'worker': worker,
      'date': date,
      'amount': amount,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      worker: json['worker'] ?? '',
      date: json['date'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class AppData {
  static List<Worker> workers = [];
  static List<WorkEntry> works = [];
  static List<Payment> payments = [];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final workersData = prefs.getString('workers');
    final worksData = prefs.getString('works');
    final paymentsData = prefs.getString('payments');

    if (workersData != null) {
      final list = jsonDecode(workersData) as List;
      workers = list
          .map((item) => Worker.fromJson(item))
          .toList();
    }

    if (worksData != null) {
      final list = jsonDecode(worksData) as List;
      works = list
          .map((item) => WorkEntry.fromJson(item))
          .toList();
    }

    if (paymentsData != null) {
      final list = jsonDecode(paymentsData) as List;
      payments = list
          .map((item) => Payment.fromJson(item))
          .toList();
    }
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'workers',
      jsonEncode(
        workers.map((worker) => worker.toJson()).toList(),
      ),
    );

    await prefs.setString(
      'works',
      jsonEncode(
        works.map((work) => work.toJson()).toList(),
      ),
    );

    await prefs.setString(
      'payments',
      jsonEncode(
        payments.map((payment) => payment.toJson()).toList(),
      ),
    );
  }

  static void recalculate() {
    for (final worker in workers) {
      worker.totalWork = 0;
      worker.totalPaid = 0;

      for (final work in works) {
        if (work.worker == worker.name) {
          worker.totalWork += work.total;
        }
      }

      for (final payment in payments) {
        if (payment.worker == worker.name) {
          worker.totalPaid += payment.amount;
        }
      }
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await AppData.load();
    AppData.recalculate();
    setState(() {});
  }

  void refresh() {
    AppData.recalculate();
    AppData.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(onRefresh: refresh),
      WorkersPage(onRefresh: refresh),
      WorkPage(onRefresh: refresh),
      PaymentsPage(onRefresh: refresh),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
  children: [
    Image.asset(
      'assets/logo .png',
      height: 40,
    ),
    const SizedBox(width: 10),
    const Text(
      'JENIL DIAMOND',
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
  ],
),
        centerTitle: true,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'હોમ',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'કારીગર',
          ),
          NavigationDestination(
            icon: Icon(Icons.diamond_outlined),
            selectedIcon: Icon(Icons.diamond),
            label: 'કામ',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'પેમેન્ટ',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  final VoidCallback onRefresh;

  const DashboardPage({
    super.key,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    double totalWork = 0;
    double totalPaid = 0;

    for (final worker in AppData.workers) {
      totalWork += worker.totalWork;
      totalPaid += worker.totalPaid;
    }

    final balance = totalWork - totalPaid;

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1565C0),
                  Color(0xFF42A5F5),
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JENIL DIAMOND',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Diamond Karigar Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'કારીગર',
                  AppData.workers.length.toString(),
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  'કામ',
                  AppData.works.length.toString(),
                  Icons.diamond,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _moneyCard(
                  'કુલ કામ',
                  totalWork,
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _moneyCard(
                  'ચૂકવણી',
                  totalPaid,
                  Icons.payments,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _balanceCard(balance),
          const SizedBox(height: 24),
          const Text(
            'કારીગરોની સ્થિતિ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (AppData.workers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'હજુ કોઈ કારીગર ઉમેર્યો નથી',
                  ),
                ),
              ),
            )
          else
            ...AppData.workers.map(
              (worker) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      worker.name.isNotEmpty
                          ? worker.name[0]
                          : '?',
                    ),
                  ),
                  title: Text(worker.name),
                  subtitle: Text(
                    'કામ: ₹${worker.totalWork.toStringAsFixed(0)}',
                  ),
                  trailing: Text(
                    'બાકી\n₹${worker.balance.toStringAsFixed(0)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: worker.balance > 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _moneyCard(
    String title,
    double amount,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(double balance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.pending_actions,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text('કુલ બાકી'),
                  Text(
                    '₹${balance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkersPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const WorkersPage({
    super.key,
    required this.onRefresh,
  });

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  void addWorker() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('નવો કારીગર'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'કારીગરનું નામ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'મોબાઇલ નંબર',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('રદ કરો'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  return;
                }

                AppData.workers.add(
                  Worker(
                    name: nameController.text.trim(),
                    mobile: mobileController.text.trim(),
                  ),
                );

                await AppData.save();

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context);
                widget.onRefresh();
                setState(() {});
              },
              child: const Text('ઉમેરો'),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendSms(Worker worker) async {
    if (worker.mobile.isEmpty) {
      return;
    }

    final message =
        'નમસ્તે ${worker.name}, JENIL DIAMOND તરફથી તમારા કામની બાકી રકમ ₹${worker.balance.toStringAsFixed(0)} છે.';

    final uri = Uri(
      scheme: 'sms',
      path: worker.mobile,
      queryParameters: {
        'body': message,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addWorker,
        icon: const Icon(Icons.person_add),
        label: const Text('કારીગર ઉમેરો'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'કારીગરોની યાદી',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (AppData.workers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    'કોઈ કારીગર નથી\n\n+ કારીગર ઉમેરો',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            ...AppData.workers.map(
              (worker) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      child: Text(
                        worker.name.isNotEmpty
                            ? worker.name[0]
                            : '?',
                      ),
                    ),
                    title: Text(
                      worker.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${worker.mobile}\nબાકી: ₹${worker.balance.toStringAsFixed(0)}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.sms),
                      onPressed: () => sendSms(worker),
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

class WorkPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const WorkPage({
    super.key,
    required this.onRefresh,
  });

  @override
  State<WorkPage> createState() => _WorkPageState();
}

class _WorkPageState extends State<WorkPage> {
  void addWork() {
    if (AppData.workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('પહેલા કારીગર ઉમેરો'),
        ),
      );
      return;
    }

    String selectedWorker =
        AppData.workers.first.name;

    final quantityController = TextEditingController();
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double quantity =
                double.tryParse(quantityController.text) ?? 0;
            double rate =
                double.tryParse(rateController.text) ?? 0;
            double total = quantity * rate;

            return AlertDialog(
              title: const Text('નવું કામ'),
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
                      items: AppData.workers
                          .map(
                            (worker) =>
                                DropdownMenuItem<String>(
                              value: worker.name,
                              child: Text(worker.name),
                            ),
                          )
                          .toList(),
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
                      onChanged: (_) => setDialogState(() {}),
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
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'રેટ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(12),
                        color: Colors.blue.withOpacity(0.1),
                      ),
                      child: Text(
                        'કુલ: ₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('રદ કરો'),
                ),
                FilledButton(
                  onPressed: () async {
                    final q = double.tryParse(
                          quantityController.text,
                        ) ??
                        0;
                    final r = double.tryParse(
                          rateController.text,
                        ) ??
                        0;

                    if (q <= 0 || r <= 0) {
                      return;
                    }

                    AppData.works.add(
                      WorkEntry(
                        worker: selectedWorker,
                        date: DateFormat('dd-MM-yyyy')
                            .format(DateTime.now()),
                        quantity: q,
                        rate: r,
                      ),
                    );

                    AppData.recalculate();
                    await AppData.save();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pop(context);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addWork,
        icon: const Icon(Icons.add),
        label: const Text('કામ ઉમેરો'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'કામની એન્ટ્રી',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (AppData.works.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    'હજુ કોઈ કામની એન્ટ્રી નથી',
                  ),
                ),
              ),
            )
          else
            ...AppData.works.reversed.map(
              (work) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.diamond),
                  ),
                  title: Text(work.worker),
                  subtitle: Text(
                    '${work.date}\n${work.quantity} × ₹${work.rate}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    '₹${work.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

class PaymentsPage extends StatefulWidget {
  final VoidCallback onRefresh;

  const PaymentsPage({
    super.key,
    required this.onRefresh,
  });

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  void addPayment() {
    if (AppData.workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('પહેલા કારીગર ઉમેરો'),
        ),
      );
      return;
    }

    String selectedWorker =
        AppData.workers.first.name;

    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('પેમેન્ટ ઉમેરો'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedWorker,
                    decoration: const InputDecoration(
                      labelText: 'કારીગર',
                      border: OutlineInputBorder(),
                    ),
                    items: AppData.workers
                        .map(
                          (worker) =>
                              DropdownMenuItem<String>(
                            value: worker.name,
                            child: Text(worker.name),
                          ),
                        )
                        .toList(),
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
                      labelText: 'રકમ',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('રદ કરો'),
                ),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                          amountController.text,
                        ) ??
                        0;

                    if (amount <= 0) {
                      return;
                    }

                    AppData.payments.add(
                      Payment(
                        worker: selectedWorker,
                        date: DateFormat('dd-MM-yyyy')
                            .format(DateTime.now()),
                        amount: amount,
                      ),
                    );

                    AppData.recalculate();
                    await AppData.save();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pop(context);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addPayment,
        icon: const Icon(Icons.add),
        label: const Text('પેમેન્ટ ઉમેરો'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'પેમેન્ટની યાદી',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (AppData.payments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    'હજુ કોઈ પેમેન્ટ નથી',
                  ),
                ),
              ),
            )
          else
            ...AppData.payments.reversed.map(
              (payment) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.payments),
                  ),
                  title: Text(payment.worker),
                  subtitle: Text(payment.date),
                  trailing: Text(
                    '₹${payment.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 17,
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
