// File: lib/features/advisor/advisor_logic.dart

class StorageAdvice {
  final String item;
  final int days;
  final String tip;

  StorageAdvice({required this.item, required this.days, required this.tip});
}

class AdvisorEngine {
  // Offline rule-based engine (Zero-network fallback)
  static final Map<String, dynamic> _rules = {
    'rice': {'days': 365, 'tip': 'Store in airtight container, keep dry.'},
    'bread': {'days': 3, 'tip': 'Eat first. Toast if stale to extend life.'},
    'onion': {'days': 30, 'tip': 'Store in a net bag in a dark, cool place.'},
    'potato': {'days': 21, 'tip': 'Keep away from sunlight. Do not refrigerate.'},
    'flour': {'days': 180, 'tip': 'Keep in a sealed container to avoid pests.'},
    'lentils': {'days': 365, 'tip': 'Very stable. Keep dry and cool.'},
    'canned': {'days': 730, 'tip': 'Check for dents/rust. Use within 2 days of opening.'},
  };

  static List<StorageAdvice> getAdvice(List<String> items) {
    List<StorageAdvice> results = [];
    for (var item in items) {
      final key = item.toLowerCase().trim();
      final match = _rules.entries.firstWhere(
            (e) => key.contains(e.key),
        orElse: () => MapEntry(item, {'days': 7, 'tip': 'No specific data. Consume soon.'}),
      );

      results.add(StorageAdvice(
        item: item,
        days: match.value['days'],
        tip: match.value['tip'],
      ));
    }
    // Sort by shortest shelf life
    results.sort((a, b) => a.days.compareTo(b.days));
    return results;
  }
}