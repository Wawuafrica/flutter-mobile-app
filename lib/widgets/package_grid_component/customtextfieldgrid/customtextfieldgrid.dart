import 'package:flutter/material.dart';

class CustomTextfieldGrid extends StatefulWidget {
  final String hintText;
  final TextEditingController controller; // Non-nullable
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const CustomTextfieldGrid({
    super.key,
    required this.hintText,
    required this.controller,
    this.keyboardType,
    this.onChanged,
  });

  @override
  State<CustomTextfieldGrid> createState() => _CustomTextfieldGridState();
}

class _CustomTextfieldGridState extends State<CustomTextfieldGrid> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    // Controller is disposed by parent (PackageGridComponent)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      maxLines: 2,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(fontSize: 11),
        border: InputBorder.none,
      ),
    );
  }
}