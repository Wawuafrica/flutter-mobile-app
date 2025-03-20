import 'package:flutter/material.dart';

class Customtextfieldgrid extends StatefulWidget {
  final String hintText;
  const Customtextfieldgrid({super.key, required this.hintText});

  @override
  State<Customtextfieldgrid> createState() => _CustomtextfieldgridState();
}

class _CustomtextfieldgridState extends State<Customtextfieldgrid> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 2,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(fontSize: 11),
        border: InputBorder.none,
      ),
    );
  }
}
