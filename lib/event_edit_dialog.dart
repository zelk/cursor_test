import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // Import this to access Event and Person classes

class EventEditDialog extends StatefulWidget {
  final Event event;
  final Function(Event oldEvent, Event? newEvent) onUpdateEvent;

  const EventEditDialog({
    Key? key,
    required this.event,
    required this.onUpdateEvent,
  }) : super(key: key);

  @override
  _EventEditDialogState createState() => _EventEditDialogState();
}

class _EventEditDialogState extends State<EventEditDialog> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late FocusNode titleFocusNode;
  late String description;
  late DateTime? start;
  late DateTime? end;
  late bool hasTime;
  late TextEditingController startTimeController;
  late TextEditingController endTimeController;
  late FocusNode startTimeFocusNode;
  late FocusNode endTimeFocusNode;
  late FocusNode descriptionFocusNode;
  bool _isKeyboardNavigation = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.event.title);
    titleFocusNode = FocusNode();

    description = widget.event.description;
    start = widget.event.start;
    end = widget.event.end;
    hasTime = widget.event.hasTime;

    startTimeController = TextEditingController(
      text: widget.event.hasTime && widget.event.start != null
          ? _formatTimeOfDay(TimeOfDay.fromDateTime(widget.event.start!))
          : '',
    );
    endTimeController = TextEditingController(
      text: widget.event.hasTime && widget.event.end != null
          ? _formatTimeOfDay(TimeOfDay.fromDateTime(widget.event.end!))
          : '',
    );

    startTimeFocusNode = FocusNode();
    endTimeFocusNode = FocusNode();
    descriptionFocusNode = FocusNode();

    startTimeFocusNode
        .addListener(() => _handleFocusChange(startTimeFocusNode));
    endTimeFocusNode.addListener(() => _handleFocusChange(endTimeFocusNode));
    titleFocusNode.addListener(() => _handleFocusChange(titleFocusNode));
    descriptionFocusNode
        .addListener(() => _handleFocusChange(descriptionFocusNode));
  }

  @override
  void dispose() {
    titleFocusNode.dispose();
    titleController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    startTimeFocusNode
        .removeListener(() => _handleFocusChange(startTimeFocusNode));
    endTimeFocusNode.removeListener(() => _handleFocusChange(endTimeFocusNode));
    titleFocusNode.removeListener(() => _handleFocusChange(titleFocusNode));
    descriptionFocusNode
        .removeListener(() => _handleFocusChange(descriptionFocusNode));
    startTimeFocusNode.dispose();
    endTimeFocusNode.dispose();
    descriptionFocusNode.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour < 24 &&
          minute >= 0 &&
          minute < 60) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  void _handleFocusChange(FocusNode focusNode) {
    if (focusNode.hasFocus && _isKeyboardNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (focusNode == startTimeFocusNode) {
          startTimeController.selection = TextSelection(
              baseOffset: 0, extentOffset: startTimeController.text.length);
        } else if (focusNode == endTimeFocusNode) {
          endTimeController.selection = TextSelection(
              baseOffset: 0, extentOffset: endTimeController.text.length);
        } else if (focusNode == titleFocusNode) {
          titleController.selection = TextSelection(
              baseOffset: 0, extentOffset: titleController.text.length);
        } else if (focusNode == descriptionFocusNode) {
          // For multiline text fields, we need to use a different approach
          focusNode.requestFocus();
          SystemChannels.textInput.invokeMethod('TextInput.updateSelection', {
            'selectionBase': 0,
            'selectionExtent': description.length,
            'text': description,
          });
        }
      });
    }
    _isKeyboardNavigation = false;
  }

  void _handleTextFieldTap(
      TapDownDetails details, TextEditingController controller) {
    final TextPosition textPosition = controller.selection.base;
    final newPosition = controller.text.isNotEmpty
        ? TextSelection.collapsed(offset: textPosition.offset)
        : const TextSelection.collapsed(offset: 0);
    controller.selection = newPosition;
  }

  void submitForm() {
    if (formKey.currentState!.validate()) {
      final startTime = _parseTime(startTimeController.text);
      final endTime = _parseTime(endTimeController.text);

      final DateTime? startDateTime = startTime != null
          ? DateTime(
              start?.year ?? DateTime.now().year,
              start?.month ?? DateTime.now().month,
              start?.day ?? DateTime.now().day,
              startTime.hour,
              startTime.minute,
            )
          : start;

      final DateTime? endDateTime = endTime != null
          ? DateTime(
              end?.year ?? DateTime.now().year,
              end?.month ?? DateTime.now().month,
              end?.day ?? DateTime.now().day,
              endTime.hour,
              endTime.minute,
            )
          : null;

      final bool hasTimeValue = startTime != null;

      final updatedEvent = Event(
        start: startDateTime,
        end: endDateTime,
        title: titleController.text,
        description: description,
        person: widget.event.person,
        hasTime: hasTimeValue,
      );
      widget.onUpdateEvent(widget.event, updatedEvent);
      Navigator.of(context).pop();
    }
  }

  void deleteEvent() {
    widget.onUpdateEvent(widget.event, null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const CancelIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const SubmitIntent(),
      },
      child: Actions(
        actions: {
          CancelIntent: CallbackAction<CancelIntent>(
            onInvoke: (intent) {
              Navigator.of(context).pop();
              return null;
            },
          ),
          SubmitIntent: CallbackAction<SubmitIntent>(
            onInvoke: (intent) {
              submitForm();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: AlertDialog(
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTapDown: (details) =>
                          _handleTextFieldTap(details, titleController),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        controller: titleController,
                        focusNode: titleFocusNode,
                        onFieldSubmitted: (_) => submitForm(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTapDown: (details) => _handleTextFieldTap(
                                details, startTimeController),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Start Time',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                hintText: 'HH:mm',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(12),
                              ),
                              controller: startTimeController,
                              focusNode: startTimeFocusNode,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTapDown: (details) =>
                                _handleTextFieldTap(details, endTimeController),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'End Time',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                hintText: 'HH:mm',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(12),
                              ),
                              controller: endTimeController,
                              focusNode: endTimeFocusNode,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTapDown: (details) => _handleTextFieldTap(
                          details, TextEditingController(text: description)),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        initialValue: description,
                        onChanged: (value) => description = value,
                        maxLines: null,
                        minLines: 3,
                        textInputAction: TextInputAction.newline,
                        focusNode: descriptionFocusNode,
                      ),
                    ),
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
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          ),
        ),
      ),
    );
  }
}

class CancelIntent extends Intent {
  const CancelIntent();
}

class SubmitIntent extends Intent {
  const SubmitIntent();
}

class NextFocusIntent extends Intent {
  const NextFocusIntent();
}

class PreviousFocusIntent extends Intent {
  const PreviousFocusIntent();
}
