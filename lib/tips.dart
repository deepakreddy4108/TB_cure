import 'package:flutter/material.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get device screen size for responsive layout
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Oral Health Tips',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF02adec),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Improve Your Smile with These Tips',
                style: TextStyle(
                  fontSize: screenWidth * 0.06, // Responsive font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Follow these simple yet effective oral health practices to maintain a bright and healthy smile.',
                style: TextStyle(
                  fontSize: screenWidth * 0.04, // Responsive font size
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20.0),
              // Use Expanded to avoid layout overflow
              Expanded(
                child: ListView(
                  children: [
                    _buildTipTile(
                      title: 'Maintain Good Oral Hygiene',
                      description: 'Brush your teeth at least twice a day and floss daily.',
                      icon: Icons.brush,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Visit Your Dentist Regularly',
                      description: 'Regular dental check-ups help maintain oral health.',
                      icon: Icons.medical_services,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Limit Sugary Foods',
                      description: 'Reduce sugar intake to prevent cavities.',
                      icon: Icons.no_meals,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Stay Hydrated',
                      description: 'Drink plenty of water to help wash away food particles.',
                      icon: Icons.local_drink,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Use Mouthwash',
                      description: 'Mouthwash can help reduce plaque and fight bad breath.',
                      icon: Icons.water_drop,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Eat a Balanced Diet',
                      description: 'Include fruits, vegetables, and dairy in your diet for healthy teeth.',
                      icon: Icons.fastfood,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Avoid Smoking',
                      description: 'Smoking can cause gum disease and oral cancer. Quit smoking for better oral health.',
                      icon: Icons.smoking_rooms,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Wear a Mouthguard',
                      description: 'Protect your teeth during sports or physical activities with a mouthguard.',
                      icon: Icons.sports_mma,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Chew Sugar-Free Gum',
                      description: 'Chewing sugar-free gum after meals helps stimulate saliva production.',
                      icon: Icons.bubble_chart,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Replace Your Toothbrush Regularly',
                      description: 'Replace your toothbrush every 3-4 months or sooner if the bristles are frayed.',
                      icon: Icons.change_circle,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Avoid Nail Biting',
                      description: 'Nail biting can chip teeth and impact jaw health. Find alternatives to reduce this habit.',
                      icon: Icons.no_accounts,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Use Fluoride Toothpaste',
                      description: 'Fluoride strengthens tooth enamel and helps prevent decay.',
                      icon: Icons.check_circle,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Rinse After Meals',
                      description: 'Rinse your mouth with water after meals to remove food particles.',
                      icon: Icons.ramen_dining,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Monitor Your Child’s Oral Health',
                      description: 'Teach children proper brushing techniques and supervise their oral hygiene habits.',
                      icon: Icons.child_care,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Avoid Excessive Alcohol',
                      description: 'Excessive alcohol consumption can lead to dry mouth and oral health issues.',
                      icon: Icons.no_drinks,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Eat Teeth-Friendly Foods',
                      description: 'Crunchy fruits and vegetables like apples and carrots naturally clean your teeth.',
                      icon: Icons.apple,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Address Teeth Grinding',
                      description: 'Use a nightguard if you grind your teeth to prevent wear and tear.',
                      icon: Icons.nights_stay,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Be Gentle with Your Teeth',
                      description: 'Avoid using your teeth as tools to open bottles or tear packaging.',
                      icon: Icons.construction,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    _buildTipTile(
                      title: 'Keep Your Tongue Clean',
                      description: 'Use a tongue scraper or brush your tongue to remove bacteria.',
                      icon: Icons.cleaning_services,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipTile({
    required String title,
    required String description,
    required IconData icon,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02), // Responsive padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: screenWidth * 0.08, // Responsive icon size
            color: const Color(0xFF02adec),
          ),
          SizedBox(width: screenWidth * 0.03), // Responsive space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.05, // Responsive text size
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01), // Responsive space
                Text(
                  description,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04, // Responsive text size
                    color: Colors.grey[700],
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
