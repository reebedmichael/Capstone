// dashboard_header.dart
import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String? ingetekendGebruikerNaam;
  final int ongeleeseKennisgewings;
  final VoidCallback onNavigeerNaKennisgewings;
  final VoidCallback onUitteken;

  const DashboardHeader({
    super.key,
    required this.ingetekendGebruikerNaam,
    required this.ongeleeseKennisgewings,
    required this.onNavigeerNaKennisgewings,
    required this.onUitteken,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Left section: logo + title + welcome
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text("🍽️", style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Spys Admin Dashboard",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    "Welkom terug, ${ingetekendGebruikerNaam ?? ''}",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),

          /// Right section: notification button + sign out
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  OutlinedButton(
                    onPressed: onNavigeerNaKennisgewings,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.notifications, size: 20),
                  ),
                  if (ongeleeseKennisgewings > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ongeleeseKennisgewings.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onUitteken,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Teken Uit"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
