// File: lib/features/advisor/advisor_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import 'advisor_logic.dart';

class AdvisorScreen extends StatefulWidget {
  final List<String> inventoryItems;
  const AdvisorScreen({super.key, required this.inventoryItems});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  late List<StorageAdvice> _adviceList;

  @override
  void initState() {
    super.initState();
    _adviceList = AdvisorEngine.getAdvice(widget.inventoryItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("AI Storage Advisor"),
      ),
      body: _adviceList.isEmpty
          ? const Center(child: Text("Add items to your inventory to get advice."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _adviceList.length,
        itemBuilder: (context, index) {
          final advice = _adviceList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                            advice.item,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: advice.days <= 7
                              ? AppColors.error.withOpacity(0.1)
                              : AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${advice.days}d Left",
                          style: TextStyle(
                            color: advice.days <= 7 ? AppColors.error : AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(advice.tip, style: TextStyle(color: Colors.grey[700])),
                  if (index == 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                          "CONSUME SOON",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}