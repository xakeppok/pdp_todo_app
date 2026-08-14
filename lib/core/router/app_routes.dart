abstract final class AppRoutes {
  static const root = '/';
  static const todos = '/todos';
  static const messages = '/messages';
  static const nativeMap = '/native-map';

  static const createRelative = 'create';
  static const idRelative = ':id';
  static const editRelative = 'edit';

  static const create = '$todos/$createRelative';

  static String details(String id) => '$todos/$id';

  static String edit(String id) => '$todos/$id/$editRelative';
}
