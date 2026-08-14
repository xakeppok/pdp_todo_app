enum TodoPriority {
  low(1, 'Low'),
  medium(2, 'Medium'),
  high(3, 'High');

  const TodoPriority(this.rank, this.label);

  final int rank;
  final String label;

  static TodoPriority? tryParse(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'low' => TodoPriority.low,
      'medium' => TodoPriority.medium,
      'high' => TodoPriority.high,
      _ => null,
    };
  }

  static TodoPriority fromName(String raw) =>
      tryParse(raw) ?? TodoPriority.medium;
}
