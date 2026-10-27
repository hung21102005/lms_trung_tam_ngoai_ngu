import 'package:flutter/material.dart';

class EntityOption {
  const EntityOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// A selector for records already stored on the server. The field opens its
/// options on tap and filters them as the user types; callers receive only IDs
/// from a selected option, never arbitrary typed text.
class SearchableEntityField extends StatefulWidget {
  const SearchableEntityField({
    super.key,
    required this.label,
    required this.options,
    required this.onSelected,
    this.selectedId,
    this.hintText,
    this.enabled = true,
  });

  final String label;
  final String? hintText;
  final List<EntityOption> options;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final bool enabled;

  @override
  State<SearchableEntityField> createState() => _SearchableEntityFieldState();
}

class _SearchableEntityFieldState extends State<SearchableEntityField> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedId;
  bool _settingText = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _syncText();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant SearchableEntityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedId != oldWidget.selectedId ||
        widget.options != oldWidget.options) {
      _selectedId = widget.selectedId;
      _syncText();
    }
  }

  void _syncText() {
    final label = widget.options
        .where((option) => option.id == _selectedId)
        .map((option) => option.label)
        .firstOrNull;
    _settingText = true;
    _controller.text = label ?? '';
    _settingText = false;
  }

  void _onTextChanged() {
    if (_settingText || _selectedId == null) return;
    final selectedLabel = widget.options
        .where((option) => option.id == _selectedId)
        .map((option) => option.label)
        .firstOrNull;
    if (_controller.text != selectedLabel) {
      _selectedId = null;
      widget.onSelected(null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => DropdownMenu<String>(
        width: constraints.maxWidth,
        controller: _controller,
        enabled: widget.enabled,
        enableFilter: true,
        enableSearch: true,
        requestFocusOnTap: true,
        menuHeight: 320,
        label: Text(widget.label),
        hintText: widget.hintText ?? 'Bấm để chọn hoặc gõ để tìm',
        dropdownMenuEntries: widget.options
            .map(
              (option) => DropdownMenuEntry<String>(
                value: option.id,
                label: option.label,
              ),
            )
            .toList(),
        onSelected: (id) {
          _selectedId = id;
          widget.onSelected(id);
        },
      ),
    );
  }
}
