import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Add this import for Random
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: DateFormat('MMMM yyyy').format(DateTime.now())),
    );
  }
}

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

class Person {
  final String name;

  Person({required this.name});
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Person> people = [
    Person(name: 'Caroline'),
    Person(name: 'Ricky'),
    Person(name: 'Valdemar'),
    Person(name: 'Emmy-Lo'),
  ];

  List<Event> events = [];

  final List<String> eventTitles = [
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

  @override
  void initState() {
    super.initState();
    _generateDummyEvents();
  }

  void _generateDummyEvents() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    print("Generating dummy events...");

    const totalEvents = 100;
    final allDayEventsCount =
        (totalEvents * 0.2).round(); // 20% of total events
    final timedEventsCount = totalEvents - allDayEventsCount;

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

    print("Total events generated: ${events.length}");
    print("All-day events: $allDayEventsCount");
    print("Timed events: $timedEventsCount");
  }

  void _regenerateEvents() {
    setState(() {
      events.clear();
      _generateDummyEvents();
    });
  }

  void _updateEvent(Event oldEvent, Event? newEvent) {
    setState(() {
      final index = events.indexOf(oldEvent);
      if (index != -1) {
        if (newEvent == null) {
          // Delete the event
          events.removeAt(index);
        } else {
          // Update the event
          events[index] = newEvent;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _regenerateEvents,
          tooltip: 'Randomize',
        ),
        title: Row(
          children: [
            Text(widget.title),
            const SizedBox(width: 10),
            Text('(${events.length} events)',
                style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
      body: CalendarView(
        events: events,
        people: people,
        onUpdateEvent: _updateEvent,
      ),
    );
  }
}

class CalendarView extends StatelessWidget {
  final List<Event> events;
  final List<Person> people;
  final Function(Event oldEvent, Event? newEvent) onUpdateEvent;

  const CalendarView({
    super.key,
    required this.events,
    required this.people,
    required this.onUpdateEvent,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Column(
      children: [
        // Sticky header
        Table(
          border: TableBorder.all(),
          children: [
            TableRow(
              decoration: const BoxDecoration(
                color: Colors.grey, // Dark grey background
              ),
              children: [
                _buildHeaderCell('Date'),
                for (var person in people) _buildHeaderCell(person.name),
              ],
            ),
          ],
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Table(
              border: TableBorder.all(),
              children: [
                for (var day = 1; day <= daysInMonth; day++)
                  TableRow(
                    children: [
                      TableCell(
                          child: _buildDateCell(
                              firstDayOfMonth.add(Duration(days: day - 1)))),
                      for (var person in people)
                        _buildPersonCell(now, day, person, context),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return TableCell(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        color: Colors.grey[800], // Dark grey background
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text for contrast
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateCell(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: _getCellBackgroundColor(date, isToday, isPast, true),
      height: 100, // Match the height of person cells
      child: Stack(
        children: [
          if (isToday)
            const Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.arrow_right,
                  color: Colors.orange,
                  size: 36,
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${DateFormat('E').format(date)} ${date.day}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isToday)
                  Text(
                    DateFormat('HH:mm').format(now),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCell(
      DateTime now, int day, Person person, BuildContext context) {
    final date = DateTime(now.year, now.month, day);
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isPast = date.isBefore(DateTime(now.year, now.month, now.day));

    // Filter events for this day and person
    final cellEvents = events
        .where((event) =>
            event.person.name == person.name &&
            event.start != null &&
            event.start!.day == day &&
            event.start!.month == now.month &&
            event.start!.year == now.year)
        .toList();

    // Sort the events based on time
    cellEvents.sort((a, b) {
      if (a.hasTime && b.hasTime) {
        return a.start!.compareTo(b.start!);
      } else if (a.hasTime) {
        return -1; // a comes first
      } else if (b.hasTime) {
        return 1; // b comes first
      } else {
        return 0; // both are all-day events, keep original order
      }
    });

    return TableCell(
      child: Container(
        color: _getCellBackgroundColor(date, isToday, isPast, false),
        height: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cellEvents
              .map((event) => _buildEventWidget(event, now, context))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildEventWidget(Event event, DateTime now, BuildContext context) {
    String eventText;
    if (event.hasTime && event.start != null) {
      if (event.end != null) {
        eventText =
            '${_formatTime(event.start!)} - ${_formatTime(event.end!)} ${event.title}';
      } else {
        eventText = '${_formatTime(event.start!)} ${event.title}';
      }
    } else {
      eventText = event.title;
    }

    return _HoverableEventWidget(
      event: event,
      now: now,
      onTap: () => _showEventEditDialog(context, event),
      eventText: eventText,
    );
  }

  void _showEventEditDialog(BuildContext context, Event event) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: event.title);
    String description = event.description;
    DateTime? start = event.start;
    DateTime? end = event.end;
    bool hasTime = event.hasTime;

    // Set the cursor position at the end of the title text
    titleController.selection = TextSelection.fromPosition(
      TextPosition(offset: titleController.text.length),
    );

    void submitForm() {
      if (formKey.currentState!.validate()) {
        final updatedEvent = Event(
          start: start,
          end: end,
          title: titleController.text,
          description: description,
          person: event.person,
          hasTime: hasTime,
        );
        onUpdateEvent(event, updatedEvent);
        Navigator.of(context).pop();
      }
    }

    void deleteEvent() {
      onUpdateEvent(event, null); // Pass null to indicate deletion
      Navigator.of(context).pop();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RawKeyboardListener(
          focusNode: FocusNode(),
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              print("ESC key pressed"); // Debug print
              Navigator.of(context).pop();
            }
          },
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Edit Event'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Title'),
                          controller: titleController,
                          autofocus: true,
                          onFieldSubmitted: (_) => submitForm(),
                        ),
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          initialValue: description,
                          onChanged: (value) => description = value,
                          maxLines: 5, // Set to multiple lines
                          minLines: 3, // Minimum number of lines to show
                          textInputAction:
                              TextInputAction.newline, // Allow new lines
                        ),
                        CheckboxListTile(
                          title: const Text('Has Time'),
                          value: hasTime,
                          onChanged: (value) {
                            setState(() {
                              hasTime = value ?? false;
                            });
                          },
                        ),
                        if (hasTime) ...[
                          ListTile(
                            title: const Text('Start Time'),
                            subtitle: Text(start?.toString() ?? 'Not set'),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: start ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  start = picked;
                                });
                              }
                            },
                          ),
                          ListTile(
                            title: const Text('End Time'),
                            subtitle: Text(end?.toString() ?? 'Not set'),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: end ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  end = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: deleteEvent,
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                      Row(
                        children: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            onPressed: submitForm,
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getCellBackgroundColor(
      DateTime date, bool isToday, bool isPast, bool isDateColumn) {
    Color baseColor;
    if (isToday) {
      baseColor = Colors.yellow[100]!;
    } else if (_isWeekend(date)) {
      baseColor = isPast ? Colors.grey[300]! : Colors.pink[50]!;
    } else if (isPast) {
      baseColor = Colors.grey[100]!;
    } else {
      baseColor = Colors.transparent;
    }

    // Make the color darker for the date column
    if (isDateColumn) {
      return _darkenColor(baseColor);
    }

    return baseColor;
  }

  Color _darkenColor(Color color) {
    const amount = 0.1;
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}

class _HoverableEventWidget extends StatefulWidget {
  final Event event;
  final DateTime now;
  final VoidCallback onTap;
  final String eventText;

  const _HoverableEventWidget({
    required this.event,
    required this.now,
    required this.onTap,
    required this.eventText,
  });

  @override
  _HoverableEventWidgetState createState() => _HoverableEventWidgetState();
}

class _HoverableEventWidgetState extends State<_HoverableEventWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isPast = _isEventPast(widget.event, widget.now);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.blue.withOpacity(0.2)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
                color: isHovered
                    ? Colors.blue.withOpacity(0.5)
                    : Colors.blue.withOpacity(0.3)),
            boxShadow: [
              if (isHovered)
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Text(
            widget.eventText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
              decoration: isPast ? TextDecoration.lineThrough : null,
              color: isPast ? Colors.grey : Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  bool _isEventPast(Event event, DateTime now) {
    if (event.hasTime) {
      return event.end != null
          ? event.end!.isBefore(now)
          : (event.start != null ? event.start!.isBefore(now) : false);
    } else {
      // For events without time, compare only the date
      final eventDate = event.start != null
          ? DateTime(event.start!.year, event.start!.month, event.start!.day)
          : null;
      final today = DateTime(now.year, now.month, now.day);
      return eventDate != null && eventDate.isBefore(today);
    }
  }
}
