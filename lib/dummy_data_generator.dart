import 'dart:math';
import 'models/event.dart';
import 'models/person.dart';

class DummyDataGenerator {
  static final List<String> eventTitles = [
    'Tennis practice',
    'Homework time',
    'Laundry day',
    'Lunch with grandma',
    'Soccer game',
    'Piano lesson',
    'Dentist appointment',
    'Family movie night',
    'Grocery shopping',
    'Swimming class',
    'Parent-teacher conference',
    'Cooking dinner',
    'Yoga session',
    'Book club meeting',
    'Haircut',
    'Volunteer at food bank',
    'Art class',
    'Family game night',
    'Doctor\'s checkup',
    'Birthday party',
    'Gardening',
    'Car maintenance',
    'Dance recital',
    'Bake cookies',
    'Bike ride',
    'Karate lesson',
    'Science fair prep',
    'Playdate with friends',
    'Camping trip',
    'Visit to museum',
    'Guitar lesson',
    'Tutoring session',
    'Gym workout',
    'Family picnic',
    'Painting the house',
    'Charity run',
    'Pottery class',
    'Fishing trip',
    'Coding workshop',
    'Vet appointment for pet',
    'School play rehearsal',
    'Recycling day',
    'Photography class',
    'Farmers market visit',
    'Basketball practice',
    'Meditation session',
    'Library visit',
    'Craft project',
    'Hiking adventure',
    'Language class'
  ];

  static List<Event> generateDummyEvents(List<Person> people) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    const totalEvents = 100;
    final allDayEventsCount =
        (totalEvents * 0.2).round(); // 20% of total events
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
        description: 'Description for ${person.name}\'s event',
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
        description: 'All-day event for ${person.name}',
        person: person,
        hasTime: false,
      );
      events.add(allDayEvent);
    }

    return events;
  }
}
