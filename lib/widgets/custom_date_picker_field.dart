import 'package:flutter/material.dart';

class CustomDatePickerField extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onDateSelected;
  final String labelText;

  const CustomDatePickerField({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    required this.onDateSelected,
    required this.labelText,
  });

  @override
  State<CustomDatePickerField> createState() => _CustomDatePickerFieldState();
}

class _CustomDatePickerFieldState extends State<CustomDatePickerField> {
  final MenuController _menuController = MenuController();
  final FocusNode _focusNode = FocusNode();

  void _closeDropdown() {
    if (_menuController.isOpen) {
      _menuController.close();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      childFocusNode: _focusNode,
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        padding: MaterialStateProperty.all(EdgeInsets.zero),
        elevation: MaterialStateProperty.all(8),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.labelText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: const Icon(Icons.calendar_today, size: 20),
            ),
            child: Text(
              widget.initialDate != null
                  ? widget.initialDate!.toIso8601String().split('T').first
                  : 'Select Date',
            ),
          ),
        );
      },
      menuChildren: [
        SizedBox(
          width: 320,
          height: 350,
          child: Theme(
            data: Theme.of(context),
            child: CalendarDatePicker(
              initialDate: widget.initialDate ?? DateTime.now(),
              firstDate: widget.firstDate ?? DateTime(2000),
              lastDate: widget.lastDate ?? DateTime(2101),
              onDateChanged: (date) {
                widget.onDateSelected(date);
                _closeDropdown();
              },
            ),
          ),
        ),
      ],
    );
  }
}
