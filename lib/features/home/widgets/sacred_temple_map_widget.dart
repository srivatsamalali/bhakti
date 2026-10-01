import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../pooja/garbhagruha/garbhagruha_scene.dart';
import '../../pooja/garbhagruha/venkateshwara_scene.dart';
import '../../pooja/garbhagruha/ganesha_scene.dart';
import '../../pooja/garbhagruha/chamundeshwari_scene.dart';
import '../../pooja/garbhagruha/lakshmi_scene.dart';
import '../../pooja/garbhagruha/sanctum_registry.dart';
import '../../pooja/virtual_pooja_room_screen.dart';
import '../../../widgets/sacred_filigree_border.dart';

/// Interactive Real 3D Terrain Map & Pilgrimage Yatra Section on Home Screen
class SacredTempleMapWidget extends StatefulWidget {
  const SacredTempleMapWidget({super.key});

  @override
  State<SacredTempleMapWidget> createState() => _SacredTempleMapWidgetState();
}

class _SacredTempleMapWidgetState extends State<SacredTempleMapWidget>
    with SingleTickerProviderStateMixin {
  int _selectedSiteIndex = 0;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToTemple(int index) {
    HapticFeedback.heavyImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VirtualPoojaRoomScreen(
          initialDeityIndex: index,
          startWithAerialDescent: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedSite = allSanctumEnvironments[_selectedSiteIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A1007),
              Color(0xFF160603),
              Color(0xFF33140A),
            ],
          ),
          border: Border.all(
            color: AppColors.goldPrimary.withOpacity(0.55),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE65100).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Ornate Corner Filigree
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: CustomPaint(
                  painter: SacredCornerFiligreePainter(
                    filigreeColor: AppColors.goldPrimary.withOpacity(0.65),
                    cornerSize: 22,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Sacred Title & Yatra Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFFFD54F),
                                  Color(0xFFE65100),
                                  Color(0xFF4E160A),
                                ],
                              ),
                              border: Border.all(color: AppColors.goldLight, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.goldPrimary.withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.public_rounded,
                              color: Color(0xFFFFF9C4),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'ಪುಣ್ಯಕ್ಷೇತ್ರ ದರ್ಶನ',
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.goldLight,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.goldPrimary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.goldPrimary.withOpacity(0.5),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Text(
                                      '3D TERRAIN YATRA',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: AppColors.goldLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Realistic Satellite Map • Sky Entry & Garbhagruha Pooja',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _navigateToTemple(_selectedSiteIndex),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldPrimary.withOpacity(0.2),
                            border: Border.all(color: AppColors.goldLight.withOpacity(0.6)),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.goldLight,
                            size: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Real 3D Topographical Satellite Terrain Map of South India
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final mapWidth = constraints.maxWidth;
                      const mapHeight = 220.0;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: mapHeight,
                          width: mapWidth,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.goldLight.withOpacity(0.7),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. High-Resolution 3D Satellite Terrain Image
                              Image.asset(
                                'assets/images/pooja/south_india_terrain_map.jpg',
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, -0.1),
                              ),

                              // 2. Subtle Vignette & Terrain Depth Gradient
                              Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 1.1,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.4),
                                      Colors.black.withOpacity(0.7),
                                    ],
                                    stops: const [0.4, 0.8, 1.0],
                                  ),
                                ),
                              ),

                              // 3. Animated Golden Pilgrimage Yatra Flight Path Lines
                              CustomPaint(
                                size: Size(mapWidth, mapHeight),
                                painter: RealisticTerrainYatraRoutePainter(
                                  sites: allSanctumEnvironments,
                                  selectedIndex: _selectedSiteIndex,
                                  pulse: _pulseController.value,
                                ),
                              ),

                              // 4. Interactive 3D Beacon Pins on the Real Terrain Map
                              ...List.generate(allSanctumEnvironments.length, (index) {
                                final site = allSanctumEnvironments[index];
                                final isSelected = index == _selectedSiteIndex;

                                final pinX = site.mapPosition.dx * mapWidth - (isSelected ? 48 : 40);
                                final pinY = site.mapPosition.dy * mapHeight - (isSelected ? 36 : 30);

                                return Positioned(
                                  left: pinX.clamp(4.0, mapWidth - 110.0),
                                  top: pinY.clamp(6.0, mapHeight - 46.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedSiteIndex = index;
                                      });
                                    },
                                    child: AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, _) {
                                        final pulseScale = isSelected
                                            ? 1.0 + (_pulseController.value * 0.14)
                                            : 1.0;
                                        return Transform.scale(
                                          scale: pulseScale,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Beacon Glow Ring + Label
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(14),
                                                  gradient: LinearGradient(
                                                    colors: isSelected
                                                        ? [
                                                            const Color(0xFFFFD54F),
                                                            site.primaryColor,
                                                          ]
                                                        : [
                                                            const Color(0xEE1E0803),
                                                            const Color(0xEE120401),
                                                          ],
                                                  ),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : AppColors.goldLight.withOpacity(0.7),
                                                    width: isSelected ? 2.0 : 1.2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: isSelected
                                                          ? site.primaryColor.withOpacity(0.9)
                                                          : Colors.black.withOpacity(0.6),
                                                      blurRadius: isSelected ? 16 : 6,
                                                      spreadRadius: isSelected ? 3 : 0,
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      site.symbol,
                                                      style: TextStyle(
                                                        fontSize: isSelected ? 12 : 10,
                                                        color: isSelected
                                                            ? Colors.black
                                                            : AppColors.goldLight,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      site.locationName.split(',').first,
                                                      style: TextStyle(
                                                        fontSize: isSelected ? 11 : 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isSelected
                                                            ? Colors.black
                                                            : Colors.white,
                                                        shadows: isSelected
                                                            ? []
                                                            : const [
                                                                Shadow(
                                                                  color: Colors.black,
                                                                  blurRadius: 4,
                                                                ),
                                                              ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Golden Pin Point
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isSelected
                                                      ? AppColors.goldLight
                                                      : Colors.white,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.goldPrimary.withOpacity(0.8),
                                                      blurRadius: 6,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }),

                              // Map Corner Badge: "3D REAL SATELLITE TERRAIN"
                              Positioned(
                                bottom: 8,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.goldLight.withOpacity(0.5)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.terrain_rounded, color: AppColors.goldLight, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'DECCAN & GHATS TERRAIN',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.goldLight,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Selected Temple Aerial Preview Card with Direct Flight Entry Button
                  GestureDetector(
                    onTap: () => _navigateToTemple(_selectedSiteIndex),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            selectedSite.gradientColors[0].withOpacity(0.9),
                            const Color(0xFF140704),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.goldLight.withOpacity(0.7),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: selectedSite.primaryColor.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Aerial Drone Photo Thumbnail
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(17),
                                  bottomLeft: Radius.circular(17),
                                ),
                                child: Image.asset(
                                  selectedSite.aerialImagePath,
                                  width: 125,
                                  height: 88,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.goldLight, width: 0.8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.flight_takeoff_rounded, color: AppColors.goldLight, size: 10),
                                      SizedBox(width: 3),
                                      Text(
                                        'AERIAL VIEW',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.goldLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 12),

                          // Temple Details & Flight Action
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        selectedSite.kannadaName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.goldLight,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '• ${selectedSite.stateName}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedSite.sanctumName,
                                    style: const TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.play_circle_fill_rounded,
                                        color: AppColors.goldLight,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Fly In & Enter Garbhagruha',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.goldLight.withOpacity(0.95),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Action Arrow
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.goldPrimary.withOpacity(0.3),
                                border: Border.all(color: AppColors.goldLight, width: 1.2),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.goldLight,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Horizontal 4 Sacred Pilgrimage Selectors Pills
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allSanctumEnvironments.length,
                      itemBuilder: (context, index) {
                        final site = allSanctumEnvironments[index];
                        final isSelected = index == _selectedSiteIndex;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedSiteIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [site.primaryColor, site.gradientColors[1]]
                                    : [const Color(0xFF240D06), const Color(0xFF160603)],
                              ),
                              border: Border.all(
                                color: isSelected ? AppColors.goldLight : const Color(0x44C8A050),
                                width: isSelected ? 1.5 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(site.symbol, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 6),
                                Text(
                                  site.locationName.split(',').first,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Canvas Painter for Connecting Pilgrimage Routes across the Real Terrain Map
class RealisticTerrainYatraRoutePainter extends CustomPainter {
  final List<GarbhagruhaEnvironment> sites;
  final int selectedIndex;
  final double pulse;

  RealisticTerrainYatraRoutePainter({
    required this.sites,
    required this.selectedIndex,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.35 + (pulse * 0.25))
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final selectedSite = sites[selectedIndex];
    final centerOffset = Offset(
      selectedSite.mapPosition.dx * size.width,
      selectedSite.mapPosition.dy * size.height,
    );

    // Radiating beacon rings from the selected temple
    final beaconPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.4 * (1.0 - pulse))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(centerOffset, 12 + (pulse * 24), beaconPaint);

    // Connecting golden flight trajectory curves
    for (int i = 0; i < sites.length; i++) {
      if (i == selectedIndex) continue;
      final target = Offset(
        sites[i].mapPosition.dx * size.width,
        sites[i].mapPosition.dy * size.height,
      );

      final path = Path();
      path.moveTo(centerOffset.dx, centerOffset.dy);
      path.quadraticBezierTo(
        (centerOffset.dx + target.dx) / 2,
        (centerOffset.dy + target.dy) / 2 - 15,
        target.dx,
        target.dy,
      );
      canvas.drawPath(path, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant RealisticTerrainYatraRoutePainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.pulse != pulse;
}
