import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Usage Analytics"),
        backgroundColor: const Color.fromARGB(255, 0, 72, 126),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Requests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          Map<String, int> equipmentUsage = {};
          Map<String, int> monthlyTrends = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            String name = data['Name'] ?? 'Unknown';
            int count = data['count'] ?? 0;
            String month = data['month_year'] ?? 'Unknown';

            // Aggregate by Equipment Name
            equipmentUsage[name] = (equipmentUsage[name] ?? 0) + count;

            // Aggregate by Month
            monthlyTrends[month] = (monthlyTrends[month] ?? 0) + count;
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle("Most Requested Equipment"),
              _buildUsageList(equipmentUsage),
              const SizedBox(height: 24),
              _buildSectionTitle("Monthly Demand Trends"),
              _buildTrendList(monthlyTrends),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildUsageList(Map<String, int> data) {
    var sortedKeys = data.keys.toList()..sort((a, b) => data[b]!.compareTo(data[a]!));
    return Card(
      child: Column(
        children: sortedKeys.take(5).map((key) {
          return ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.blue),
            title: Text(key),
            trailing: Text("${data[key]} units", style: const TextStyle(fontWeight: FontWeight.bold)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendList(Map<String, int> data) {
    return Card(
      child: Column(
        children: data.entries.map((entry) {
          return ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.orange),
            title: Text("Month: ${entry.key}"),
            trailing: Text("${entry.value} checkouts"),
          );
        }).toList(),
      ),
    );
  }
}