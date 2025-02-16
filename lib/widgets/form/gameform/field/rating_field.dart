// widgets/form/gameform/rating_field.dart

import 'package:flutter/material.dart';

class RatingField extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;

  const RatingField({
    Key? key,
    required this.rating,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('评分 - Rating: ${rating.toStringAsFixed(1)}'),
        Slider(
          value: rating,
          min: 0,
          max: 10,
          divisions: 100,
          label: rating.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}