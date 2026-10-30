// Importing necessary packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:legalai/legal_chat_page.dart';
import 'package:legalai/legal_chat_provider.dart';
import 'package:provider/provider.dart';

/// CustomPainter to draw animated sine wave background
class WaveBackground extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // Draw multiple horizontal sine waves
    for (var i = 0; i < height; i += 50) {
      path.reset();
      path.moveTo(0, i.toDouble());
      for (var x = 0; x < width; x += 20) {
        path.lineTo(
          x.toDouble(),
          i + math.sin(x * 0.03) * 20,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// HomePage widget - Main screen with navigation tabs
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

/// HomePage stateful logic
class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0; // Tracks current tab
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final bool _hasNotifications = true;
  late final LegalChatProvider _chatProvider;

  // Stores recent chat activities (up to 3)
  List<Map<String, Object>> recentActivities = [];

  /// Navigates to the chat screen and adds to recent activities
  void _navigateToChat(String title, bool clear, String baseUrl, String dir, String ques, {String filetype = 'json'}) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => LegalChatPage(
            heading: title,
            clear: clear,
            baseUrl: baseUrl,
            direc: dir,
            ques: ques,
            filetype: filetype,
          )))
        .then((_) {
      // Update recent activity after returning
      setState(() {
        if (recentActivities.length >= 3) {
          recentActivities.removeAt(0);
        }
        recentActivities.insert(0, {
          'title': title,
          'description': 'Case Summarization...',
          'time': DateTime.now().toIso8601String()
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chatProvider = Provider.of<LegalChatProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Background wave animation
          CustomPaint(
            painter: WaveBackground(),
            size: MediaQuery.of(context).size,
          ),
          Column(
            children: [
              // AppBar with app title and actions
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                title: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withAlpha(50),
                      child: Icon(Icons.gavel, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Text("LegalAssist", style: theme.textTheme.titleLarge),
                  ],
                ),
                actions: [
                  // Notification icon with badge
                  IconButton(
                    icon: Stack(
                      children: [
                        Icon(Icons.notifications_outlined,
                            color: context.watch<LegalChatProvider>().isDarkMode
                                ? Colors.white
                                : Colors.black),
                        if (_hasNotifications)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {},
                  ),
                  // Theme toggle
                  IconButton(
                    icon: Icon(
                      context.watch<LegalChatProvider>().isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    onPressed: () {
                      context.read<LegalChatProvider>().toggleTheme();
                    },
                  ),
                ],
              ),
              // Tab content switching
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildHomeTab(),
                    _buildServicesTab(),
                    _buildProfileTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      // Bottom navigation bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: theme.colorScheme.onSurface),
            selectedIcon: Icon(Icons.home, color: theme.colorScheme.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.cases_outlined, color: theme.colorScheme.onSurface),
            selectedIcon: Icon(Icons.cases, color: theme.colorScheme.primary),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: theme.colorScheme.onSurface),
            selectedIcon: Icon(Icons.person, color: theme.colorScheme.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Builds the Home tab layout
  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildQuickActionsSection(),
        const SizedBox(height: 24),
        SizedBox(height: 350, child: _buildRecentActivitiesSection()),
        const SizedBox(height: 24),
        _buildStatsSection(),
      ],
    );
  }

  /// Quick actions like Summarize, Draft etc.
  Widget _buildQuickActionsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Actions", style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                "Summarize Case", Icons.description, theme.colorScheme.primary, () {
                  _navigateToChat("Summarize Case", true, 'https://72bb-34-53-3-19.ngrok-free.app', 'summary', 'question');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                "Draft Contract", Icons.edit_document, Color(0xFF70D6FF), () {
                  _navigateToChat("Draft Contract", true, 'https://1e9f-34-13-253-50.ngrok-free.app/', 'generate/', 'prompt', filetype: 'x-www-form-urlencoded');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard("QnA", Icons.category, Color(0xFFFF70A6), () {
                _navigateToChat("QnA", true, 'https://72bb-34-53-3-19.ngrok-free.app', 'chat', 'question');
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard("Clause Classification", Icons.edit_document, Colors.orange, () {
                _navigateToChat("Clause Classification", true, 'https://8fa3-14-139-239-178.ngrok-free.app', 'generate/', 'prompt');
              }),
            ),
          ],
        ),
      ],
    );
  }

  /// Card widget used in Quick Actions
  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 124,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 12),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Recent activity list
  Widget _buildRecentActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 300,
          child: recentActivities.isNotEmpty
              ? ListView.builder(
                  itemCount: recentActivities.length,
                  itemBuilder: (context, index) {
                    final activity = recentActivities[index];
                    return _buildActivityCard(
                      activity['title'] as String,
                      activity['description'] as String,
                      _getTimeAgo(DateTime.parse(activity['time'] as String)),
                      Icons.description_outlined,
                      index,
                    );
                  },
                )
              : const Center(child: Text("No recent activities yet.")),
        ),
      ],
    );
  }

  /// Helper to format time like "3 hours ago"
  String _getTimeAgo(DateTime time) {
    final Duration difference = DateTime.now().difference(time);
    if (difference.inSeconds < 60) return '${difference.inSeconds} seconds ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${difference.inDays ~/ 7} weeks ago';
  }

  /// Widget to render each recent activity card
  Widget _buildActivityCard(String type, String title, String time, IconData icon, int index) {
    final theme = Theme.of(context);
    final Color cardColor = Color.lerp(theme.colorScheme.primary, Colors.grey[300]!, index * 0.3)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cardColor.withOpacity(0.1),
          child: Icon(icon, color: cardColor),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(type),
        trailing: Text(time, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
      ),
    );
  }

  /// Stats for user like number of cases handled
  Widget _buildStatsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Your Stats", style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard("Cases", "28", Icons.cases_outlined, theme.colorScheme.primary)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard("Contracts", "15", Icons.description_outlined, theme.colorScheme.secondary)),
          ],
        ),
      ],
    );
  }

  /// Widget for stat cards
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  /// Services tab content
  Widget _buildServicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildServiceCard("Case Summarization", "Generate concise summaries from case details", Icons.description, Colors.yellow),
        _buildServiceCard("Clause Classification", "Classify the clauses on the basis of case scenario.", Icons.edit_document, Colors.green),
        _buildServiceCard("QnA", "Solve doubts regarding the case.", Icons.category, Colors.orange),
        _buildServiceCard("Draft Contract", "Creates a contract for your legal matters.", Icons.category, Color(0xFF70D6FF)),
      ],
    );
  }

  /// Reusable card for service options
  Widget _buildServiceCard(String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _navigateToChat(title, true, 'url', 'directory', 'question');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  /// Profile tab content with menu items
  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(child: CircleAvatar(radius: 50, backgroundImage: AssetImage('assets/images/avatar.jpg'))),
        const SizedBox(height: 16),
        const Center(child: Text("John Doe", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
        const Center(child: Text("Legal Professional", style: TextStyle(color: Colors.grey))),
        const SizedBox(height: 32),
        _buildProfileMenuItem("My Documents", Icons.folder_outlined),
        _buildProfileMenuItem("Settings", Icons.settings_outlined),
        _buildProfileMenuItem("Help & Support", Icons.help_outline),
        _buildProfileMenuItem("About", Icons.info_outline),
      ],
    );
  }

  /// Reusable profile menu tile
  Widget _buildProfileMenuItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Handle menu tap
      },
    );
  }
}
