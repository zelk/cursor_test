import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'event_edit_dialog.dart';
import 'package:flutter/services.dart';
import 'models/event.dart';
import 'models/person.dart';

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

  void _updateEvent(
      Event oldEvent, Event? newEvent, int focusedDay, int focusedPersonIndex) {
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
        // Resort events and update _focusedEventIndex
        _resortEventsAndUpdateFocus(focusedDay, focusedPersonIndex);
      }
    });
  }

  void _resortEventsAndUpdateFocus(int focusedDay, int focusedPersonIndex) {
    final cellEvents = _getEventsForCurrentCell(focusedDay, focusedPersonIndex);
    cellEvents.sort((a, b) {
      if (a.hasTime && b.hasTime) {
        return a.start!.compareTo(b.start!);
      } else if (a.hasTime) {
        return -1;
      } else if (b.hasTime) {
        return 1;
      } else {
        return 0;
      }
    });

    // Note: We can't update _focusedEventIndex here as it's in CalendarView
    // You might want to consider moving this logic to CalendarView
  }

  List<Event> _getEventsForCurrentCell(int focusedDay, int focusedPersonIndex) {
    final now = DateTime.now();
    final person = people[focusedPersonIndex];

    return events
        .where((event) =>
            event.person.name == person.name &&
            event.start != null &&
            event.start!.day == focusedDay &&
            event.start!.month == now.month &&
            event.start!.year == now.year)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _regenerateEvents,
            child: Tooltip(
              message: 'Randomize',
              child: Container(
                color: Colors.transparent,
                child: const Icon(Icons.refresh),
              ),
            ),
          ),
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

class CalendarView extends StatefulWidget {
  final List<Event> events;
  final List<Person> people;
  final Function(Event oldEvent, Event? newEvent, int focusedDay,
      int focusedPersonIndex) onUpdateEvent;

  const CalendarView({
    super.key,
    required this.events,
    required this.people,
    required this.onUpdateEvent,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  int _focusedDay = DateTime.now().day;
  int _focusedPersonIndex = 0;
  bool _isEventKeyboardNavigation = false;
  int _focusedEventIndex = -1;
  Event? _focusedEvent;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            final cellEvents = _getEventsForCell(
                _focusedDay, widget.people[_focusedPersonIndex]);
            if (cellEvents.isEmpty) {
              return KeyEventResult.skipRemainingHandlers;
            }
            if (_isEventKeyboardNavigation) {
              _openEditDialogForFocusedEvent();
            } else {
              _toggleKeyboardNavigationMode();
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape &&
              _isEventKeyboardNavigation) {
            _exitEventKeyboardNavigation();
            return KeyEventResult.handled;
          } else if (_isEventKeyboardNavigation) {
            return _handleEventKeyboardNavigation(event);
          } else {
            return _handleCellKeyboardNavigation(event);
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
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
                  for (var person in widget.people)
                    _buildHeaderCell(person.name),
                ],
              ),
            ],
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Table(
                border: TableBorder.all(),
                children: [
                  for (var day = 1; day <= daysInMonth; day++)
                    TableRow(
                      children: [
                        _buildDateCell(
                            firstDayOfMonth.add(Duration(days: day - 1))),
                        for (var personIndex = 0;
                            personIndex < widget.people.length;
                            personIndex++)
                          _buildPersonCell(now, day, widget.people[personIndex],
                              personIndex),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  KeyEventResult _handleEventKeyboardNavigation(RawKeyEvent event) {
    if (!_isEventKeyboardNavigation) return KeyEventResult.ignored;

    final cellEvents =
        _getEventsForCell(_focusedDay, widget.people[_focusedPersonIndex]);
    if (cellEvents.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_focusedEventIndex > 0) {
        setState(() {
          _focusedEventIndex--;
          _focusedEvent = cellEvents[_focusedEventIndex];
        });
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_focusedEventIndex < cellEvents.length - 1) {
        setState(() {
          _focusedEventIndex++;
          _focusedEvent = cellEvents[_focusedEventIndex];
        });
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      _openEditDialogForFocusedEvent();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openEditDialogForFocusedEvent() {
    final cellEvents =
        _getEventsForCell(_focusedDay, widget.people[_focusedPersonIndex]);
    if (_focusedEventIndex >= 0 && _focusedEventIndex < cellEvents.length) {
      final focusedEvent = cellEvents[_focusedEventIndex];
      _showEventEditDialog(context, focusedEvent);
    }
  }

  KeyEventResult _handleCellKeyboardNavigation(RawKeyEvent event) {
    final daysInMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_focusedDay > 1) {
        _moveCellFocus(Direction.up);
        _scrollToFocusedCell();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_focusedDay < daysInMonth) {
        _moveCellFocus(Direction.down);
        _scrollToFocusedCell();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_focusedPersonIndex > 0) {
        _moveCellFocus(Direction.left);
        _scrollToFocusedCell();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_focusedPersonIndex < widget.people.length - 1) {
        _moveCellFocus(Direction.right);
        _scrollToFocusedCell();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.skipRemainingHandlers;
  }

  void _scrollToFocusedCell() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? tableBox = context.findRenderObject() as RenderBox?;
      if (tableBox == null) return;

      const cellHeight = 100.0; // Assuming each cell is 100 pixels high
      final scrollOffset = (_focusedDay - 1) * cellHeight;
      final viewportHeight = _scrollController.position.viewportDimension;
      final currentScrollOffset = _scrollController.offset;

      if (scrollOffset < currentScrollOffset) {
        // Scroll up if the focused cell is above the viewport
        _scrollController.animateTo(
          scrollOffset,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
        );
      } else if (scrollOffset + cellHeight >
          currentScrollOffset + viewportHeight) {
        // Scroll down if the focused cell is below the viewport
        _scrollController.animateTo(
          scrollOffset + cellHeight - viewportHeight,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _toggleKeyboardNavigationMode() {
    final cellEvents =
        _getEventsForCell(_focusedDay, widget.people[_focusedPersonIndex]);
    setState(() {
      _isEventKeyboardNavigation = !_isEventKeyboardNavigation;
      if (_isEventKeyboardNavigation && cellEvents.isNotEmpty) {
        _focusedEventIndex = 0;
        _focusedEvent = cellEvents[_focusedEventIndex];
      } else {
        _focusedEventIndex = -1;
        _focusedEvent = null;
      }
    });
  }

  void _exitEventKeyboardNavigation() {
    setState(() {
      _isEventKeyboardNavigation = false;
      _focusedEventIndex = -1;
      _focusedEvent = null;
    });
  }

  void _moveCellFocus(Direction direction) {
    setState(() {
      switch (direction) {
        case Direction.up:
          _focusedDay = (_focusedDay - 1).clamp(1,
              DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day);
          break;
        case Direction.down:
          _focusedDay = (_focusedDay + 1).clamp(1,
              DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day);
          break;
        case Direction.left:
          _focusedPersonIndex =
              (_focusedPersonIndex - 1).clamp(0, widget.people.length - 1);
          break;
        case Direction.right:
          _focusedPersonIndex =
              (_focusedPersonIndex + 1).clamp(0, widget.people.length - 1);
          break;
      }
    });
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
      height: 100, // Match the height of person cells
      decoration: BoxDecoration(
        color: _getCellBackgroundColor(date, isToday, isPast, true),
        border: _focusedDay == date.day
            ? Border.all(
                color: _isEventKeyboardNavigation
                    ? Colors.orange.withOpacity(0.5)
                    : Colors.orange,
                width: _isEventKeyboardNavigation ? 1 : 2,
              )
            : null,
      ),
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
      DateTime now, int day, Person person, int personIndex) {
    final cellEvents = _getEventsForCell(day, person);
    final isCellFocused =
        _focusedDay == day && _focusedPersonIndex == personIndex;

    if (isCellFocused && _isEventKeyboardNavigation) {
      if (_focusedEventIndex == -1 || _focusedEvent == null) {
        _focusedEventIndex = cellEvents.isEmpty ? -1 : 0;
        _focusedEvent =
            _focusedEventIndex >= 0 ? cellEvents[_focusedEventIndex] : null;
      } else {
        // Ensure the focused event is still in the cell
        final eventIndex = cellEvents.indexWhere((e) => e == _focusedEvent);
        if (eventIndex == -1) {
          _focusedEventIndex = 0;
          _focusedEvent = cellEvents.isNotEmpty ? cellEvents[0] : null;
        } else {
          _focusedEventIndex = eventIndex;
        }
      }
    }

    return TableCell(
      child: DragTarget<Event>(
        onAccept: (event) {
          setState(() {
            final oldEvent = event;
            final newEvent = Event(
              start: DateTime(now.year, now.month, day, event.start!.hour,
                  event.start!.minute),
              end: event.end != null
                  ? DateTime(now.year, now.month, day, event.end!.hour,
                      event.end!.minute)
                  : null,
              title: event.title,
              description: event.description,
              person: person,
              hasTime: event.hasTime,
            );
            widget.onUpdateEvent(oldEvent, newEvent, day, personIndex);
          });
        },
        builder: (context, candidateData, rejectedData) {
          return GestureDetector(
            onTap: () => _handleCellTap(day, personIndex),
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration: BoxDecoration(
                color: _getCellBackgroundColor(
                    DateTime(now.year, now.month, day), false, false, false),
                border: Border.all(
                  color: isCellFocused
                      ? (_isEventKeyboardNavigation
                          ? Colors.orange // Regular orange for event navigation
                          : Colors.orange
                              .shade700) // Darker orange for regular focus
                      : Colors.grey[300]!,
                  width:
                      isCellFocused ? (_isEventKeyboardNavigation ? 2 : 3) : 1,
                ),
                boxShadow: isCellFocused && !_isEventKeyboardNavigation
                    ? [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              height: 100,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: cellEvents.asMap().entries.map((entry) {
                      int index = entry.key;
                      Event event = entry.value;
                      return _buildEventWidget(
                        event,
                        now,
                        context,
                        isFocused: isCellFocused &&
                            _isEventKeyboardNavigation &&
                            index == _focusedEventIndex,
                      );
                    }).toList(),
                  ),
                  if (isCellFocused && !_isEventKeyboardNavigation)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Implement add event functionality
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventWidget(Event event, DateTime now, BuildContext context,
      {bool isFocused = false}) {
    String eventText = _formatEventText(event);
    return _HoverableEventWidget(
      event: event,
      now: now,
      onTap: () => _showEventEditDialog(context, event),
      eventText: eventText,
      isFocused: isFocused,
    );
  }

  String _formatEventText(Event event) {
    if (event.hasTime && event.start != null) {
      if (event.end != null) {
        return '${_formatTime(event.start!)} - ${_formatTime(event.end!)} ${event.title}';
      } else {
        return '${_formatTime(event.start!)} ${event.title}';
      }
    } else {
      return event.title;
    }
  }

  void _showEventEditDialog(BuildContext context, Event event) {
    _focusedEvent = event; // Store the currently focused event
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EventEditDialog(
          event: event,
          onUpdateEvent: (Event oldEvent, Event? newEvent) {
            widget.onUpdateEvent(
                oldEvent, newEvent, _focusedDay, _focusedPersonIndex);
            _updateFocusedEventIndex(oldEvent, newEvent);
          },
        );
      },
    );
  }

  void _updateFocusedEventIndex(Event oldEvent, Event? newEvent) {
    setState(() {
      final cellEvents =
          _getEventsForCell(_focusedDay, widget.people[_focusedPersonIndex]);
      cellEvents.sort((a, b) {
        if (a.hasTime && b.hasTime) {
          return a.start!.compareTo(b.start!);
        } else if (a.hasTime) {
          return -1;
        } else if (b.hasTime) {
          return 1;
        } else {
          return 0;
        }
      });

      if (_isEventKeyboardNavigation) {
        if (newEvent != null) {
          // Find the index of the updated event
          _focusedEventIndex = cellEvents.indexWhere((e) => e == newEvent);
        } else {
          // If the event was deleted, focus on the next event or the last one if it was the last event
          _focusedEventIndex =
              _focusedEventIndex.clamp(0, cellEvents.length - 1);
        }

        if (_focusedEventIndex == -1) {
          // If the event is no longer in the cell, reset focus
          _focusedEventIndex = cellEvents.isEmpty ? -1 : 0;
        }

        _focusedEvent =
            _focusedEventIndex >= 0 ? cellEvents[_focusedEventIndex] : null;
      }
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getCellBackgroundColor(
      DateTime date, bool isToday, bool isPast, bool isDateColumn) {
    Color baseColor;
    if (isToday) {
      baseColor = Colors.yellow[100] ?? Colors.yellow;
    } else if (_isWeekend(date)) {
      baseColor = isPast ? Colors.grey[300]! : Colors.pink[50] ?? Colors.pink;
    } else if (isPast) {
      baseColor = Colors.grey[100] ?? Colors.grey;
    } else {
      baseColor = Colors.white; // Changed from transparent to white
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

  List<Event> _getEventsForCell(int day, Person person) {
    final now = DateTime.now();

    final cellEvents = widget.events
        .where((event) =>
            event.person.name == person.name &&
            event.start != null &&
            event.start!.day == day &&
            event.start!.month == now.month &&
            event.start!.year == now.year)
        .toList();

    cellEvents.sort((a, b) {
      if (a.hasTime && b.hasTime) {
        return a.start!.compareTo(b.start!);
      } else if (a.hasTime) {
        return -1;
      } else if (b.hasTime) {
        return 1;
      } else {
        return 0;
      }
    });

    return cellEvents;
  }

  void _handleCellTap(int day, int personIndex) {
    setState(() {
      _focusedDay = day;
      _focusedPersonIndex = personIndex;
      _isEventKeyboardNavigation = false;
      _focusedEventIndex = -1;
      _focusedEvent = null;
    });
    _focusNode.requestFocus();
    _scrollToFocusedCell(); // Add this line to trigger auto-scrolling
  }
}

class _HoverableEventWidget extends StatefulWidget {
  final Event event;
  final DateTime now;
  final VoidCallback onTap;
  final String eventText;
  final bool isFocused;

  const _HoverableEventWidget({
    required this.event,
    required this.now,
    required this.onTap,
    required this.eventText,
    required this.isFocused,
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
      child: Draggable<Event>(
        data: widget.event,
        feedback: Material(
          child: Container(
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
            ),
            child: Text(
              widget.eventText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        childWhenDragging: Container(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: widget.isFocused
                  ? Colors.blue.withOpacity(0.3)
                  : (isHovered
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.isFocused
                    ? Colors.blue
                    : (isHovered
                        ? Colors.blue.withOpacity(0.5)
                        : Colors.blue.withOpacity(0.3)),
                width: widget.isFocused ? 2 : 1,
              ),
              boxShadow: [
                if (isHovered || widget.isFocused)
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
      return eventDate != null &&
          eventDate.isBefore(today) &&
          eventDate != today;
    }
  }
}

enum Direction { up, down, left, right }
