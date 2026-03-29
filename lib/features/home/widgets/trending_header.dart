import 'package:flutter/material.dart';

class TrendingHeader extends StatelessWidget {
  const TrendingHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.trending_up, color: Colors.orange),
        SizedBox(width: 8),
        Text(
          'Trending Now',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        Spacer(),
        Text('More →',
            style: TextStyle(
                color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
      ],
    );
  }
}
