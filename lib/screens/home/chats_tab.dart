import 'package:flutter/material.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [Tab(text: 'Social'), Tab(text: 'Jobs')],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Center(child: Text('DMs from users', style: TextStyle(color: Colors.white))),
                Center(child: Text('DMs from job opportunities', style: TextStyle(color: Colors.white))),
              ],
            ),
          )
        ],
      ),
    );
  }
}
