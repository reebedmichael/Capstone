import 'package:flutter/material.dart';
import 'toelae_bestuur_page.dart';
import 'gebruiker_tipes_toelae_page.dart';

class ToelaeMainPage extends StatefulWidget {
  const ToelaeMainPage({super.key});

  @override
  State<ToelaeMainPage> createState() => _ToelaeMainPageState();
}

class _ToelaeMainPageState extends State<ToelaeMainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toelae Bestuur'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_add_alt_1), text: 'Individueel'),
            Tab(icon: Icon(Icons.group_work), text: 'Gebruiker Tipes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ToelaeBestuurPage(), GebruikerTipesToelaePage()],
      ),
    );
  }
}
