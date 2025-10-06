// dashboard_header.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';

class DashboardHeader extends StatefulWidget {
  final int ongeleeseKennisgewings;
  final VoidCallback onNavigeerNaKennisgewings;
  final VoidCallback onUitteken;

  const DashboardHeader({
    super.key,
    required this.ongeleeseKennisgewings,
    required this.onNavigeerNaKennisgewings,
    required this.onUitteken,
  });

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  late final GebruikersRepository _gebruikersRepo;
  String? _userName;
  String? _userSurname;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final supabaseClient = Supabase.instance.client;
    _gebruikersRepo = GebruikersRepository(SupabaseDb(supabaseClient));
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _errorMessage = 'No authenticated user found';
          _isLoading = false;
        });
        return;
      }

      final userData = await _gebruikersRepo.kryGebruiker(currentUserId);
      if (userData != null) {
        setState(() {
          _userName = userData['gebr_naam'] as String?;
          _userSurname = userData['gebr_van'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User data not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load user data: $e';
        _isLoading = false;
      });
    }
  }

  String _getWelcomeMessage() {
    if (_isLoading) {
      return "Welkom terug...";
    }

    if (_errorMessage != null) {
      return "Welkom terug, Admin";
    }

    if (_userName != null && _userSurname != null) {
      return "Welkom terug, $_userName $_userSurname";
    } else if (_userName != null) {
      return "Welkom terug, $_userName";
    } else {
      return "Welkom terug, Admin";
    }
  }

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
                    _getWelcomeMessage(),
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
                    onPressed: widget.onNavigeerNaKennisgewings,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.notifications, size: 20),
                  ),
                  if (widget.ongeleeseKennisgewings > 0)
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
                          widget.ongeleeseKennisgewings.toString(),
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
                onPressed: widget.onUitteken,
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
