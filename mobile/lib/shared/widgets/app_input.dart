import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.obscureText = false,
    this.showToggle = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final bool obscureText;
  final bool showToggle;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        suffixIcon: widget.showToggle
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: PhosphorIcon(
                  _obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                ),
              )
            : null,
      ),
    );
  }
}
