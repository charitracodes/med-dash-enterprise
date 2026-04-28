import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; 
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isDarkMode = true;

  // 1. MASTER DATA STORE
  final List<Map<String, dynamic>> _allAppointments = [
    {"name": "Charitra Jain", "doctor": "Dr. Sharma", "time": "10:00 AM", "status": "Confirmed", "color": Colors.greenAccent},
    {"name": "Rahul Gupta", "doctor": "Dr. Verma", "time": "11:30 AM", "status": "Pending", "color": Colors.orangeAccent},
    {"name": "Sneha Singh", "doctor": "Dr. Sharma", "time": "01:00 PM", "status": "Cancelled", "color": Colors.redAccent},
  ];

  List<Map<String, dynamic>> _foundAppointments = [];

  @override
  void initState() {
    _foundAppointments = _allAppointments;
    super.initState();
  }

  // DYNAMIC THEME HELPERS
  Color get bgColor => isDarkMode ? const Color(0xFF0F111A) : const Color(0xFFF5F7FB);
  Color get cardColor => isDarkMode ? const Color(0xFF1A1D2E) : Colors.white;
  Color get sideColor => isDarkMode ? const Color(0xFF08090F) : const Color(0xFF1E1E2C);
  Color get textColor => isDarkMode ? Colors.white : Colors.black87;
  Color get subTextColor => isDarkMode ? Colors.white38 : Colors.grey;

  // 2. CORE LOGIC
  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = enteredKeyword.isEmpty 
      ? _allAppointments 
      : _allAppointments.where((u) => u["name"].toLowerCase().contains(enteredKeyword.toLowerCase())).toList();
    setState(() => _foundAppointments = results);
  }

  void _updateStatus(int masterIndex, String newStatus, Color newColor) {
    setState(() {
      _allAppointments[masterIndex]["status"] = newStatus;
      _allAppointments[masterIndex]["color"] = newColor;
      _runFilter(""); 
    });
  }

  // 3. ENHANCED EXPORT LOGIC WITH FILTERING
  void _exportCSV({String? filterStatus}) {
    List<List<dynamic>> rows = [["Name", "Doctor", "Time", "Status"]];
    
    // Determine which list to export
    Iterable<Map<String, dynamic>> exportList = _foundAppointments;
    if (filterStatus != null) {
      exportList = _foundAppointments.where((a) => a["status"] == filterStatus);
    }

    if (exportList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No records found for this filter."))
      );
      return;
    }

    for (var app in exportList) {
      rows.add([app["name"], app["doctor"], app["time"], app["status"]]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final url = html.Url.createObjectUrlFromBlob(html.Blob([utf8.encode(csv)]));
    String fileName = filterStatus == null ? "all_patients" : "${filterStatus.toLowerCase()}_patients";
    
    html.AnchorElement(href: url)
      ..setAttribute("download", "${fileName}_report.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // 4. ADD PATIENT DIALOG
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final docCtrl = TextEditingController();
    final timeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
        child: AlertDialog(
          backgroundColor: cardColor,
          title: Text("New Consultation", style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Patient Name")),
              TextField(controller: docCtrl, decoration: const InputDecoration(labelText: "Doctor Name")),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: "Time")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _allAppointments.add({
                      "name": nameCtrl.text,
                      "doctor": docCtrl.text,
                      "time": timeCtrl.text,
                      "status": "Pending",
                      "color": Colors.orangeAccent,
                    });
                    _runFilter(""); 
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int activeCount = _allAppointments.where((a) => a["status"] == "Confirmed").length;

    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 240,
            color: sideColor,
            child: Column(
              children: [
                const DrawerHeader(child: Icon(Icons.local_hospital, color: Colors.blueAccent, size: 50)),
                _sidebarItem(Icons.dashboard, "Overview", true),
                _sidebarItem(Icons.people, "Patients", false),
                const Spacer(),
                ListTile(
                  leading: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.orangeAccent),
                  title: Text(isDarkMode ? "Light Mode" : "Dark Mode", style: const TextStyle(color: Colors.white70)),
                  onTap: () => setState(() => isDarkMode = !isDarkMode),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // MAIN CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER WITH POPUP EXPORT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Med-Dash Enterprise", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                      Row(
                        children: [
                          // NEW: POPUP EXPORT BUTTON
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'all') _exportCSV();
                              if (val == 'confirmed') _exportCSV(filterStatus: 'Confirmed');
                              if (val == 'pending') _exportCSV(filterStatus: 'Pending');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.white10 : Colors.blueGrey,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.download, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text("Export Report", style: TextStyle(color: Colors.white)),
                                  Icon(Icons.arrow_drop_down, color: Colors.white),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'all', child: Text("Export All Visible")),
                              const PopupMenuItem(value: 'confirmed', child: Text("Export Confirmed Only")),
                              const PopupMenuItem(value: 'pending', child: Text("Export Pending Only")),
                            ],
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton.icon(
                            onPressed: _showAddDialog,
                            icon: const Icon(Icons.add),
                            label: const Text("New Patient"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.all(18)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // DYNAMIC CARDS
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildStatCard("Total Registry", _allAppointments.length.toString(), Icons.folder, Colors.blueAccent),
                      _buildStatCard("Active Cases", activeCount.toString(), Icons.bolt, Colors.greenAccent),
                      _buildStatCard("Needs Follow-up", (_allAppointments.length - activeCount).toString(), Icons.history, Colors.orangeAccent),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // CHART
                  _buildAnalyticsChart(activeCount.toDouble()),
                  const SizedBox(height: 30),

                  // SEARCH
                  Container(
                    width: 400,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: subTextColor.withOpacity(0.2))),
                    child: TextField(
                      style: TextStyle(color: textColor),
                      onChanged: (value) => _runFilter(value),
                      decoration: InputDecoration(hintText: 'Search registry...', hintStyle: TextStyle(color: subTextColor), border: InputBorder.none, icon: Icon(Icons.search, color: subTextColor)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DATA TABLE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
                    child: Theme(
                      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Patient")),
                          DataColumn(label: Text("Doctor")),
                          DataColumn(label: Text("Status (Click to Edit)")),
                        ],
                        rows: _foundAppointments.asMap().entries.map((entry) {
                          var data = entry.value;
                          int masterIdx = _allAppointments.indexOf(data);

                          return DataRow(cells: [
                            DataCell(Text(data["name"], style: TextStyle(color: textColor))),
                            DataCell(Text(data["doctor"], style: TextStyle(color: textColor))),
                            DataCell(
                              PopupMenuButton<String>(
                                child: Chip(
                                  label: Text(data["status"], style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                                  backgroundColor: data["color"],
                                ),
                                onSelected: (val) {
                                  if (val == 'Confirmed') _updateStatus(masterIdx, 'Confirmed', Colors.greenAccent);
                                  if (val == 'Pending') _updateStatus(masterIdx, 'Pending', Colors.orangeAccent);
                                  if (val == 'Cancelled') _updateStatus(masterIdx, 'Cancelled', Colors.redAccent);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'Confirmed', child: Text("Set Confirmed")),
                                  const PopupMenuItem(value: 'Pending', child: Text("Set Pending")),
                                  const PopupMenuItem(value: 'Cancelled', child: Text("Set Cancelled")),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
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

  Widget _buildAnalyticsChart(double active) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [FlSpot(0, 2), FlSpot(1, active), FlSpot(2, 4), FlSpot(3, 1), FlSpot(4, 5)],
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 4,
              belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, bool selected) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.blueAccent : Colors.white24),
      title: Text(title, style: TextStyle(color: selected ? Colors.white : Colors.white24)),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: subTextColor)),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }
}