import 'package:flutter/material.dart';
import 'package:pos_inventory/features/cart/model/cart_item.dart';

class TransaksiItem extends StatelessWidget {
  const TransaksiItem({
    super.key,
    required this.item,
    required this.onAdd,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '@Rp ${item.price}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: onRemove, // Panggil callback saat diklik
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "${item.qty}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onAdd, // Panggil callback saat diklik
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Rp ${item.total}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
