// ignore: one_member_abstracts -- injectable time port for deterministic tests
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  // ignore: use_setters_to_change_properties -- explicit test API, not a field mirror
  void setNow(DateTime value) => _now = value;
}
