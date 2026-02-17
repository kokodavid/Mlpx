import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final int points;

  const HomeHeader({
    Key? key,
    required this.userName,
    this.profileImageUrl,
    this.points = 32, // Example value
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello $userName",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              context.push('/profile');
            },
            child: CircleAvatar(
              radius: 19,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : (userName == 'Guest' ? const AssetImage('assets/turtle.png') as ImageProvider : null),
              child: profileImageUrl == null && userName != 'Guest'
                  ? Text(
                userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}