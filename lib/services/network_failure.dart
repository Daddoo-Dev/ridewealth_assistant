bool isRetryableNetworkError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('failed host lookup') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection reset') ||
      text.contains('connection closed') ||
      text.contains('connection abort') ||
      text.contains('timeoutexception') ||
      text.contains('network error') ||
      text.contains('xmlhttprequest error') ||
      text.contains('failed to fetch') ||
      text.contains('software caused connection abort');
}
