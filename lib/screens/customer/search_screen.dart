import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tìm kiếm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ô tìm kiếm
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm resort, khách sạn...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 28),

            const Text(
              'Tìm kiếm phổ biến',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SearchChip(
                  label: 'Phú Quốc',
                  onTap: () {
                    _searchController.text = 'Phú Quốc';
                  },
                ),
                _SearchChip(
                  label: 'Đà Nẵng',
                  onTap: () {
                    _searchController.text = 'Đà Nẵng';
                  },
                ),
                _SearchChip(
                  label: 'Nha Trang',
                  onTap: () {
                    _searchController.text = 'Nha Trang';
                  },
                ),
                _SearchChip(
                  label: 'Đà Lạt',
                  onTap: () {
                    _searchController.text = 'Đà Lạt';
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            if (_searchController.text.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Nhập địa điểm để tìm kiếm',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text(
                    'Đang tìm kiếm: ${_searchController.text}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(
        Icons.location_on_outlined,
        size: 18,
      ),
    );
  }
}