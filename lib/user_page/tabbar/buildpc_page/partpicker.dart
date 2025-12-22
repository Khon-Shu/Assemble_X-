import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class PartPicker<T> extends StatefulWidget {
  final Future<List<T>> Function() fetchItems;
  final String title;
  final Widget Function(T) buildRow;
  final String Function(T) getName;
  final String Function(T) getPrice;
  final String? Function(T) getImageUrl;

  const PartPicker({
    super.key,
    required this.fetchItems,
    required this.title,
    required this.buildRow,
    required this.getName,
    required this.getPrice,
    required this.getImageUrl,
  });

  @override
  State<PartPicker<T>> createState() => _PartPickerState<T>();
}

class _PartPickerState<T> extends State<PartPicker<T>> {
  List<T> _items = [];
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final data = await widget.fetchItems();
      setState(() {
        _items = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading ${widget.title}: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildImageWidget(String? imageUrl, {double size = 40}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset('assets/images/default.png',
          width: size, height: size, fit: BoxFit.cover);
    }
    if (imageUrl.startsWith('/data/')) {
      return Image.file(File(imageUrl),
          width: size, height: size, fit: BoxFit.cover);
    } else {
      return Image.asset(imageUrl,
          width: size, height: size, fit: BoxFit.cover);
    }
  }

  void _showPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => SizedBox(
        width: double.infinity,
        height: 300,
        child: Column(
          children: [
            // Header
            Container(
              color: CupertinoColors.systemBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(widget.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 70,
                scrollController:
                    FixedExtentScrollController(initialItem: _selectedIndex),
                onSelectedItemChanged: (int index) {
                  setState(() => _selectedIndex = index);
                },
                children: _items.map((item) => widget.buildRow(item)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    if (_items.isEmpty) {
      return const Text("No items available");
    }
    final selected = _items[_selectedIndex];
    return CupertinoButton.filled(
      padding: const EdgeInsets.all(8),
      onPressed: () => _showPicker(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImageWidget(widget.getImageUrl(selected), size: 30),
          const SizedBox(width: 8),
          Text(widget.getName(selected),
              overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
