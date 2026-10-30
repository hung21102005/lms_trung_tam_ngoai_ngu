import 'package:flutter/material.dart';

import 'mobile/mobile_ui.dart';

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
    if (MediaQuery.sizeOf(context).width < 600) {
      final selectedLabel = widget.options
          .where((option) => option.id == _selectedId)
          .map((option) => option.label)
          .firstOrNull;
      return InkWell(
        onTap: widget.enabled ? _showMobilePicker : null,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
            enabled: widget.enabled,
          ),
          isEmpty: selectedLabel == null,
          child: Text(
            selectedLabel ?? widget.hintText ?? 'Bấm để chọn hoặc gõ để tìm',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: selectedLabel == null
                ? TextStyle(color: Theme.of(context).hintColor)
                : null,
          ),
        ),
      );
    }
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

  Future<void> _showMobilePicker() async {
    String query = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final visible = widget.options
              .where(
                (option) =>
                    option.label.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
          return Padding(
            padding: EdgeInsets.only(
              left: MobileTokens.gutter,
              right: MobileTokens.gutter,
              bottom:
                  MediaQuery.viewInsetsOf(sheetContext).bottom +
                  MobileTokens.gutter,
            ),
            child: SizedBox(
              height:
                  (MediaQuery.sizeOf(sheetContext).height -
                      MediaQuery.viewInsetsOf(sheetContext).bottom) *
                  0.65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.label,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => setSheetState(() => query = value),
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo tên hoặc mã',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: visible.isEmpty
                        ? const Center(child: Text('Không có mục phù hợp'))
                        : ListView.builder(
                            itemCount: visible.length,
                            itemBuilder: (_, index) {
                              final option = visible[index];
                              return ListTile(
                                title: Text(option.label),
                                trailing: option.id == _selectedId
                                    ? const Icon(Icons.check_rounded)
                                    : null,
                                onTap: () =>
                                    Navigator.pop(sheetContext, option.id),
                              );
                            },
                          ),
                  ),
                  if (_selectedId != null)
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext, ''),
                      child: const Text('Bỏ chọn'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || selected == null) return;
    final id = selected.isEmpty ? null : selected;
    setState(() {
      _selectedId = id;
      _syncText();
    });
    widget.onSelected(id);
  }
}
