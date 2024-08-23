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

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.event.title);
    titleFocusNode = FocusNode();

    description = widget.event.description;
    start = widget.event.start;
    end = widget.event.end;
    hasTime = widget.event.hasTime;

    // Schedule a callback to focus the title field after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(titleFocusNode);
    });
  }

  @override
  void dispose() {
    titleFocusNode.dispose();
    titleController.dispose();
    super.dispose();
  }

  void submitForm() {
    if (formKey.currentState!.validate()) {
      final updatedEvent = Event(
        start: start,
        end: end,
        title: titleController.text,
        description: description,
        person: widget.event.person,
        hasTime: hasTime,
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
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      controller: titleController,
                      focusNode: titleFocusNode,
                      onFieldSubmitted: (_) => submitForm(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
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
