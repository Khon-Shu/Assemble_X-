import 'package:flutter/material.dart';
import 'dart:io';

class ViewSavedBuildContext extends StatelessWidget {
  final String build_name;
  final String price;
  final String imageUrl;
  final VoidCallback? onView;

  const ViewSavedBuildContext({
    required this.build_name,
    required this.price,
    required this.imageUrl,
    this.onView,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarProvider;
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('/data/')) {
        final file = File(imageUrl);
        if (file.existsSync()) {
          avatarProvider = FileImage(file);
        }
      } else {
        avatarProvider = AssetImage(imageUrl);
      }
    }

    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
        border: Border.all(width: 1.5, style: BorderStyle.solid, color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: avatarProvider != null
                    ? Image(
                        image: avatarProvider,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.computer, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    build_name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Price: $price', style: const TextStyle(color: Colors.green)),
                ],
              ),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
              ),
              onPressed: onView,
              child: const Text(
                'View',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}