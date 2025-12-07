import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String profileImageUrl;
  final int points;

  const HomeHeader({
    Key? key,
    required this.userName,
    required this.profileImageUrl,
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
                  "Hi, $userName",
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
            child: const CircleAvatar(
              radius: 19,
              backgroundImage: AssetImage('assets/turtle.png'),
            ),
          ),
        ],
      ),
    );
  }
}
