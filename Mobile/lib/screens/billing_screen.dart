import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../main.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _billing;

  final List<Map<String, dynamic>> _plans = [
    {
      "name": "Starter",
      "price": "\$0",
      "features": ["1,000 mins/month", "Up to 3 AI agents", "Basic analytics", "Email support"],
    },
    {
      "name": "Professional",
      "price": "\$20",
      "popular": true,
      "features": ["5,000 mins/month", "Up to 5 AI agents", "Advanced analytics", "Priority support", "Voice training"],
    },
    {
      "name": "Enterprise",
      "price": "\$50",
      "features": ["Unlimited minutes", "Up to 10 AI agents", "Full analytics suite", "24/7 support", "Custom voice"],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchBilling();
  }

  Future<void> _fetchBilling() async {
    try {
      final res = await ApiService.getBilling();
      if (res.statusCode == 200) {
        setState(() {
          _billing = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Billing fetch error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _upgradePlan(String planName) async {
    // Determine price amount
    int amount = 0;
    if (planName == "Professional") amount = 20;
    if (planName == "Enterprise") amount = 50;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.createCheckoutSession(planName, amount);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final checkoutUrl = Uri.parse(body['url']);
        
        // Open checkout URL in browser
        if (await canLaunchUrl(checkoutUrl)) {
          await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
        } else {
          throw Exception("Could not open payment window.");
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      _fetchBilling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = _billing?['currentPlan'] ?? "Starter";
    final int usedMins = _billing?['usedMinutes'] ?? 0;
    final int monthlyMins = _billing?['monthlyMinutes'] ?? 1000;
    final double progress = monthlyMins > 0 ? (usedMins / monthlyMins) : 0.0;
    final cardNo = _billing?['paymentMethod']?['cardNumber'] ?? "xxxx";
    final List<dynamic> history = _billing?['paymentHistory'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Subscription & Billing', style: TextStyle(fontWeight: FontWeight.bold)),
      ),

      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Tier Card (Premium Gradient)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CURRENT ACTIVE PLAN', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(currentPlan, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Usage: $usedMins / $monthlyMins minutes", style: const TextStyle(color: Colors.white, fontSize: 13)),
                          Text("${(progress * 100).toStringAsFixed(0)}% Used", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress > 1.0 ? 1.0 : progress,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Available Plans Header
                const Text('Choose Subscription Tier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),

                // Subscription plans horizontal cards
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      final name = plan['name'];
                      final price = plan['price'];
                      final isPopular = plan['popular'] ?? false;
                      final isCurrent = currentPlan == name;

                      return Container(
                        width: 170,
                        margin: const EdgeInsets.only(right: 12, bottom: 8),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isPopular ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: isPopular ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 8),
                                Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                const Text('per month', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                const Spacer(),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isCurrent ? Colors.grey[200] : const Color(0xFF2563EB),
                                    foregroundColor: isCurrent ? Colors.black54 : Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onPressed: isCurrent ? null : () => _upgradePlan(name),
                                  child: Text(
                                    isCurrent ? "Active" : "Upgrade",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Payment details
                const Text('Card Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.credit_card, color: Color(0xFF2563EB)),
                    title: Text("•••• •••• •••• $cardNo"),
                    subtitle: Text("Expires ${_billing?['paymentMethod']?['expiry'] ?? 'N/A'}"),
                  ),
                ),
                const SizedBox(height: 24),

                // Invoice history list
                const Text('Billing Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Card(
                  child: history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text("No billing transactions found.")),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: history.length,
                        separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return ListTile(
                            dense: true,
                            title: Text(item['invoice'] ?? 'Invoice'),
                            subtitle: Text(item['date'] ?? ''),
                            trailing: Text(
                              item['amount'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          );
                        },
                      ),
                )
              ],
            ),
          ),
    );
  }
}
