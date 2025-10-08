import 'package:flutter/material.dart';
import '../../../app/presentation/widgets/app_bottom_nav.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  bool isLoading = false;

  // Dummy user data
  String name = 'Jan';
  String surname = 'Jansen';
  String email = 'jan@example.com';
  String phone = '0821234567';
  String userType = 'Student';
  String pickupLocation = 'Kampus Sentraal';
  double walletBalance = 250.75;

  // Form controllers
  late TextEditingController nameController;
  late TextEditingController surnameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: name);
    surnameController = TextEditingController(text: surname);
    emailController = TextEditingController(text: email);
    phoneController = TextEditingController(text: phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void handleSave() {
    setState(() {
      name = nameController.text;
      surname = surnameController.text;
      email = emailController.text;
      phone = phoneController.text;
      isEditing = false;
    });
  }

  void handleCancel() {
    setState(() {
      nameController.text = name;
      surnameController.text = surname;
      emailController.text = email;
      phoneController.text = phone;
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final initials = "${name[0]}${surname[0]}".toUpperCase();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Profiel",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      if (!isEditing)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => setState(() => isEditing = true),
                        )
                      else ...[
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: handleCancel,
                        ),
                        IconButton(
                          icon: const Icon(Icons.save, color: Colors.green),
                          onPressed: handleSave,
                        ),
                      ]
                    ],
                  )
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              child: Text(
                                initials,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("$name $surname",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(email,
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      userType,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Personal Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.person, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Persoonlike Inligting",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Name
                            _buildField(
                                label: "Naam",
                                controller: nameController,
                                enabled: isEditing),

                            const SizedBox(height: 12),

                            // Surname
                            _buildField(
                                label: "Van",
                                controller: surnameController,
                                enabled: isEditing),

                            const SizedBox(height: 12),

                            // Email
                            _buildField(
                                label: "E-pos Adres",
                                controller: emailController,
                                enabled: isEditing,
                                icon: Icons.mail),

                            const SizedBox(height: 12),

                            // Phone
                            _buildField(
                                label: "Selfoon Nommer",
                                controller: phoneController,
                                enabled: isEditing,
                                icon: Icons.phone),

                            const SizedBox(height: 12),

                            // User type
                            isEditing
                                ? DropdownButtonFormField<String>(
                                    value: userType,
                                    decoration: const InputDecoration(
                                      labelText: "Gebruiker Tipe",
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: "Student",
                                          child: Text("Student")),
                                      DropdownMenuItem(
                                          value: "Personeel",
                                          child: Text("Personeel")),
                                      DropdownMenuItem(
                                          value: "Ander", child: Text("Ander")),
                                    ],
                                    onChanged: (val) =>
                                        setState(() => userType = val ?? ""),
                                  )
                                : ListTile(
                                    leading: const Icon(Icons.badge),
                                    title: Text(userType),
                                  ),

                            const SizedBox(height: 12),

                            // Pickup location
                            isEditing
                                ? DropdownButtonFormField<String>(
                                    value: pickupLocation,
                                    decoration: const InputDecoration(
                                      labelText: "Haalpunt",
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: "Kampus Sentraal",
                                          child: Text("Kampus Sentraal")),
                                      DropdownMenuItem(
                                          value: "Biblioteek",
                                          child: Text("Biblioteek")),
                                      DropdownMenuItem(
                                          value: "Kafeteria",
                                          child: Text("Kafeteria")),
                                    ],
                                    onChanged: (val) => setState(
                                        () => pickupLocation = val ?? ""),
                                  )
                                : ListTile(
                                    leading: const Icon(Icons.location_on),
                                    title: Text(pickupLocation),
                                  ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Account Settings
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.settings, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Rekening Instellings",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Wallet Balance
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text("Beursie Balans",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text("Beskikbare fondse",
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "R${walletBalance.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text("Bestuur"),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Quick Actions
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.settings),
                                    label: const Text("Instellings"),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.help),
                                    label: const Text("Help"),
                                    onPressed: () {},
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Logout
                            OutlinedButton.icon(
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text(
                                "Teken Uit",
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Edit Mode Notice
                    if (isEditing)
                      Card(
                        color: Colors.amber.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.info, color: Colors.orange),
                          title: const Text(
                            "Wysig Modus: Maak jou veranderings en druk Stoor.",
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool enabled = false,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
