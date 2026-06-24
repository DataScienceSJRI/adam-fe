import 'package:adam/data/models/preference_model.dart';
import 'package:flutter/material.dart';

class FoodTile extends StatelessWidget {
  final PreferenceModel item;
  final bool isSelected;
  final VoidCallback onTap;
  final String? imageUrl;

  const FoodTile({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green.shade700 : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color:
              isSelected ? Colors.green.withOpacity(0.3) : Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wrap image/icon with Flexible to prevent overflow
                  Flexible(
                    child: imageUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(item.icon ?? Icons.fastfood,
                                size: 42, color: Colors.green.shade700),
                      ),
                    )
                        : Icon(item.icon,
                        size: 42, color: Colors.green.shade700),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.green.shade700,
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
