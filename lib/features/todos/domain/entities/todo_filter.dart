enum TodoFilter {
  all('All'),
  active('Active'),
  completed('Completed'),
  overdue('Overdue');

  const TodoFilter(this.label);

  final String label;
}
