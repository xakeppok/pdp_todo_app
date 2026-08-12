enum TodoPriority {
  low(1, 'Low'),
  medium(2, 'Medium'),
  high(3, 'High');

  const TodoPriority(this.rank, this.label);

  final int rank;
  final String label;
}
