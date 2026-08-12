enum TodoSort {
  priority('Priority'),
  dueDate('Due date');

  const TodoSort(this.label);

  final String label;
}
