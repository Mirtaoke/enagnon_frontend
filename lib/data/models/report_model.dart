class Report {
  final int id;
  final int shopId;
  final String date;
  final double totalIn;
  final double totalOut;
  final double cashBalance;
  final String note;
  final List<int> reportIds;

  Report({
    required this.id,
    required this.shopId,
    required this.date,
    required this.totalIn,
    required this.totalOut,
    required this.cashBalance,
    required this.note,
    this.reportIds = const [],
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? 0,
      shopId: json['shop_id'] ?? 0,
      date: json['date'] ?? '',
      totalIn: double.tryParse('${json['total_in']}') ?? 0,
      totalOut: double.tryParse('${json['total_out']}') ?? 0,
      cashBalance: double.tryParse('${json['cash_balance']}') ?? 0,
      note: json['note'] ?? '',
      reportIds: (json['report_ids'] as List? ?? const [])
          .map((id) => int.tryParse('$id') ?? 0)
          .where((id) => id > 0)
          .toList(),
    );
  }
}
