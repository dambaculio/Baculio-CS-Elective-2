import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

void main() {
  runApp(const ResponsiveAdaptiveApp());
}

class ResponsiveAdaptiveApp extends StatelessWidget {
  const ResponsiveAdaptiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Responsive & Adaptive Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[300],
      ),
      home: const ResponsiveDashboard(),
    );
  }
}

class ResponsiveDashboard extends StatelessWidget {
  const ResponsiveDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 900;

        // Dynamically assign target platform mode based on inspect screen width
        // Mobile (< 600px)     -> iOS (Cupertino UI)
        // Tablet (600-899px)   -> Android (Material UI)
        // Desktop (>= 900px)   -> Web / Desktop UI
        final TargetPlatform activePlatform = width < 600
            ? TargetPlatform.iOS
            : (width < 900 ? TargetPlatform.android : TargetPlatform.macOS);

        return Theme(
          data: Theme.of(context).copyWith(platform: activePlatform),
          child: Scaffold(
            backgroundColor: Colors.grey[300],
            // Top App Bar adapts between iOS Cupertino bar, Android AppBar, and Desktop Bar
            appBar: AdaptiveAppBar(
              showHamburger: !isDesktop,
              platform: activePlatform,
            ),
            // Slide-out drawer menu for Mobile and Tablet
            drawer: isDesktop ? null : AppDrawer(platform: activePlatform),
            body: _buildResponsiveBody(width, activePlatform),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveBody(double width, TargetPlatform platform) {
    // 1. MOBILE LAYOUT (< 600px): iOS Theme, 2x2 Grid, White Cupertino Cards
    if (width < 600) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                children: List.generate(4, (_) => const BoxTile()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(), // Native iOS bounce
                itemCount: 5,
                itemBuilder: (context, index) =>
                    TileCard(platform: platform, index: index),
              ),
            ),
          ],
        ),
      );
    }

    // 2. TABLET LAYOUT (600px - 899px): Android Theme, 1x4 Row Grid, Material Cards
    if (width < 900) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 4,
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                children: List.generate(4, (_) => const BoxTile()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) =>
                    TileCard(platform: platform, index: index),
              ),
            ),
          ],
        ),
      );
    }

    // 3. DESKTOP LAYOUT (>= 900px): Web Theme, Permanent Sidebar, Feature Box
    return Row(
      children: [
        SizedBox(
          width: 240,
          child: AppDrawer(platform: platform),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 4,
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    children: List.generate(4, (_) => const BoxTile()),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) =>
                        TileCard(platform: platform, index: index),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ADAPTIVE APP BAR: Switches visual designs automatically during window inspection
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showHamburger;
  final TargetPlatform platform;

  const AdaptiveAppBar({
    super.key,
    required this.showHamburger,
    required this.platform,
  });

  @override
  Widget build(BuildContext context) {
    // iOS Cupertino Navigation Bar (< 600px)
    if (platform == TargetPlatform.iOS) {
      return CupertinoNavigationBar(
        backgroundColor: Colors.grey[900],
        border: null,
        leading: showHamburger
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.bars,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              )
            : null,
        middle: const Text(
          'iOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      );
    }

    // Android Material AppBar (600px - 899px)
    if (platform == TargetPlatform.android) {
      return AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 4,
        automaticallyImplyLeading: showHamburger,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Android',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      );
    }

    // Web / Desktop Navigation Bar (>= 900px)
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Row(
        children: [
          Icon(Icons.web, color: Colors.blueAccent, size: 20),
          SizedBox(width: 8),
          Text(
            'Web/Desktop',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// SIDEBAR / DRAWER MENU
class AppDrawer extends StatelessWidget {
  final TargetPlatform platform;

  const AppDrawer({super.key, required this.platform});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[300],
      elevation: 0,
      child: Column(
        children: [
          const DrawerHeader(
            child: Icon(
              Icons.favorite,
              size: 48,
              color: Colors.black,
            ),
          ),
          _buildMenuItem(Icons.home, 'D A S H B O A R D'),
          _buildMenuItem(Icons.settings, 'S E T T I N G S'),
          _buildMenuItem(Icons.info_outline, 'A B O U T'),
          _buildMenuItem(Icons.logout, 'L O G O U T'),
          const Spacer(),
          // Adaptive badge indicator inside drawer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Platform: ${platform.name.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.black,
        ),
      ),
      onTap: () {},
    );
  }
}

// DARK GREY SQUARE CARD
class BoxTile extends StatelessWidget {
  const BoxTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}

// WHITE HORIZONTAL LIST CARD WITH VISIBLE ADAPTIVE DESIGNS
class TileCard extends StatelessWidget {
  final TargetPlatform platform;
  final int index;

  const TileCard({
    super.key,
    required this.platform,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // 1. iOS Design: Rounded Cupertino style with Cupertino Switch
    if (platform == TargetPlatform.iOS) {
      return Container(
        height: 70,
        margin: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 6.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0), // iOS rounded card styling
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.device_phone_portrait,
              color: Colors.blue,
            ),
            const SizedBox(width: 12),
            const Spacer(),
            CupertinoSwitch(
              value: true,
              onChanged: (val) {},
            ),
          ],
        ),
      );
    }

    // 2. Android Design: Material card with elevation and Material Switch
    if (platform == TargetPlatform.android) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(
          vertical: 4.0,
          horizontal: 6.0,
        ),
        color: Colors.white,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Icon(
                Icons.android,
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              const Spacer(),
              Switch(
                value: true,
                activeColor: Colors.green,
                onChanged: (val) {},
              ),
            ],
          ),
        ),
      );
    }

    // 3. Web / Desktop Design: Sharp desktop card with mouse cursor hover state
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 6.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: InkWell(
        onTap: () {},
        hoverColor: Colors.blue.withOpacity(0.05), // Mouse hover feedback for web
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Icon(
                Icons.desktop_windows,
                color: Colors.purple,
              ),
              const SizedBox(width: 12),
              const Spacer(),
              OutlinedButton(
                onPressed: () {},
                child: const Text(
                  'Action',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}