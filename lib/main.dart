import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'event_edit_dialog.dart';
import 'package:flutter/services.dart';
import 'models/event.dart';
import 'models/person.dart';
import 'dummy_data_generator.dart';

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

  @override
  void initState() {
    super.initState();
    _generateDummyEvents();
  }

  void _generateDummyEvents() {
    events = DummyDataGenerator.generateDummyEvents(people);
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
      }
    });
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
  bool _isCellNavigation = false;
  int _focusedEventIndex = -1;
  Event? _focusedEvent;

  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentDay();
    });
  }

  void _scrollToCurrentDay() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    const cellHeight = 100.0; // Assuming each cell is 100 pixels high
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentDayOffset = (now.day - 1) * cellHeight;

    if (currentDayOffset + viewportHeight > daysInMonth * cellHeight) {
      // If the current day is close to the end of the month, scroll to the bottom
      _scrollController.jumpTo(daysInMonth * cellHeight - viewportHeight);
    } else {
      // Otherwise, scroll to the current day
      _scrollController.jumpTo(currentDayOffset);
    }
  }

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
            if (!_isCellNavigation) {
              _enterCellNavigationState();
              return KeyEventResult.handled;
            } else {
              _openEditDialogForFocusedEvent();
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.escape &&
              _isCellNavigation) {
            _exitEventKeyboardNavigation();
            return KeyEventResult.handled;
          } else if (_isCellNavigation) {
            return _handleEventKeyboardNavigation(event);
          } else {
            return _handleCalendarNavigation(event);
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
    if (!_isCellNavigation) return KeyEventResult.ignored;

    final cellEvents =
        _getEventsForCell(_focusedDay, widget.people[_focusedPersonIndex]);
    final displayEvents = [
      Event(
        title: "Create Event...",
        person: widget.people[_focusedPersonIndex],
        start: DateTime(DateTime.now().year, DateTime.now().month, _focusedDay),
        hasTime: false,
      ),
      ...cellEvents,
    ];

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_focusedEventIndex > 0) {
        setState(() {
          _focusedEventIndex--;
          _focusedEvent = displayEvents[_focusedEventIndex];
        });
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_focusedEventIndex < displayEvents.length - 1) {
        setState(() {
          _focusedEventIndex++;
          _focusedEvent = displayEvents[_focusedEventIndex];
        });
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      _openEditDialogForFocusedEvent();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_focusedEvent != null) {
        widget.onUpdateEvent(
            _focusedEvent!, null, _focusedDay, _focusedPersonIndex);
        _updateFocusedEventIndex(_focusedEvent!, null);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _openEditDialogForFocusedEvent() {
    final cellEvents =
        _getEventsForCell(_focusedDay, widget.people[_focusedPersonIndex]);
    final displayEvents = [
      Event(
        title: "Create Event...",
        person: widget.people[_focusedPersonIndex],
        start: DateTime(DateTime.now().year, DateTime.now().month, _focusedDay),
        hasTime: false,
      ),
      ...cellEvents,
    ];

    if (_focusedEventIndex >= 0 && _focusedEventIndex < displayEvents.length) {
      final focusedEvent = displayEvents[_focusedEventIndex];
      if (_focusedEventIndex == 0 && _isCellNavigation) {
        // Create new event
        _showEventEditDialog(context, null,
            DateTime(DateTime.now().year, DateTime.now().month, _focusedDay));
      } else {
        _showEventEditDialog(context, focusedEvent, DateTime.now());
      }
    }
  }

  KeyEventResult _handleCalendarNavigation(RawKeyEvent event) {
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
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      _enterCellNavigationState();
      return KeyEventResult.handled;
    }
    return KeyEventResult.skipRemainingHandlers;
  }

  void _enterCellNavigationState() {
    setState(() {
      _isCellNavigation = true;
      _focusedEventIndex =
          0; // Always start at the first item (Create Event...)
      _focusedEvent = null;
    });
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

  void _exitEventKeyboardNavigation() {
    setState(() {
      _isCellNavigation = false;
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
        color: _getCellBackgroundColor(date, isToday, isPast, true, false),
        border: _focusedDay == date.day
            ? Border.all(
                color: _isCellNavigation
                    ? Colors.orange.withOpacity(0.5)
                    : Colors.orange,
                width: _isCellNavigation ? 1 : 2,
              )
            : null,
      ),
      child: Stack(
        children: [
          if (isToday)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
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

    final displayEvents = [
      if (isCellFocused && _isCellNavigation)
        Event(
          title: "Create Event...",
          person: person,
          start: DateTime(now.year, now.month, day),
          hasTime: false,
        ),
      ...cellEvents,
    ];

    if (isCellFocused && _isCellNavigation) {
      _focusedEventIndex =
          _focusedEventIndex.clamp(0, displayEvents.length - 1);
      _focusedEvent = displayEvents[_focusedEventIndex];
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
            onTap: () {
              _handleCellTap(day, personIndex);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration: BoxDecoration(
                color: _getCellBackgroundColor(
                    DateTime(now.year, now.month, day),
                    false,
                    false,
                    false,
                    isCellFocused && _isCellNavigation),
                border: Border.all(
                  color: isCellFocused
                      ? (_isCellNavigation
                          ? Colors.orange // Regular orange for event navigation
                          : Colors.orange
                              .shade700) // Darker orange for regular focus
                      : Colors.grey[300]!,
                  width: isCellFocused ? (_isCellNavigation ? 2 : 3) : 1,
                ),
                boxShadow: isCellFocused && !_isCellNavigation
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
                  // Add this Positioned.fill widget to handle taps on empty space
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        _handleCellTap(day, personIndex);
                        setState(() {
                          _isCellNavigation = true;
                        });
                      },
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: displayEvents.asMap().entries.map((entry) {
                      int index = entry.key;
                      Event event = entry.value;
                      return _buildEventWidget(
                        event,
                        now,
                        context,
                        isFocused: isCellFocused &&
                            _isCellNavigation &&
                            index == _focusedEventIndex,
                        isPseudoEvent:
                            isCellFocused && _isCellNavigation && index == 0,
                      );
                    }).toList(),
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
      {bool isFocused = false, bool isPseudoEvent = false}) {
    String eventText =
        isPseudoEvent ? "Create Event..." : _formatEventText(event);
    return _HoverableEventWidget(
      event: event,
      now: now,
      onTap: () {
        if (isPseudoEvent) {
          _showEventEditDialog(
              context, null, DateTime(now.year, now.month, _focusedDay));
        } else {
          _showEventEditDialog(context, event, DateTime.now());
        }
      },
      eventText: eventText,
      isFocused: isFocused,
      isPseudoEvent: isPseudoEvent,
    );
  }

  String _formatEventText(Event event) {
    String timeText = '';
    if (event.hasTime && event.start != null) {
      if (event.end != null) {
        timeText = '${_formatTime(event.start!)} - ${_formatTime(event.end!)} ';
      } else {
        timeText = '${_formatTime(event.start!)} ';
      }
    }
    return '$timeText${event.title}';
  }

  void _showEventEditDialog(BuildContext context, Event? event, DateTime date) {
    _focusedEvent = event; // Store the currently focused event
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EventEditDialog(
          event: event,
          person: widget.people[_focusedPersonIndex].name,
          date: date,
          onUpdateEvent: (Event oldEvent, Event? newEvent) {
            setState(() {
              if (event == null && newEvent != null) {
                // Handle new event creation
                widget.events.add(newEvent);
              } else {
                // Handle event update or deletion
                widget.onUpdateEvent(
                    oldEvent, newEvent, _focusedDay, _focusedPersonIndex);
              }
              _updateFocusAfterEdit(oldEvent, newEvent);
              _isCellNavigation = true;
            });
          },
        );
      },
    );
  }

  void _updateFocusAfterEdit(Event? oldEvent, Event? newEvent) {
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

    if (newEvent != null) {
      // For both new and updated events
      _focusedEventIndex = cellEvents.indexOf(newEvent) + 1;
      _focusedEvent = newEvent;
    } else if (oldEvent != null) {
      // For deleted events
      _focusedEventIndex = cellEvents.isEmpty
          ? 0
          : cellEvents.indexOf(oldEvent).clamp(0, cellEvents.length - 1) + 1;
      _focusedEvent =
          _focusedEventIndex > 0 ? cellEvents[_focusedEventIndex - 1] : null;
    }

    if (cellEvents.isEmpty) {
      _exitEventKeyboardNavigation();
    } else {
      _isCellNavigation = true;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getCellBackgroundColor(DateTime date, bool isToday, bool isPast,
      bool isDateColumn, bool isSelectedInCellNavigation) {
    Color baseColor;
    if (isSelectedInCellNavigation) {
      baseColor = Colors.orange[50] ?? Colors.orange[100]!;
    } else if (isToday) {
      baseColor = Colors.yellow[100] ?? Colors.yellow;
    } else if (_isWeekend(date)) {
      baseColor = isPast ? Colors.grey[300]! : Colors.pink[50] ?? Colors.pink;
    } else if (isPast) {
      baseColor = Colors.grey[100] ?? Colors.grey;
    } else {
      baseColor = Colors.white;
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
      _isCellNavigation = false; // Set to false initially
      _focusedEventIndex = -1;
      _focusedEvent = null;
    });
    _focusNode.requestFocus();
    _scrollToFocusedCell();
  }

  void _updateFocusedEventIndex(Event oldEvent, Event? newEvent) {
    // ... existing implementation ...
  }
}

class _HoverableEventWidget extends StatefulWidget {
  final Event event;
  final DateTime now;
  final VoidCallback onTap;
  final String eventText;
  final bool isFocused;
  final bool isPseudoEvent;

  const _HoverableEventWidget({
    required this.event,
    required this.now,
    required this.onTap,
    required this.eventText,
    required this.isFocused,
    this.isPseudoEvent = false,
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
      onEnter: (_) {
        setState(() => isHovered = true);
      },
      onExit: (_) {
        setState(() => isHovered = false);
      },
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
          onTap: () {
            // Find the CalendarView ancestor
            final calendarViewState =
                context.findAncestorStateOfType<_CalendarViewState>();
            if (calendarViewState != null) {
              // Update the focused day and person index
              calendarViewState.setState(() {
                calendarViewState._focusedDay = widget.event.start!.day;
                calendarViewState._focusedPersonIndex =
                    calendarViewState.widget.people.indexWhere(
                        (person) => person.name == widget.event.person.name);
                calendarViewState._isCellNavigation = true;

                // Find the index of the clicked event in the cell
                final cellEvents = calendarViewState._getEventsForCell(
                    calendarViewState._focusedDay,
                    calendarViewState
                        .widget.people[calendarViewState._focusedPersonIndex]);
                calendarViewState._focusedEventIndex =
                    cellEvents.indexOf(widget.event) + 1;
                calendarViewState._focusedEvent = widget.event;
              });

              // Now that we've updated the state, call the original onTap
              widget.onTap();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: widget.isPseudoEvent
                  ? Colors.green.withOpacity(0.1)
                  : (widget.isFocused
                      ? Colors.blue.withOpacity(0.3)
                      : (isHovered
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.1))),
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
            child: RichText(
              text: TextSpan(
                children: [
                  if (!widget.isPseudoEvent)
                    TextSpan(
                      text: _formatEventTime(widget.event),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isHovered ? FontWeight.bold : FontWeight.normal,
                        decoration: isPast ? TextDecoration.lineThrough : null,
                        color: widget.isFocused
                            ? Colors.black
                            : (isHovered
                                ? (isPast ? Colors.grey : Colors.black)
                                : Colors.grey[500]),
                      ),
                    ),
                  TextSpan(
                    text: widget.event.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: widget.isPseudoEvent
                          ? FontWeight.bold
                          : (isHovered ? FontWeight.bold : FontWeight.normal),
                      decoration: isPast && !widget.isPseudoEvent
                          ? TextDecoration.lineThrough
                          : null,
                      color: widget.isPseudoEvent
                          ? Colors.green[700]
                          : (widget.isFocused
                              ? Colors.black
                              : (isHovered
                                  ? (isPast ? Colors.grey : Colors.black)
                                  : (isPast ? Colors.grey : Colors.black))),
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
              maxLines: null,
            ),
          ),
        ),
      ),
    );
  }

  String _formatEventTime(Event event) {
    String timeText = '';
    if (event.hasTime && event.start != null) {
      if (event.end != null) {
        timeText = '${_formatTime(event.start!)} - ${_formatTime(event.end!)} ';
      } else {
        timeText = '${_formatTime(event.start!)} ';
      }
    }
    return timeText;
  }

  String _formatTime(DateTime time) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(time);
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
