import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Address input with live suggestions while typing.
///
/// Suggestions come from OpenStreetMap's free Nominatim geocoder (no API key
/// required; fine for light business use). Selecting a suggestion fills the
/// field; free-typed text is always accepted as-is.
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;

  const AddressAutocompleteField({
    Key? key,
    required this.controller,
    this.labelText = 'Address',
    this.hintText,
    this.prefixIcon,
    this.validator,
  }) : super(key: key);

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  Timer? _debounce;
  List<String> _suggestions = [];
  bool _loading = false;
  String _lastPicked = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 5 || value == _lastPicked) {
      if (_suggestions.isNotEmpty || _loading) {
        setState(() {
          _suggestions = [];
          _loading = false;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=jsonv2&limit=5&addressdetails=0&q=${Uri.encodeComponent(query)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final results = (json.decode(res.body) as List)
            .map((r) => (r['display_name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        setState(() {
          _suggestions = results;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      // Offline or rate-limited — the field still works as plain text input
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pick(String suggestion) {
    _lastPicked = suggestion;
    widget.controller.text = suggestion;
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          onChanged: _onChanged,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText ?? 'Start typing an address...',
            prefixIcon: widget.prefixIcon ?? const Icon(Icons.location_on_outlined),
            border: const OutlineInputBorder(),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (_suggestions.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            elevation: 3,
            child: Column(
              children: _suggestions
                  .map((s) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.place, size: 18),
                        title: Text(s, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => _pick(s),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
