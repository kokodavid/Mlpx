import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';

class ProgressGoalSection extends StatelessWidget {
  final int coins;
  const ProgressGoalSection({Key? key, this.coins = 230}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of pills
          Row(
            children: [
              // Learning plan pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppColors.sandyLight,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  "Learning plan",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              // Coins pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.sandyLight,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined,
                        color: Colors.grey, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      "$coins",
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Set your weekly goal
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDEDED),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.flag, color: Colors.orange[700], size: 22),
                ),
                const SizedBox(width: 14),
                const Text(
                  "Set your weekly goal",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
