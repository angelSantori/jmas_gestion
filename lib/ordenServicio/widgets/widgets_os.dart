import 'package:flutter/material.dart';

Widget buildRatingRow(String label, int? rating) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child:
              rating != null
                  ? buildStarRating(rating)
                  : const Text('No disponible', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );
}

Widget buildStarRating(int rating) {
  return Row(
    children: List.generate(5, (index) {
      return Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: const Color.fromARGB(255, 7, 85, 255),
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
        size: 24,
      );
    }),
  );
}
