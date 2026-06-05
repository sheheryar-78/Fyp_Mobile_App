import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _calls = [];
  String _selectedSentiment = ""; // Empty means "All"

  @override
  void initState() {
    super.initState();
    _fetchCalls();
  }

  Future<void> _fetchCalls() async {
    try {
      final res = await ApiService.getCalls();
      if (res.statusCode == 200) {
        setState(() {
          _calls = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Calls fetch error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rateCall(String callId, int stars, StateSetter setModalState) async {
    try {
      final res = await ApiService.rateCall(callId, stars);
      if (res.statusCode == 200) {
        final updatedCall = jsonDecode(res.body);
        setState(() {
          _calls = _calls.map((call) => call['_id'] == callId ? updatedCall : call).toList();
        });
        setModalState(() {
          // Dynamic update of current active bottom sheet
          _selectedCall = updatedCall;
        });
      }
    } catch (e) {
      debugPrint("Rating call error: $e");
    }
  }

  Map<String, dynamic>? _selectedCall;

  void _showCallDetailsBottomSheet(Map<String, dynamic> call) {
    _selectedCall = call;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeCall = _selectedCall ?? call;
            final String summary = activeCall['summary'] ?? "No summary generated for this interaction.";
            final List<dynamic> transcript = activeCall['transcript'] ?? [];
            final int currentRating = activeCall['rating'] ?? 0;
            final String duration = activeCall['duration'] ?? "0s";
            final String caller = activeCall['caller'] ?? "Unknown";

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.8,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(caller, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("AI Agent: ${activeCall['agent'] ?? 'N/A'}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Card
                          Card(
                            color: const Color(0xFFF8FAFC),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.summarize_outlined, color: Color(0xFF2563EB), size: 18),
                                      SizedBox(width: 8),
                                      Text('Call Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(summary, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Conversation bubbles
                          const Text('CONVERSATION TRANSCRIPT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 12),
                          if (transcript.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text('No transcript available for this call.', style: TextStyle(color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: transcript.length,
                              itemBuilder: (context, tIdx) {
                                final msg = transcript[tIdx];
                                final String speaker = msg['speaker'] ?? 'customer';
                                final String message = msg['message'] ?? '';
                                final String time = msg['timestamp'] ?? '';
                                final bool isCustomer = speaker == 'customer';

                                return Align(
                                  alignment: isCustomer ? Alignment.centerLeft : Alignment.centerRight,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isCustomer ? const Color(0xFFF1F5F9) : const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(12),
                                        topRight: const Radius.circular(12),
                                        bottomLeft: isCustomer ? Radius.zero : const Radius.circular(12),
                                        bottomRight: isCustomer ? const Radius.circular(12) : Radius.zero,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isCustomer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isCustomer ? "Customer • $time" : "AI Agent • $time",
                                          style: TextStyle(
                                            fontSize: 9, 
                                            fontWeight: FontWeight.bold, 
                                            color: isCustomer ? const Color(0xFF64748B) : const Color(0xFF93C5FD),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          message,
                                          style: TextStyle(
                                            fontSize: 13, 
                                            color: isCustomer ? const Color(0xFF1E293B) : Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Rate interaction
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RATE INTERACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (starIdx) {
                              final starNum = starIdx + 1;
                              final isLit = starNum <= currentRating;
                              return GestureDetector(
                                onTap: () => _rateCall(activeCall['_id'], starNum, setModalState),
                                child: Icon(
                                  isLit ? Icons.star : Icons.star_border,
                                  color: isLit ? Colors.amber : const Color(0xFFCBD5E1),
                                  size: 28,
                                ),
                              );
                            }),
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('CALL DURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(duration, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final filteredCalls = _calls.where((call) {
      if (_selectedSentiment.isNotEmpty && call['sentiment'] != _selectedSentiment) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Call History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: const AppNavigationDrawer(currentRoute: '/calls'),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Sentiment Filter Chips
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Color(0xFF64748B), size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("All", ""),
                            const SizedBox(width: 8),
                            _buildFilterChip("Positive", "positive"),
                            const SizedBox(width: 8),
                            _buildFilterChip("Neutral", "neutral"),
                            const SizedBox(width: 8),
                            _buildFilterChip("Negative", "negative"),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),

              // Calls List
              Expanded(
                child: filteredCalls.isEmpty
                  ? const Center(child: Text("No calls found matching filters."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCalls.length,
                      itemBuilder: (context, index) {
                        final call = filteredCalls[index];
                        final String caller = call['caller'] ?? "Unknown";
                        final String agent = call['agent'] ?? "N/A";
                        final String duration = call['duration'] ?? "0s";
                        final String sentiment = call['sentiment'] ?? "neutral";

                        IconData sentimentIcon = Icons.sentiment_neutral;
                        Color sentimentColor = Colors.grey;
                        if (sentiment == "positive") {
                          sentimentIcon = Icons.sentiment_satisfied_alt;
                          sentimentColor = Colors.green;
                        } else if (sentiment == "negative") {
                          sentimentIcon = Icons.sentiment_very_dissatisfied;
                          sentimentColor = Colors.red;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () => _showCallDetailsBottomSheet(call),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                              child: const Icon(Icons.phone_callback, color: Color(0xFF2563EB), size: 20),
                            ),
                            title: Text(caller, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Agent: $agent • $duration", style: const TextStyle(fontSize: 12)),
                            trailing: Icon(sentimentIcon, color: sentimentColor),
                          ),
                        );
                      },
                    ),
              )
            ],
          ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedSentiment == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSentiment = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
