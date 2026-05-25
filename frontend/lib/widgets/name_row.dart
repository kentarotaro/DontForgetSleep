import 'package:flutter/material.dart';
import 'labeled_text_field.dart';

class NameRow extends StatelessWidget {
  final TextEditingController firstController;
  final TextEditingController lastController;

  const NameRow({
    super.key,
    required this.firstController,
    required this.lastController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LabeledTextField(
            label: 'First Name',
            controller: firstController,
            hintText: 'John',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LabeledTextField(
            label: 'Last Name',
            controller: lastController,
            hintText: 'Wick',
          ),
        ),
      ],
    );
  }
}
