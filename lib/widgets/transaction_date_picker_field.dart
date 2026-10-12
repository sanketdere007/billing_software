import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'app_message_dialog.dart';

/// Custom input formatter that automatically maintains the `yyyy/MM/dd` format.
///
/// Features:
/// - Allows only digits and slashes.
/// - Automatically inserts `/` after year (4 digits) and month (2 digits).
/// - Gracefully handles backspace without trapping the user on slashes.
/// - Keeps the cursor in the appropriate position when editing.
class DateTextInputFormatter extends TextInputFormatter {
  const DateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    String newText = newValue.text;

    if (newText.isEmpty) {
      return newValue;
    }

    final bool isDeleting = newText.length < oldText.length;

    // If backspacing on a trailing slash (e.g. "2026/" or "2026/10/"),
    // remove the preceding digit as well to avoid being trapped on the slash.
    if (isDeleting &&
        oldText.endsWith('/') &&
        newText == oldText.substring(0, oldText.length - 1)) {
      newText = newText.substring(0, newText.length - 1);
    }

    // Extract only digits
    final digitsOnly = newText.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Limit to 8 digits (YYYYMMDD)
    final clampedDigits =
        digitsOnly.length > 8 ? digitsOnly.substring(0, 8) : digitsOnly;

    final buffer = StringBuffer();
    for (int i = 0; i < clampedDigits.length; i++) {
      if (i == 4 || i == 6) {
        buffer.write('/');
      }
      buffer.write(clampedDigits[i]);
    }

    // If user explicitly typed a slash at year or month boundary, keep it
    if ((clampedDigits.length == 4 || clampedDigits.length == 6) &&
        newText.endsWith('/')) {
      buffer.write('/');
    }

    final formatted = buffer.toString();

    // Determine target cursor offset
    int newCursorOffset = formatted.length;
    if (!isDeleting && newValue.selection.end < newValue.text.length) {
      final digitsBeforeCursor = newValue.text
          .substring(0, newValue.selection.end.clamp(0, newValue.text.length))
          .replaceAll(RegExp(r'[^\d]'), '')
          .length;
      int count = 0;
      int targetOffset = 0;
      for (int i = 0; i < formatted.length; i++) {
        if (formatted[i] != '/') {
          count++;
        }
        if (count == digitsBeforeCursor) {
          targetOffset = i + 1;
          break;
        }
      }
      newCursorOffset = targetOffset.clamp(0, formatted.length);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}

/// Reusable Transaction Date Picker Field for Sales & Purchase Entry screens.
///
/// Supports:
/// 1. Dynamic future-date restriction (disables dates > today).
/// 2. Manual keyboard entry in `yyyy/MM/dd` format.
/// 3. Immediate validation on Enter when manually entered:
///    - Valid: accepts date, does NOT open calendar, moves focus to next field.
///    - Invalid: shows warning dialog, keeps focus on date field.
/// 4. Enter without manual typing: opens calendar date picker.
/// 5. Clicking calendar icon opens date picker normally.
class TransactionDatePickerField extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final VoidCallback? onNextFocus;
  final String labelText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool restrictFutureDates;
  final bool isRequired;
  final bool enabled;

  const TransactionDatePickerField({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
    this.focusNode,
    this.nextFocusNode,
    this.onNextFocus,
    this.labelText = 'Invoice Date',
    this.firstDate,
    this.lastDate,
    this.restrictFutureDates = true,
    this.isRequired = true,
    this.enabled = true,
  });

  /// Validates a date string in `yyyy/MM/dd` format.
  /// Returns an error message if invalid, or `null` if valid.
  static String? validateDateString(
    String rawText, {
    bool restrictFutureDates = true,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return 'Please enter a date.';
    }

    final parts = text.split(RegExp(r'[/-]'));
    if (parts.length != 3) {
      return 'Please enter a valid date in yyyy/MM/dd format.';
    }

    final yearStr = parts[0];
    final monthStr = parts[1];
    final dayStr = parts[2];

    if (yearStr.length != 4) {
      return 'Please enter a valid 4-digit year.';
    }

    final year = int.tryParse(yearStr);
    final month = int.tryParse(monthStr);
    final day = int.tryParse(dayStr);

    if (year == null || year < (firstDate?.year ?? 2000)) {
      return 'Year cannot be earlier than ${firstDate?.year ?? 2000}.';
    }

    if (month == null || month < 1 || month > 12) {
      return 'Invalid month ($monthStr). Month must be between 01 and 12.';
    }

    // Days in month calculation (including leap year for February)
    final bool isLeapYear =
        (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    int maxDaysInMonth;
    switch (month) {
      case 2:
        maxDaysInMonth = isLeapYear ? 29 : 28;
        break;
      case 4:
      case 6:
      case 9:
      case 11:
        maxDaysInMonth = 30;
        break;
      default:
        maxDaysInMonth = 31;
    }

    if (day == null || day < 1 || day > maxDaysInMonth) {
      if (day != null && day > 31) {
        return 'Invalid day ($dayStr). Day cannot be greater than 31.';
      }
      if (day != null && day < 1) {
        return 'Invalid day ($dayStr). Day must be at least 01.';
      }
      if (month == 2) {
        return 'February $year has only $maxDaysInMonth days.';
      }
      return 'The selected month has only $maxDaysInMonth days.';
    }

    final enteredDate = DateTime(year, month, day);

    // Restrict future dates dynamically
    if (restrictFutureDates) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (enteredDate.isAfter(today)) {
        return 'Future dates are not allowed. Please enter today\'s date or an earlier date.';
      }
    }

    if (firstDate != null) {
      final min = DateTime(firstDate.year, firstDate.month, firstDate.day);
      if (enteredDate.isBefore(min)) {
        final fmt = DateFormat('yyyy/MM/dd');
        return 'Date cannot be earlier than ${fmt.format(min)}.';
      }
    }

    if (lastDate != null) {
      final max = DateTime(lastDate.year, lastDate.month, lastDate.day);
      if (enteredDate.isAfter(max)) {
        final fmt = DateFormat('yyyy/MM/dd');
        return 'Date cannot be later than ${fmt.format(max)}.';
      }
    }

    return null;
  }

  /// Parses a date string formatted as `yyyy/MM/dd` if valid, otherwise returns null.
  static DateTime? tryParseDate(String rawText) {
    final text = rawText.trim();
    final parts = text.split(RegExp(r'[/-]'));
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    int maxDays;
    switch (month) {
      case 2:
        maxDays = isLeapYear ? 29 : 28;
        break;
      case 4:
      case 6:
      case 9:
      case 11:
        maxDays = 30;
        break;
      default:
        maxDays = 31;
    }
    if (day > maxDays) return null;
    return DateTime(year, month, day);
  }

  @override
  State<TransactionDatePickerField> createState() =>
      _TransactionDatePickerFieldState();
}

class _TransactionDatePickerFieldState
    extends State<TransactionDatePickerField> {
  static final DateFormat _displayFormat = DateFormat('yyyy/MM/dd');

  final MenuController _menuController = MenuController();
  late final TextEditingController _controller;
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  DateTime? _currentDate;
  bool _hasUserEdited = false;
  String _textWhenFocusGained = '';
  String? _errorText;
  bool _isSubmitting = false;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _formatDate(DateTime date) => _displayFormat.format(date);

  @override
  void initState() {
    super.initState();
    _currentDate = widget.selectedDate ?? _today;
    _controller = TextEditingController(text: _formatDate(_currentDate!));
    _textWhenFocusGained = _controller.text;

    _effectiveFocusNode.addListener(_handleFocusChange);
    _effectiveFocusNode.onKeyEvent = _handleKeyEvent;
  }

  @override
  void didUpdateWidget(covariant TransactionDatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      oldWidget.focusNode?.onKeyEvent = null;
      _effectiveFocusNode.addListener(_handleFocusChange);
      _effectiveFocusNode.onKeyEvent = _handleKeyEvent;
    }

    if (widget.selectedDate != null &&
        widget.selectedDate != oldWidget.selectedDate &&
        widget.selectedDate != _currentDate) {
      _currentDate = widget.selectedDate;
      _controller.text = _formatDate(_currentDate!);
      _hasUserEdited = false;
      _textWhenFocusGained = _controller.text;
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _effectiveFocusNode.onKeyEvent = null;
    _internalFocusNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _closeCalendarPopup() {
    if (_menuController.isOpen) {
      _menuController.close();
    }
  }

  void _openCalendarPopup() {
    if (!_menuController.isOpen) {
      final typed = TransactionDatePickerField.tryParseDate(_controller.text);
      if (typed != null && !typed.isAfter(_today)) {
        _currentDate = typed;
      }
      setState(() {});
      _menuController.open();
    }
  }

  void _toggleCalendarPopup() {
    if (_menuController.isOpen) {
      _closeCalendarPopup();
    } else {
      _openCalendarPopup();
    }
  }

  void _handleFocusChange() {
    if (_effectiveFocusNode.hasFocus) {
      // Focus gained: reset manual edit tracking and select all text.
      // Do NOT open calendar popup automatically on focus.
      _hasUserEdited = false;
      _textWhenFocusGained = _controller.text;
      _errorText = null;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      // Focus lost: close popup if open
      _closeCalendarPopup();

      // If user typed something valid, commit it.
      // If invalid, revert back to last valid date so form state is never broken.
      if (_hasUserEdited) {
        final err = TransactionDatePickerField.validateDateString(
          _controller.text,
          restrictFutureDates: widget.restrictFutureDates,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
        );
        if (err == null) {
          final parsed = TransactionDatePickerField.tryParseDate(
            _controller.text,
          );
          if (parsed != null) {
            _currentDate = parsed;
            widget.onDateSelected(parsed);
          }
        } else {
          // Revert to last valid date
          _controller.text = _formatDate(_currentDate ?? _today);
        }
        _hasUserEdited = false;
        _errorText = null;
        if (mounted) setState(() {});
      }
    }
  }

  void _advanceFocus() {
    if (widget.onNextFocus != null) {
      widget.onNextFocus!();
    } else if (widget.nextFocusNode != null) {
      widget.nextFocusNode!.requestFocus();
    } else {
      FocusScope.of(context).nextFocus();
    }
  }

  DateTime _getInitialPickerDate() {
    final today = _today;
    final first = widget.firstDate ?? DateTime(2000);

    DateTime initial = _currentDate ?? today;
    final typed = TransactionDatePickerField.tryParseDate(_controller.text);
    if (typed != null && !typed.isAfter(today) && !typed.isBefore(first)) {
      initial = typed;
    }

    if (initial.isAfter(today) && widget.restrictFutureDates) {
      initial = today;
    }
    if (initial.isBefore(first)) {
      initial = first;
    }
    return initial;
  }

  void _onDatePickedFromCalendar(DateTime picked) {
    _closeCalendarPopup();
    setState(() {
      _currentDate = picked;
      _controller.text = _formatDate(picked);
      _hasUserEdited = false;
      _textWhenFocusGained = _controller.text;
      _errorText = null;
    });
    widget.onDateSelected(picked);
    _advanceFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      _submitAndAdvanceFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _submitAndAdvanceFocus([String? value]) {
    if (_isSubmitting) return;
    _isSubmitting = true;

    // Pressing Enter should never open the calendar popup
    _closeCalendarPopup();

    final text = _controller.text.trim();

    // If the date field is empty and user presses Enter, move to next field
    if (text.isEmpty) {
      _isSubmitting = false;
      _advanceFocus();
      return;
    }

    // Validate the entered date
    final error = TransactionDatePickerField.validateDateString(
      text,
      restrictFutureDates: widget.restrictFutureDates,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );

    if (error != null) {
      setState(() {
        _errorText = error;
      });
      showWarningDialog(context, error).then((_) {
        if (mounted) {
          _effectiveFocusNode.requestFocus();
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        }
        _isSubmitting = false;
      });
      return;
    }

    final parsed = TransactionDatePickerField.tryParseDate(text)!;
    setState(() {
      _currentDate = parsed;
      _hasUserEdited = false;
      _textWhenFocusGained = _controller.text;
      _errorText = null;
    });
    widget.onDateSelected(parsed);
    _isSubmitting = false;
    _advanceFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _today;
    final effectiveFirstDate = widget.firstDate ?? DateTime(2000);
    final effectiveLastDate = widget.restrictFutureDates
        ? today
        : (widget.lastDate ?? DateTime(2101));

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        padding: MaterialStateProperty.all(EdgeInsets.zero),
        elevation: MaterialStateProperty.all(8),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return TextFormField(
          controller: _controller,
          focusNode: _effectiveFocusNode,
          enabled: widget.enabled,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          inputFormatters: const [
            DateTextInputFormatter(),
          ],
          onChanged: (val) {
            if (val != _textWhenFocusGained) {
              _hasUserEdited = true;
            }
            if (_menuController.isOpen) {
              _closeCalendarPopup();
            }
            if (_errorText != null) {
              setState(() {
                _errorText = null;
              });
            }
          },
          onFieldSubmitted: (_) => _submitAndAdvanceFocus(),
          validator: widget.isRequired
              ? (val) => TransactionDatePickerField.validateDateString(
                  val ?? '',
                  restrictFutureDates: widget.restrictFutureDates,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                )
              : null,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            errorText: _errorText,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2.0,
              ),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today, size: 20),
              tooltip: 'Select date',
              onPressed: widget.enabled ? _toggleCalendarPopup : null,
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
              initialDate: _getInitialPickerDate(),
              firstDate: effectiveFirstDate,
              lastDate: effectiveLastDate,
              onDateChanged: (date) {
                _onDatePickedFromCalendar(date);
              },
            ),
          ),
        ),
      ],
    );
  }
}
