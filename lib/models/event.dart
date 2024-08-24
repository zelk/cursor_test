import 'person.dart';

class Event {
  final DateTime? start;
  final DateTime? end;
  final String title;
  final String description;
  final Person person;
  final bool hasTime;

  Event({
    this.start,
    this.end,
    required this.title,
    required this.description,
    required this.person,
    required this.hasTime,
  });
}
