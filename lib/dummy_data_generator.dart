import 'dart:math';
import 'models/event.dart';
import 'models/person.dart';

class DummyDataGenerator {
  static final List<String> eventTitles = [
    'Tennisträning',
    'Läxläsning',
    'Tvättdag',
    'Lunch med mormor',
    'Fotbollsmatch',
    'Pianolektion',
    'Tandläkarbesök',
    'Familjefilmkväll',
    'Handla mat',
    'Simlektion',
    'Utvecklingssamtal',
    'Laga middag',
    'Yogapass',
    'Bokklubbsmöte',
    'Klippning',
    'Volontärarbete på matbank',
    'Konstklass',
    'Familjespelkväll',
    'Läkarbesök',
    'Födelsedagsfest',
    'Trädgårdsarbete',
    'Bilunderhåll',
    'Dansuppvisning',
    'Baka kakor',
    'Cykeltur',
    'Karatelektions',
    'Förberedelse för vetenskapsmässa',
    'Lekträff med vänner',
    'Campingresa',
    'Besök på museum',
    'Gitarrlektion',
    'Handledningssession',
    'Gymträning',
    'Familjepicknick',
    'Måla huset',
    'Välgörenhetslopp',
    'Keramikkurs',
    'Fisketur',
    'Kodningsverkstad',
    'Veterinärbesök för husdjur',
    'Skolpjäsrepetition',
    'Återvinningsdag',
    'Fotokurs',
    'Besök på bondemarknad',
    'Basketträning',
    'Meditationssession',
    'Biblioteksbesök',
    'Hantverksprojekt',
    'Vandring',
    'Språkkurs'
  ];

  static List<Event> generateDummyEvents(List<Person> people) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    const totalEvents = 100;
    final allDayEventsCount =
        (totalEvents * 0.4).round(); // 40% of total events
    final timedEventsCount = totalEvents - allDayEventsCount;

    List<Event> events = [];

    // Generate timed events
    for (var i = 0; i < timedEventsCount; i++) {
      final day = Random().nextInt(daysInMonth) + 1;
      final person = people[Random().nextInt(people.length)];
      final startHour =
          8 + Random().nextInt(10); // Events between 8 AM and 5 PM
      final startMinute = Random().nextInt(4) * 15; // 0, 15, 30, or 45 minutes
      final durationHours = Random().nextInt(4); // 0 to 3 hours long

      final start = DateTime(now.year, now.month, day, startHour, startMinute);
      final end =
          durationHours > 0 ? start.add(Duration(hours: durationHours)) : null;

      final event = Event(
        start: start,
        end: end,
        title: eventTitles[Random().nextInt(eventTitles.length)],
        description: '',
        person: person,
        hasTime: true,
      );
      events.add(event);
    }

    // Generate all-day events (events without time)
    for (var i = 0; i < allDayEventsCount; i++) {
      final day = Random().nextInt(daysInMonth) + 1;
      final person = people[Random().nextInt(people.length)];
      final allDayEvent = Event(
        start: DateTime(now.year, now.month, day),
        end: null,
        title: eventTitles[Random().nextInt(eventTitles.length)],
        description: '',
        person: person,
        hasTime: false,
      );
      events.add(allDayEvent);
    }

    return events;
  }
}
