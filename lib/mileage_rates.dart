class MileageRate {
  final DateTime startDate;
  final DateTime endDate;
  final double rate;

  MileageRate({
    required this.startDate,
    required this.endDate,
    required this.rate,
  });
}

List<MileageRate> mileageRates = [
  MileageRate(
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 12, 31),
    rate: 0.67,
  ),
  MileageRate(
    startDate: DateTime(2025, 1, 1),
    endDate: DateTime(2025, 12, 31),
    rate: 0.70,
  ),
  MileageRate(
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 31),
    rate: 0.73,
  ),
];
