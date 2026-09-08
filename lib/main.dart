import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'calendar_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JenilDiamondApp());
}

class JenilDiamondApp extends StatelessWidget {
  const JenilDiamondApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JENIL DIAMOND',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const SplashPage(),
    );
  }
}

// ============================================================
// SPLASH / OPENING LOGO ANIMATION
// ============================================================

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.45,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.65,
          curve: Curves.easeIn,
        ),
      ),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 170,
                height: 170,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 30,
                      spreadRadius: 5,
                      color: Colors.black.withOpacity(0.12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/logo .png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'JENIL DIAMOND',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Diamond Work Management',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 25),
              const SizedBox(
                width: 35,
                height: 35,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WORKER MODEL
// ============================================================

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

// ============================================================
// WORK ENTRY
// ============================================================

class WorkEntry {
  String worker;
  DateTime date;
  double quantity;
  double rate;

  WorkEntry({
    required this.worker,
    required this.date,
    required this.quantity,
    required this.rate,
  });

  double get total => quantity * rate;

  Map<String, dynamic> toJson() {
    return {
      'worker': worker,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'rate': rate,
    };
  }

  factory WorkEntry.fromJson(Map<String, dynamic> json) {
    return WorkEntry(
      worker: json['worker'] ?? '',
      date: DateTime.parse(json['date']),
      quantity: (json['quantity'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
    );
  }
}

// ============================================================
// PAYMENT
// ============================================================

class Payment {
  String worker;
  DateTime date;
  double amount;

  Payment({
    required this.worker,
    required this.date,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'worker': worker,
      'date': date.toIso8601String(),
      'amount': amount,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      worker: json['worker'] ?? '',
      date: DateTime.parse(json['date']),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

// ============================================================
// APP DATA
// ============================================================

class AppData {
  static final List<Worker> workers = [];
  static final List<WorkEntry> works = [];
  static final List<Payment> payments = [];

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final workersJson = prefs.getString('workers');
    final worksJson = prefs.getString('works');
    final paymentsJson = prefs.getString('payments');

    workers.clear();
    works.clear();
    payments.clear();

    if (workersJson != null) {
      final list = jsonDecode(workersJson) as List;
      workers.addAll(
        list.map(
          (e) => Worker.fromJson(
            Map<String, dynamic>.from(e),
          ),
        ),
      );
    }

    if (worksJson != null) {
      final list = jsonDecode(worksJson) as List;
      works.addAll(
        list.map(
          (e) => WorkEntry.fromJson(
            Map<String, dynamic>.from(e),
          ),
        ),
      );
    }

    if (paymentsJson != null) {
      final list = jsonDecode(paymentsJson) as List;
      payments.addAll(
        list.map(
          (e) => Payment.fromJson(
            Map<String, dynamic>.from(e),
          ),
        ),
      );
    }

    recalculate();
  }

  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'workers',
      jsonEncode(
        workers.map((e) => e.toJson()).toList(),
      ),
    );

    await prefs.setString(
      'works',
      jsonEncode(
        works.map((e) => e.toJson()).toList(),
      ),
    );

    await prefs.setString(
      'payments',
      jsonEncode(
        payments.map((e) => e.toJson()).toList(),
      ),
    );
  }

  static void recalculate() {
    for (final worker in workers) {
      worker.totalWork = 0;
      worker.totalPaid = 0;
    }

    for (final work in works) {
      final worker = workers.where(
        (w) => w.name == work.worker,
      );

      if (worker.isNotEmpty) {
        worker.first.totalWork += work.total;
      }
    }

    for (final payment in payments) {
      final worker = workers.where(
        (w) => w.name == payment.worker,
      );

      if (worker.isNotEmpty) {
        worker.first.totalPaid += payment.amount;
      }
    }
  }

  static Future<void> addWorker(
    String name,
    String mobile,
  ) async {
    workers.add(
      Worker(
        name: name,
        mobile: mobile,
      ),
    );

    await save();
  }

  static Future<void> addWork(
    WorkEntry entry,
  ) async {
    works.add(entry);
    recalculate();
    await save();
  }

  static Future<void> addPayment(
    Payment payment,
  ) async {
    payments.add(payment);
    recalculate();
    await save();
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await AppData.load();

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pages = [
      DashboardPage(
        onRefresh: refresh,
      ),
      WorkersPage(
        onRefresh: refresh,
      ),
      CalendarPage(
        onRefresh: refresh,
      ),
      WorkPage(
        onRefresh: refresh,
      ),
      PaymentsPage(
        onRefresh: refresh,
      ),
    ];

    return Scaffold(
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'હોમ',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'કારીગર',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'કેલેન્ડર',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
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

// ============================================================
// DASHBOARD
// ============================================================

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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JENIL DIAMOND',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await AppData.load();
          onRefresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.diamond,
                      size: 55,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'JENIL DIAMOND',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Diamond Karigar Work & Payment',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _dashboardCard(
                    icon: Icons.people,
                    title: 'કારીગર',
                    value: AppData.workers.length.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dashboardCard(
                    icon: Icons.work,
                    title: 'કામ',
                    value: AppData.works.length.toString(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _dashboardCard(
                    icon: Icons.currency_rupee,
                    title: 'કુલ કામ',
                    value: '₹${totalWork.toStringAsFixed(0)}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dashboardCard(
                    icon: Icons.account_balance_wallet,
                    title: 'ઉપાડ',
                    value: '₹${totalPaid.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  size: 35,
                ),
                title: const Text(
                  'બાકી રકમ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '₹${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// WORKERS PAGE
// ============================================================

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
  final nameController = TextEditingController();
  final mobileController = TextEditingController();

  Future<void> addWorker() async {
    final name = nameController.text.trim();
    final mobile = mobileController.text.trim();

    if (name.isEmpty) {
      return;
    }

    await AppData.addWorker(
      name,
      mobile,
    );

    nameController.clear();
    mobileController.clear();

    if (!mounted) return;

    Navigator.pop(context);
    setState(() {});
    widget.onRefresh();
  }

  void showAddWorkerDialog() {
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
              child: const Text('રદ'),
            ),
            FilledButton(
              onPressed: addWorker,
              child: const Text('સાચવો'),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendSms(Worker worker) async {
    if (worker.mobile.trim().isEmpty) {
      return;
    }

    final message =
        'નમસ્તે ${worker.name}, JENIL DIAMOND માં આપનું કામ અને પેમેન્ટ રેકોર્ડ સાચવવામાં આવ્યું છે.';

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

  void showWorkerHistory(Worker worker) {
    final workerWorks = AppData.works
        .where((w) => w.worker == worker.name)
        .toList();

    final workerPayments = AppData.payments
        .where((p) => p.worker == worker.name)
        .toList();

    workerWorks.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    workerPayments.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(worker.mobile),
                    const SizedBox(height: 10),
                    Text(
                      'કુલ કામ: ₹${worker.totalWork.toStringAsFixed(2)}',
                    ),
                    Text(
                      'કુલ ઉપાડ: ₹${worker.totalPaid.toStringAsFixed(2)}',
                    ),
                    Text(
                      'બાકી: ₹${worker.balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Text(
                      'કામની હિસ્ટરી',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (workerWorks.isEmpty)
                      const Text('કામની હિસ્ટરી નથી.'),

                    ...workerWorks.map(
                      (work) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.work),
                          title: Text(
                            DateFormat('dd-MM-yyyy')
                                .format(work.date),
                          ),
                          subtitle: Text(
                            'જથ્થો: ${work.quantity} × દર: ₹${work.rate}',
                          ),
                          trailing: Text(
                            '₹${work.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'ઉપાડની હિસ્ટરી',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (workerPayments.isEmpty)
                      const Text('ઉપાડની હિસ્ટરી નથી.'),

                    ...workerPayments.map(
                      (payment) => Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.payments,
                          ),
                          title: Text(
                            DateFormat('dd-MM-yyyy')
                                .format(payment.date),
                          ),
                          trailing: Text(
                            '₹${payment.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'કારીગર',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddWorkerDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('કારીગર ઉમેરો'),
      ),
      body: AppData.workers.isEmpty
          ? const Center(
              child: Text(
                'હજુ કોઈ કારીગર નથી.\n+ દબાવીને કારીગર ઉમેરો.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: AppData.workers.length,
              itemBuilder: (context, index) {
                final worker = AppData.workers[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
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
                      '${worker.mobile}\n'
                      'કામ: ₹${worker.totalWork.toStringAsFixed(0)} | '
                      'ઉપાડ: ₹${worker.totalPaid.toStringAsFixed(0)} | '
                      'બાકી: ₹${worker.balance.toStringAsFixed(0)}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'history') {
                          showWorkerHistory(worker);
                        } else if (value == 'sms') {
                          sendSms(worker);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'history',
                          child: Text('હિસ્ટરી'),
                        ),
                        PopupMenuItem(
                          value: 'sms',
                          child: Text('SMS'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// WORK PAGE
// ============================================================

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
  Worker? selectedWorker;

  final quantityController = TextEditingController();
  final rateController = TextEditingController();

  double get total {
    final quantity =
        double.tryParse(quantityController.text) ?? 0;

    final rate =
        double.tryParse(rateController.text) ?? 0;

    return quantity * rate;
  }

  Future<void> saveWork() async {
    if (selectedWorker == null) {
      return;
    }

    final quantity =
        double.tryParse(quantityController.text);

    final rate =
        double.tryParse(rateController.text);

    if (quantity == null || rate == null) {
      return;
    }

    await AppData.addWork(
      WorkEntry(
        worker: selectedWorker!.name,
        date: DateTime.now(),
        quantity: quantity,
        rate: rate,
      ),
    );

    quantityController.clear();
    rateController.clear();

    if (!mounted) return;

    setState(() {});
    widget.onRefresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('કામ સાચવાઈ ગયું છે.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'કામ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AppData.workers.isEmpty
          ? const Center(
              child: Text(
                'પહેલા કારીગર ઉમેરો.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<Worker>(
                  value: selectedWorker,
                  decoration: const InputDecoration(
                    labelText: 'કારીગર પસંદ કરો',
                    border: OutlineInputBorder(),
                  ),
                  items: AppData.workers.map(
                    (worker) {
                      return DropdownMenuItem(
                        value: worker,
                        child: Text(worker.name),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedWorker = value;
                    });
                  },
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'જથ્થો',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: rateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'દર',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'કુલ રકમ',
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: saveWork,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'કામ સાચવો',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'આજનું કામ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                ...AppData.works.reversed.map(
                  (work) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.work),
                      title: Text(work.worker),
                      subtitle: Text(
                        '${DateFormat('dd-MM-yyyy').format(work.date)}\n'
                        '${work.quantity} × ₹${work.rate}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        '₹${work.total.toStringAsFixed(2)}',
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

// ============================================================
// PAYMENTS PAGE
// ============================================================

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
  Worker? selectedWorker;

  final amountController = TextEditingController();

  Future<void> savePayment() async {
    if (selectedWorker == null) {
      return;
    }

    final amount =
        double.tryParse(amountController.text);

    if (amount == null || amount <= 0) {
      return;
    }

    await AppData.addPayment(
      Payment(
        worker: selectedWorker!.name,
        date: DateTime.now(),
        amount: amount,
      ),
    );

    amountController.clear();

    if (!mounted) return;

    setState(() {});
    widget.onRefresh();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ઉપાડ સાચવાઈ ગયો છે.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'પેમેન્ટ / ઉપાડ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AppData.workers.isEmpty
          ? const Center(
              child: Text(
                'પહેલા કારીગર ઉમેરો.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<Worker>(
                  value: selectedWorker,
                  decoration: const InputDecoration(
                    labelText: 'કારીગર પસંદ કરો',
                    border: OutlineInputBorder(),
                  ),
                  items: AppData.workers.map(
                    (worker) {
                      return DropdownMenuItem(
                        value: worker,
                        child: Text(worker.name),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedWorker = value;
                    });
                  },
                ),

                const SizedBox(height: 15),

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

                const SizedBox(height: 20),

                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: savePayment,
                    icon: const Icon(Icons.payments),
                    label: const Text(
                      'ઉપાડ સાચવો',
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'ઉપાડની હિસ્ટરી',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                ...AppData.payments.reversed.map(
                  (payment) => Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.payments,
                      ),
                      title: Text(payment.worker),
                      subtitle: Text(
                        DateFormat('dd-MM-yyyy')
                            .format(payment.date),
                      ),
                      trailing: Text(
                        '₹${payment.amount.toStringAsFixed(2)}',
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
