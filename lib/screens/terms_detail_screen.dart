import 'package:flutter/material.dart';
import '../models/terms_model.dart';

class TermsDetailScreen extends StatelessWidget {
  final TermsModel terms;

  const TermsDetailScreen({super.key, required this.terms});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(terms.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '버전: ${terms.version}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              '최종 업데이트: ${terms.lastUpdated.year}.${terms.lastUpdated.month.toString().padLeft(2, '0')}.${terms.lastUpdated.day.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              terms.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
