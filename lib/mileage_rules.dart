class MileageRules {
  static const tooFarFuture = 'Date cannot be more than 1 day in the future.';
  static const negative = 'Mileage cannot be negative.';
  static const tooHigh = 'Mileage values are unreasonably high.';
  static const endNotGreater =
      'End mileage must be greater than start mileage.';
  static const dailyCap =
      'Daily distance over 1000 seems unreasonable. Please verify.';

  static String? validate({
    required int startMileage,
    required int endMileage,
    required DateTime date,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    if (date.isAfter(clock.add(const Duration(days: 1)))) return tooFarFuture;
    if (startMileage < 0 || endMileage < 0) return negative;
    if (startMileage > 999999 || endMileage > 999999) return tooHigh;
    if (endMileage <= startMileage) return endNotGreater;
    if (endMileage - startMileage > 1000) return dailyCap;
    return null;
  }
}
