import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(ExpenseSplitterApp());
}

class ExpenseSplitterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Splitter',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: SplashScreen(),
    );
  }
}

// ---------------- Splash Screen ----------------
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ExpenseSplitterScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet,
                size: 80, color: Colors.teal[800]),
            SizedBox(height: 20),
            Text(
              "Welcome to Expense Splitter",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[900]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "- by Satwika Pulluri",
              style: TextStyle(
                  fontSize: 18, fontStyle: FontStyle.italic, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Main Screen ----------------
class ExpenseSplitterScreen extends StatefulWidget {
  @override
  _ExpenseSplitterScreenState createState() => _ExpenseSplitterScreenState();
}

class _ExpenseSplitterScreenState extends State<ExpenseSplitterScreen> {
  final List<Map<String, dynamic>> people = [];
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  List<String> results = [];

  // ---------------- Cache ----------------
  final Map<String, List<String>> _cache = {};

  // ---------------- Add person ----------------
  void addPerson() {
    String name = nameController.text.trim();
    double? amount = double.tryParse(amountController.text);

    if (name.isNotEmpty && amount != null) {
      setState(() {
        people.add({"name": name, "amount": amount});
        nameController.clear();
        amountController.clear();
        results.clear();
      });
    }
  }

  // ---------------- Calculate Payments using caching ----------------
  void calculatePayments() {
    if (people.isEmpty) return;

    // Serialize input for cache key
    String key = people.map((p) => "${p["name"]}:${p["amount"]}").join("|");
    if (_cache.containsKey(key)) {
      // Use cached result
      setState(() {
        results = _cache[key]!;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Result loaded from cache")),
      );
      return;
    }

    // ----- Algorithm -----
    double total = people.fold(0, (sum, p) => sum + p["amount"]);
    double share = total / people.length;

    Map<String, double> balances = {};
    for (var p in people) {
      balances[p["name"]] = p["amount"] - share;
    }

    List<String> resultList = [];

    var debtors = balances.entries.where((e) => e.value < 0).toList();
    var creditors = balances.entries.where((e) => e.value > 0).toList();

    for (var debtor in debtors) {
      double debt = -debtor.value;
      for (var i = 0; i < creditors.length; i++) {
        if (creditors[i].value <= 0) continue;

        double payment = debt < creditors[i].value ? debt : creditors[i].value;
        if (payment > 0) {
          resultList.add(
              "${debtor.key} has to pay ${creditors[i].key} ₹${payment.toStringAsFixed(2)}");
          debt -= payment;
          creditors[i] = MapEntry(creditors[i].key, creditors[i].value - payment);
        }
      }
    }

    // Store result in cache
    _cache[key] = resultList;

    setState(() {
      results = resultList;
    });
  }

  // ---------------- Reset all ----------------
  void resetAll() {
    setState(() {
      people.clear();
      results.clear();
      nameController.clear();
      amountController.clear();
      _cache.clear();
    });
  }

  // ---------------- Delete person ----------------
  void deletePerson(int index) {
    setState(() {
      people.removeAt(index);
      results.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expense Splitter"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    decoration: InputDecoration(labelText: "Amount Spent"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.teal, size: 30),
                  onPressed: addPerson,
                ),
              ],
            ),
            SizedBox(height: 20),

            // List of people with delete
            Expanded(
              child: ListView.builder(
                itemCount: people.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(people[index]["name"][0]),
                      backgroundColor: Colors.teal[200],
                    ),
                    title: Text(people[index]["name"]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("₹${people[index]["amount"].toStringAsFixed(2)}"),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deletePerson(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: calculatePayments,
              child: Text("Calculate Payments"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
            SizedBox(height: 10),
            OutlinedButton(
              onPressed: resetAll,
              child: Text("Reset"),
            ),
            SizedBox(height: 20),

            // Results
            if (results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        results[index],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
