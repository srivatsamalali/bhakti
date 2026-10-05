import 'dart:io';
import 'dart:math' as math;
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/preferences/preferences_service.dart';
import '../../widgets/liquid_glass/glass_style.dart';
import '../../widgets/liquid_glass/liquid_glass.dart';
import '../../widgets/sacred_filigree_border.dart';
import 'garbhagruha/garbhagruha_scene.dart';
import 'garbhagruha/sanctum_registry.dart';

/// Petal data structure for Pushparchana
class FlowerPetal {
  double x;
  double y;
  double speedY;
  double speedX;
  double rotation;
  double rotationSpeed;
  double size;
  Color color;
  double opacity;

  FlowerPetal({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.opacity,
  });
}

/// Smoke Particle for Agarbatti / Dhoopa
class SmokeParticle {
  double x;
  double y;
  double radius;
  double opacity;
  double speedY;
  double sway;
  double age;

  SmokeParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.speedY,
    required this.sway,
    this.age = 0.0,
  });
}

class VirtualPoojaRoomScreen extends StatefulWidget {
  final int initialDeityIndex;
  final bool startWithAerialDescent;

  const VirtualPoojaRoomScreen({
    super.key,
    this.initialDeityIndex = 0, // Default to Lord Venkateshwara
    this.startWithAerialDescent = true,
  });

  @override
  State<VirtualPoojaRoomScreen> createState() => _VirtualPoojaRoomScreenState();
}

class _VirtualPoojaRoomScreenState extends State<VirtualPoojaRoomScreen>
    with TickerProviderStateMixin {
  late int _selectedDeityIndex;
  late final PageController _deityPageController;

  // Aerial Fly-In State
  bool _isAerialFlying = false;
  late final AnimationController _aerialFlyController;

  // Ritual States
  bool _leftDiyaLit = true;
  bool _rightDiyaLit = true;
  bool _isBellRinging = false;
  bool _isFlowerShowering = false;
  bool _isAartiActive = false;
  bool _isDhoopaActive = true;
  int _poojaCount = 0;

  // Animation Controllers
  late final AnimationController _cameraPushInController;
  late final AnimationController _flameFlickerController;
  late final AnimationController _bellSwingController;
  late final AnimationController _flowerPhysicsController;
  late final AnimationController _aartiOrbitController;
  late final AnimationController _dhoopaController;
  late final AnimationController _haloGlowController;
  late final AnimationController _particlesController;

  final List<FlowerPetal> _petals = [];
  final List<SmokeParticle> _smokeParticles = [];
  final List<SanctumLightParticle> _lightParticles = [];
  final math.Random _random = math.Random();

  // Audio Players for Sacred Effects & Ambience
  late final AudioPlayer _bellPlayer;
  late final AudioPlayer _bgOmPlayer;
  late final AudioPlayer _aartiPlayer;
  late final AudioPlayer _flowerPlayer;
  bool _isOmPlaying = true;

  @override
  void initState() {
    super.initState();
    _selectedDeityIndex = widget.initialDeityIndex.clamp(0, allSanctumEnvironments.length - 1);
    _isAerialFlying = widget.startWithAerialDescent;

    _deityPageController = PageController(
      viewportFraction: 0.84,
      initialPage: _selectedDeityIndex,
    );

    // Initialize Aerial Flight Drone Controller (5.2s continuous camera dive)
    _aerialFlyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );

    if (_isAerialFlying) {
      _startAerialDescent();
    }

    // Initialize Audio Players
    _bellPlayer = AudioPlayer();
    _bgOmPlayer = AudioPlayer();
    _aartiPlayer = AudioPlayer();
    _flowerPlayer = AudioPlayer();
    _initAudio();

    // Cinematic Camera Push-In Controller: smoothly glides in and STOPS at final darshan view
    _cameraPushInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (!_isAerialFlying) {
      _cameraPushInController.forward();
    }

    // Flame flicker controller
    _flameFlickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    // Bell swing controller
    _bellSwingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Flower physics ticker
    _flowerPhysicsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 40),
    )..addListener(_updateFlowers);

    // Aarti orbit controller (Mangalarathi circular motion)
    _aartiOrbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Dhoopa smoke controller
    _dhoopaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    )..addListener(_updateSmoke);
    _dhoopaController.repeat();

    // Halo glow controller
    _haloGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Sanctum Light Particles ticker
    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateLightParticles);
    _particlesController.repeat();
    _initLightParticles();

    _loadPoojaProgress();
  }

  void _startAerialDescent() {
    setState(() {
      _isAerialFlying = true;
    });
    _aerialFlyController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isAerialFlying = false;
        });
        _cameraPushInController.forward(from: 0.0);
        _triggerBellRing();
      }
    });
  }

  void _skipAerialDescent() {
    _aerialFlyController.stop();
    setState(() {
      _isAerialFlying = false;
    });
    _cameraPushInController.forward(from: 0.0);
  }

  void _initLightParticles() {
    _lightParticles.clear();
    for (int i = 0; i < 35; i++) {
      _lightParticles.add(
        SanctumLightParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          speedY: 0.0006 + (_random.nextDouble() * 0.0012),
          speedX: (_random.nextDouble() - 0.5) * 0.0008,
          size: 1.2 + _random.nextDouble() * 2.4,
          opacity: 0.15 + _random.nextDouble() * 0.55,
          pulseSpeed: 1.5 + _random.nextDouble() * 2.0,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _updateLightParticles() {
    setState(() {
      for (final p in _lightParticles) {
        p.y -= p.speedY;
        p.x += p.speedX;
        p.phase += 0.04;
        if (p.y < 0.0) {
          p.y = 1.0;
          p.x = _random.nextDouble();
        }
        if (p.x < 0.0) p.x = 1.0;
        if (p.x > 1.0) p.x = 0.0;
      }
    });
  }

  Future<String> _extractAssetToTemp(String assetKey) async {
    try {
      final byteData = await rootBundle.load(assetKey);
      final buffer = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      final tempDir = await getTemporaryDirectory();
      final fileName = assetKey.split('/').last;
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(buffer, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Error extracting $assetKey: $e');
      return '';
    }
  }

  Future<void> _initAudio() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      try {
        await _bellPlayer.setAsset('assets/audio/pooja/temple_bell.wav');
      } catch (_) {
        final bellPath = await _extractAssetToTemp('assets/audio/pooja/temple_bell.wav');
        if (bellPath.isNotEmpty) await _bellPlayer.setFilePath(bellPath);
      }

      try {
        await _flowerPlayer.setAsset('assets/audio/pooja/flower_shower.wav');
      } catch (_) {
        final flowerPath = await _extractAssetToTemp('assets/audio/pooja/flower_shower.wav');
        if (flowerPath.isNotEmpty) await _flowerPlayer.setFilePath(flowerPath);
      }

      try {
        await _aartiPlayer.setAsset('assets/audio/pooja/aarti_chime.wav');
      } catch (_) {
        final aartiPath = await _extractAssetToTemp('assets/audio/pooja/aarti_chime.wav');
        if (aartiPath.isNotEmpty) await _aartiPlayer.setFilePath(aartiPath);
      }

      try {
        await _bgOmPlayer.setAsset('assets/audio/pooja/sacred_om_drone.wav');
      } catch (_) {
        final omPath = await _extractAssetToTemp('assets/audio/pooja/sacred_om_drone.wav');
        if (omPath.isNotEmpty) await _bgOmPlayer.setFilePath(omPath);
      }

      await _bellPlayer.setVolume(1.0);
      await _flowerPlayer.setVolume(0.85);
      await _aartiPlayer.setVolume(0.9);
      await _bgOmPlayer.setLoopMode(LoopMode.all);
      await _bgOmPlayer.setVolume(0.65);
      if (_isOmPlaying) {
        await _bgOmPlayer.play();
      }
      debugPrint('🕉️ Pooja Audio & AudioSession initialized successfully');
    } catch (e) {
      debugPrint('ℹ️ Pooja audio init fallback: $e');
    }
  }

  void _toggleOmAudio() {
    HapticFeedback.selectionClick();
    setState(() {
      _isOmPlaying = !_isOmPlaying;
    });
    if (_isOmPlaying) {
      _bgOmPlayer.play();
    } else {
      _bgOmPlayer.pause();
    }
  }

  Future<void> _loadPoojaProgress() async {
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final count = prefs.getInt('bhakti_pooja_count_$todayStr') ?? 0;
    if (mounted) {
      setState(() {
        _poojaCount = count;
      });
    }
  }

  Future<void> _incrementPoojaCount() async {
    final prefs = Provider.of<PreferencesService>(context, listen: false);
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final newCount = _poojaCount + 1;
    await prefs.setInt('bhakti_pooja_count_$todayStr', newCount);
    if (mounted) {
      setState(() {
        _poojaCount = newCount;
      });
    }
  }

  @override
  void dispose() {
    _aerialFlyController.dispose();
    _cameraPushInController.dispose();
    _deityPageController.dispose();
    _flameFlickerController.dispose();
    _bellSwingController.dispose();
    _flowerPhysicsController.dispose();
    _aartiOrbitController.dispose();
    _dhoopaController.dispose();
    _haloGlowController.dispose();
    _particlesController.dispose();
    _bellPlayer.dispose();
    _flowerPlayer.dispose();
    _bgOmPlayer.dispose();
    _aartiPlayer.dispose();
    super.dispose();
  }

  // --- Select Deity ---
  void _selectDeity(int index) {
    if (index == _selectedDeityIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDeityIndex = index;
    });

    if (_deityPageController.hasClients) {
      _deityPageController.jumpToPage(index);
    }

    // Launch Continuous Aerial Flight into the newly selected temple
    _startAerialDescent();
  }

  void _showDeitySelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF190703),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: Color(0x66C8A050), width: 1.5),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Sacred Temple (ಕ್ಷೇತ್ರ ದರ್ಶನ)',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldLight,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: allSanctumEnvironments.length,
                  itemBuilder: (context, index) {
                    final deity = allSanctumEnvironments[index];
                    final isSelected = index == _selectedDeityIndex;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _selectDeity(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: isSelected
                                ? [const Color(0xFF8B2500), const Color(0xFFD97706)]
                                : [const Color(0xFF2C1008), const Color(0xFF1C0A05)],
                          ),
                          border: Border.all(
                            color: isSelected ? AppColors.goldLight : const Color(0x44C8A050),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.goldLight, width: 1.2),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  deity.imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    deity.deityName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    deity.kannadaName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.goldLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerBellRing() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isBellRinging = true;
    });

    // Animate bell swing immediately
    _bellSwingController.forward(from: 0.0).then((_) {
      _bellSwingController.reverse().then((_) {
        if (mounted) {
          setState(() => _isBellRinging = false);
        }
      });
    });
    _incrementPoojaCount();

    // Play sacred temple bell chime with speaker audio session
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);

      if (_bellPlayer.audioSource == null) {
        await _bellPlayer.setAsset('assets/audio/pooja/temple_bell.wav');
      } else {
        await _bellPlayer.seek(Duration.zero);
      }
      await _bellPlayer.setVolume(1.0);
      await _bellPlayer.play();
    } catch (e) {
      debugPrint('Bell playback primary error: $e');
      try {
        final fallbackPlayer = AudioPlayer();
        await fallbackPlayer.setAsset('assets/audio/pooja/temple_bell.wav');
        await fallbackPlayer.setVolume(1.0);
        await fallbackPlayer.play();
      } catch (err) {
        debugPrint('Bell fallback player error: $err');
      }
    }
  }

  void _toggleDiya(bool isLeft) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (isLeft) {
        _leftDiyaLit = !_leftDiyaLit;
      } else {
        _rightDiyaLit = !_rightDiyaLit;
      }
    });
    if (_leftDiyaLit || _rightDiyaLit) {
      _incrementPoojaCount();
    }
  }

  void _triggerFlowerShower() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFlowerShowering = true;
    });
    try {
      _flowerPlayer.seek(Duration.zero);
      _flowerPlayer.setVolume(0.85);
      _flowerPlayer.play();
    } catch (_) {}

    final currentEnv = allSanctumEnvironments[_selectedDeityIndex];
    final colors = currentEnv.garlandColors;

    for (int i = 0; i < 50; i++) {
      _petals.add(
        FlowerPetal(
          x: _random.nextDouble(),
          y: -0.1 - (_random.nextDouble() * 0.4),
          speedY: 0.007 + (_random.nextDouble() * 0.010),
          speedX: (_random.nextDouble() - 0.5) * 0.004,
          rotation: _random.nextDouble() * 2 * math.pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.12,
          size: 14 + (_random.nextDouble() * 14),
          color: colors[_random.nextInt(colors.length)],
          opacity: 0.95,
        ),
      );
    }

    if (!_flowerPhysicsController.isAnimating) {
      _flowerPhysicsController.repeat();
    }
    _incrementPoojaCount();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isFlowerShowering = false;
        });
      }
    });
  }

  void _updateFlowers() {
    if (_petals.isEmpty) {
      _flowerPhysicsController.stop();
      return;
    }

    setState(() {
      for (int i = _petals.length - 1; i >= 0; i--) {
        final p = _petals[i];
        p.y += p.speedY;
        p.x += p.speedX + (math.sin(p.y * 10) * 0.001);
        p.rotation += p.rotationSpeed;

        // Ground accumulation fade
        if (p.y > 0.82) {
          p.opacity -= 0.015;
          p.speedY *= 0.5;
        }

        if (p.y > 0.98 || p.opacity <= 0.0) {
          _petals.removeAt(i);
        }
      }
    });
  }

  void _toggleAarti() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAartiActive = !_isAartiActive;
    });

    if (_isAartiActive) {
      _aartiOrbitController.repeat();
      try {
        _aartiPlayer.seek(Duration.zero);
        _aartiPlayer.setLoopMode(LoopMode.all);
        _aartiPlayer.setVolume(0.85);
        _aartiPlayer.play();
      } catch (_) {}
      _incrementPoojaCount();
    } else {
      _aartiOrbitController.stop();
      try {
        _aartiPlayer.stop();
      } catch (_) {}
    }
  }

  void _toggleDhoopa() {
    HapticFeedback.selectionClick();
    setState(() {
      _isDhoopaActive = !_isDhoopaActive;
    });
  }

  void _updateSmoke() {
    if (!_isDhoopaActive) {
      if (_smokeParticles.isNotEmpty) {
        setState(() {
          _smokeParticles.clear();
        });
      }
      return;
    }

    // Spawn new smoke particles from left and right incense holders
    if (_random.nextDouble() < 0.38) {
      _smokeParticles.add(
        SmokeParticle(
          x: 0.16 + (_random.nextDouble() * 0.03),
          y: 0.74,
          radius: 3.5 + _random.nextDouble() * 3,
          opacity: 0.45,
          speedY: 0.004 + _random.nextDouble() * 0.003,
          sway: (_random.nextDouble() - 0.5) * 0.003,
        ),
      );
      _smokeParticles.add(
        SmokeParticle(
          x: 0.81 + (_random.nextDouble() * 0.03),
          y: 0.74,
          radius: 3.5 + _random.nextDouble() * 3,
          opacity: 0.45,
          speedY: 0.004 + _random.nextDouble() * 0.003,
          sway: (_random.nextDouble() - 0.5) * 0.003,
        ),
      );
    }

    setState(() {
      for (int i = _smokeParticles.length - 1; i >= 0; i--) {
        final s = _smokeParticles[i];
        s.y -= s.speedY;
        s.x += s.sway + (math.sin(s.age * 5) * 0.001);
        s.radius += 0.25;
        s.opacity -= 0.008;
        s.age += 0.05;

        if (s.opacity <= 0.0 || s.y < 0.15) {
          _smokeParticles.removeAt(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentEnv = allSanctumEnvironments[_selectedDeityIndex];
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0403),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Temple Sanctum Background & Ambient Lighting
          _buildTempleSanctumBackground(currentEnv),

          // 2. Sanctum Dust / Golden Prakash Particles
          CustomPaint(
            size: Size.infinite,
            painter: SanctumLightParticlesPainter(_lightParticles),
          ),

          // 3. Main Sanctum Perspectives & Sacred Altar
          SafeArea(
            child: Column(
              children: [
                // Top Temple Bar & Ritual Counters
                _buildTopSacredBar(currentEnv),

                // Quick Deity Selection Pills Row
                _buildDeitySelectorBar(),

                // Main Sanctum Stage (Hanging Bell, Deity Photo Altar, Dual Diyas, Aarti Orbit)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sacred Aura Rays & Halo behind Deity
                      _buildSacredHalo(currentEnv),

                      // Deity Garbhagruha Cinematic View with Camera Push-In & Darshan Hold
                      _buildCinematicGarbhagruha(currentEnv, isDesktop),

                      // Incense Smoke Particles
                      if (_isDhoopaActive)
                        CustomPaint(
                          size: Size.infinite,
                          painter: SmokePainter(_smokeParticles),
                        ),

                      // Hanging Sacred Brass Bell (Top Center)
                      Positioned(
                        top: 0,
                        child: _buildHangingTempleBell(),
                      ),

                      // Left Brass Diya on Pillar
                      Positioned(
                        left: isDesktop ? size.width * 0.18 : 18,
                        bottom: isDesktop ? 35 : 20,
                        child: _buildBrassDiyaPillar(isLeft: true),
                      ),

                      // Right Brass Diya on Pillar
                      Positioned(
                        right: isDesktop ? size.width * 0.18 : 18,
                        bottom: isDesktop ? 35 : 20,
                        child: _buildBrassDiyaPillar(isLeft: false),
                      ),

                      // Mangalarathi Revolving Camphor Aarti & Flame Illumination
                      if (_isAartiActive)
                        _buildMangalarathiOrbit(currentEnv),

                      // Flower Petal Physics Shower
                      if (_petals.isNotEmpty)
                        CustomPaint(
                          size: Size.infinite,
                          painter: FlowerShowerPainter(_petals),
                        ),
                    ],
                  ),
                ),

                // Sacred Mantra Banner
                _buildSacredMantraBanner(currentEnv),

                // Interactive Ritual Action Console
                _buildRitualActionBar(currentEnv),
              ],
            ),
          ),

          // 4. Continuous Single-Take Aerial Drone Door Entry Overlay
          if (_isAerialFlying)
            _buildAerialDescentOverlay(currentEnv),
        ],
      ),
    );
  }

  // --- Continuous Single-Take Full-Shot Drone Entry via Temple Door ---

  Widget _buildAerialDescentOverlay(GarbhagruhaEnvironment deity) {
    return AnimatedBuilder(
      animation: _aerialFlyController,
      builder: (context, child) {
        final progress = _aerialFlyController.value;

        // Continuous Timeline Choreography:
        // t = 0.0 -> 0.42: High Altitude Mountain / Hills Sky Drone Dive (scale: 1.0 -> 2.4)
        // t = 0.35 -> 0.78: Approaching & Passing Through Carved Temple Door (scale: 0.7 -> 3.2)
        // t = 0.72 -> 1.00: Gliding into the Inner Sanctum directly to Deity's Darshan Halt

        final skyZoom = 1.0 + (progress * 1.4);

        // Door Layer scale & opacity smoothly blending in the continuous flight path
        final doorProgress = ((progress - 0.30) / 0.48).clamp(0.0, 1.0);
        final doorZoom = 0.75 + (doorProgress * 2.45); // 0.75 -> 3.20 diving straight through doorway

        // Sanctum & Deity Reveal through the open doorway
        final sanctumInDoorAlpha = (doorProgress * 2.2).clamp(0.0, 1.0);

        // Overlay fade-out at the very end when the camera is already inside the Garbhagruha
        double overlayAlpha = 1.0;
        if (progress > 0.90) {
          overlayAlpha = (1.0 - ((progress - 0.90) / 0.10)).clamp(0.0, 1.0);
        }

        return Opacity(
          opacity: overlayAlpha,
          child: Container(
            color: const Color(0xFF0A0403),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Sky Aerial Mountain Approach (Continuous Zoom)
                Transform.scale(
                  scale: skyZoom,
                  child: Image.asset(
                    deity.aerialImagePath,
                    fit: BoxFit.cover,
                  ),
                ),

                // 2. The Selected Deity positioned directly inside the open sanctum doorway
                if (progress >= 0.30)
                  Opacity(
                    opacity: sanctumInDoorAlpha,
                    child: Center(
                      child: Transform.scale(
                        scale: (0.55 + (doorProgress * 0.55)).clamp(0.55, 1.15),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              radius: 0.85,
                              colors: [
                                deity.accentColor.withOpacity(0.4),
                                const Color(0xFF140804).withOpacity(0.85),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                deity.imagePath,
                                fit: BoxFit.contain,
                                height: 320,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. Ground-Level Carved Temple Door with transparent center opening
                if (progress >= 0.30)
                  Opacity(
                    opacity: (doorProgress * 3.0).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: doorZoom,
                      child: Image.asset(
                        'assets/images/pooja/temple_door_frame.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // 4. Subtle Golden Vignette & Atmospheric Depth
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.1,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.25 * (1.0 - progress)),
                          Colors.black.withOpacity(0.6 * (1.0 - progress)),
                        ],
                      ),
                    ),
                  ),
                ),

                // 5. Continuous Single-Take HUD Banner
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Harmonized Header Bar (Back Button + Flight Status + Direct Darshan)
                        Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.55),
                                  border: Border.all(color: AppColors.goldPrimary.withOpacity(0.5)),
                                ),
                                child: const Icon(Icons.arrow_back, color: AppColors.goldLight, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),

                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.goldPrimary.withOpacity(0.7), width: 1.1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.goldPrimary.withOpacity(0.25),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.flight_land_rounded, color: AppColors.goldLight, size: 15),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        progress < 0.40
                                            ? 'SKY APPROACH • ${deity.locationName.toUpperCase()}'
                                            : (progress < 0.72
                                                ? 'ENTERING VIA CARVED DOORS'
                                                : 'ARRIVING IN GARBHAGRUHA'),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.goldLight,
                                          letterSpacing: 0.6,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Direct Darshan Skip Action
                            GestureDetector(
                              onTap: _skipAerialDescent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3E170A), Color(0xFF1E0904)],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: AppColors.goldPrimary.withOpacity(0.6)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.goldPrimary.withOpacity(0.2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Direct Darshan',
                                      style: TextStyle(
                                        color: AppColors.goldLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.fast_forward_rounded, color: AppColors.goldLight, size: 13),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Bottom Narrative & Temple Entering Banner matching Sanctum aesthetics
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF2A1007),
                                Color(0xFF160603),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.goldPrimary.withOpacity(0.65),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldPrimary.withOpacity(0.3),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    deity.symbol,
                                    style: const TextStyle(fontSize: 18, color: AppColors.goldLight),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    deity.sanctumName,
                                    style: const TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.goldLight,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                deity.aerialEntryNarrative,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.35,
                                ),
                              ),
                            ],
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
    );
  }

  // --- Quick Deity Selector Bar ---

  Widget _buildDeitySelectorBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allSanctumEnvironments.length,
        itemBuilder: (context, index) {
          final deity = allSanctumEnvironments[index];
          final isSelected = index == _selectedDeityIndex;

          return GestureDetector(
            onTap: () => _selectDeity(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: isSelected
                      ? [deity.primaryColor, deity.gradientColors[1]]
                      : [const Color(0xFF2C1008), const Color(0xFF1A0703)],
                ),
                border: Border.all(
                  color: isSelected ? AppColors.goldLight : const Color(0x44C8A050),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: deity.primaryColor.withOpacity(0.55),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.goldLight : AppColors.goldPrimary,
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        deity.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    deity.deityName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.goldLight : Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Background Sanctum ---

  Widget _buildTempleSanctumBackground(GarbhagruhaEnvironment deity) {
    return AnimatedBuilder(
      animation: _flameFlickerController,
      builder: (context, _) {
        final diyaGlow = (_leftDiyaLit ? 0.05 : 0.0) + (_rightDiyaLit ? 0.05 : 0.0);
        final flicker = (_flameFlickerController.value * 0.06) + diyaGlow;
        return CustomPaint(
          size: Size.infinite,
          painter: SanctumArchitecturalPainter(
            stoneColor: deity.sanctumStoneColor,
            ambientLight: deity.ambientGlowColor,
            flameIllumination: flicker,
            archwayStyle: deity.archwayStyle,
          ),
        );
      },
    );
  }

  // --- Top Temple Bar ---

  Widget _buildTopSacredBar(GarbhagruhaEnvironment deity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.4),
                border: Border.all(color: AppColors.goldPrimary.withOpacity(0.4)),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.goldLight, size: 18),
            ),
          ),
          const SizedBox(width: 8),

          // Temple Header Title & Symbol
          Expanded(
            child: GestureDetector(
              onTap: () => _showDeitySelectorModal(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          deity.symbol,
                          style: const TextStyle(fontSize: 16, color: AppColors.goldLight),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ದೇವತಾ ಮಂದಿರ • SANCTUM',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.goldLight,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.keyboard_arrow_down, color: AppColors.goldLight, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      deity.sanctumName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Action Buttons: Replay Aerial Sky Flight + OM Toggle + Daily Count
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Replay Aerial Drone Descent Flight
              GestureDetector(
                onTap: _startAerialDescent,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldPrimary.withOpacity(0.2),
                    border: Border.all(color: AppColors.goldLight.withOpacity(0.6), width: 1.0),
                  ),
                  child: const Icon(
                    Icons.flight_land_rounded,
                    color: AppColors.goldLight,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // OM Ambience Toggle
              GestureDetector(
                onTap: _toggleOmAudio,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _isOmPlaying
                        ? AppColors.goldPrimary.withOpacity(0.2)
                        : Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: _isOmPlaying ? AppColors.goldLight : Colors.white24,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ॐ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isOmPlaying ? AppColors.goldLight : Colors.white60,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        _isOmPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: _isOmPlaying ? AppColors.goldLight : Colors.white60,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Daily Pooja Count Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.maroonPrimary.withOpacity(0.8),
                      const Color(0xFF6B1710),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.goldPrimary.withOpacity(0.6), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wb_sunny_rounded, color: AppColors.goldLight, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '$_poojaCount',
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Sacred Halo Behind Deity ---

  Widget _buildSacredHalo(GarbhagruhaEnvironment deity) {
    return AnimatedBuilder(
      animation: _haloGlowController,
      builder: (context, _) {
        final pulse = 0.92 + (_haloGlowController.value * 0.20);
        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  deity.accentColor.withOpacity(0.5),
                  deity.primaryColor.withOpacity(0.25),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Cinematic Garbhagruha View (Camera Push-In & Darshan Hold) ---

  Widget _buildCinematicGarbhagruha(GarbhagruhaEnvironment deity, bool isDesktop) {
    return AnimatedBuilder(
      animation: _cameraPushInController,
      builder: (context, child) {
        // Camera smooth push-in curve from 0.94 -> 1.04, then STOPS and HOLDS
        final curvedProgress = Curves.easeOutCubic.transform(_cameraPushInController.value);
        final cameraScale = 0.94 + (curvedProgress * 0.10);
        final cameraTranslationY = (1.0 - curvedProgress) * 12.0;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(cameraScale)
            ..translate(0.0, cameraTranslationY),
          child: SizedBox(
            height: isDesktop ? 470 : 390,
            child: PageView.builder(
              controller: _deityPageController,
              itemCount: allSanctumEnvironments.length,
              onPageChanged: (index) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDeityIndex = index;
                });
                _cameraPushInController.forward(from: 0.0);
              },
              itemBuilder: (context, index) {
                final currentDeity = allSanctumEnvironments[index];
                final isSelected = index == _selectedDeityIndex;

                return AnimatedScale(
                  scale: isSelected ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _buildDeityAltarCard(currentDeity, isSelected, isDesktop),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeityAltarCard(GarbhagruhaEnvironment deity, bool isSelected, bool isDesktop) {
    return Center(
      child: Container(
        width: isDesktop ? 350 : 310,
        height: isDesktop ? 440 : 370,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              deity.gradientColors[0].withOpacity(0.92),
              deity.gradientColors[1].withOpacity(0.96),
              const Color(0xFF0F0503),
            ],
          ),
          border: Border.all(
            color: isSelected
                ? AppColors.goldLight.withOpacity(0.9)
                : AppColors.goldPrimary.withOpacity(0.35),
            width: isSelected ? 2.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: deity.primaryColor.withOpacity(isSelected ? 0.55 : 0.2),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ornate Corner Border
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomPaint(
                  painter: SacredCornerFiligreePainter(
                    filigreeColor: AppColors.goldLight.withOpacity(0.7),
                    cornerSize: 22,
                  ),
                ),
              ),
            ),

            // Authentic Deity Photo & Sacred Info
            Column(
              children: [
                const SizedBox(height: 12),
                // Deity Photo with Golden Altar Pedestal Frame
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Lotus / Pedestal Altar Base Glow
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 230,
                            height: 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              gradient: RadialGradient(
                                colors: [
                                  deity.accentColor.withOpacity(0.65),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // High-Resolution Background-Removed Deity Photo with Kireeta Preserved
                        Image.asset(
                          deity.imagePath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.wb_sunny, color: AppColors.goldLight, size: 64),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Deity Name Banner & Pedestal
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.68),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
                    border: const Border(
                      top: BorderSide(color: Color(0x55C8A050), width: 1.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        deity.deityName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldLight,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        deity.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Hanging Brass Bell ---

  Widget _buildHangingTempleBell() {
    return GestureDetector(
      onTap: _triggerBellRing,
      child: AnimatedBuilder(
        animation: _bellSwingController,
        builder: (context, child) {
          final swingAngle = math.sin(_bellSwingController.value * math.pi * 3) * 0.22;
          return Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()..rotateZ(swingAngle),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bell Chain
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF8D6E63),
                        AppColors.goldPrimary,
                        Color(0xFF5D4037),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Brass Bell Body
                Container(
                  width: 52,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFE082),
                        Color(0xFFFFA000),
                        Color(0xFFB57C1E),
                        Color(0xFFFFD54F),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isBellRinging
                            ? AppColors.goldLight.withOpacity(0.65)
                            : Colors.black.withOpacity(0.5),
                        blurRadius: _isBellRinging ? 22 : 8,
                        spreadRadius: _isBellRinging ? 5 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_active, size: 20, color: Color(0xFF4E342E)),
                        if (_isBellRinging)
                          const Text(
                            '🔔 OM',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
                // Bell Clapper
                Container(
                  width: 8,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5D4037),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Brass Diya on Pillar ---

  Widget _buildBrassDiyaPillar({required bool isLeft}) {
    final isLit = isLeft ? _leftDiyaLit : _rightDiyaLit;

    return GestureDetector(
      onTap: () => _toggleDiya(isLeft),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flame Animation
          if (isLit)
            AnimatedBuilder(
              animation: _flameFlickerController,
              builder: (context, _) {
                final scale = 0.85 + (_flameFlickerController.value * 0.25);
                final sway = math.sin(_flameFlickerController.value * math.pi) * 0.1;

                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..scale(scale)
                    ..rotateZ(isLeft ? sway : -sway),
                  child: Container(
                    width: 22,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment(0, 0.4),
                        radius: 0.8,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFFF176),
                          Color(0xFFFF9800),
                          Color(0xFFFF3D00),
                        ],
                        stops: [0.0, 0.25, 0.65, 1.0],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(100),
                        topRight: Radius.circular(100),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB300).withOpacity(0.85),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            const SizedBox(height: 34),

          // Brass Diya Lamp Cup
          Container(
            width: 48,
            height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFF8D6E63)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.wb_incandescent, size: 10, color: Color(0xFF5D4037)),
            ),
          ),

          // Brass Stand Pillar
          Container(
            width: 10,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFB57C1E), Color(0xFFFFE082), Color(0xFF6D4C41)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Diya Base Plate
          Container(
            width: 38,
            height: 10,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFB57C1E)],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }

  // --- Mangalarathi Revolving Brass Aarti Lamp ---

  Widget _buildMangalarathiOrbit(GarbhagruhaEnvironment deity) {
    return AnimatedBuilder(
      animation: _aartiOrbitController,
      builder: (context, child) {
        final angle = _aartiOrbitController.value * 2 * math.pi;
        const radiusX = 115.0;
        const radiusY = 75.0;
        final posX = math.cos(angle) * radiusX;
        final posY = math.sin(angle) * radiusY;

        return Transform.translate(
          offset: Offset(posX, posY),
          child: CustomPaint(
            size: const Size(64, 64),
            painter: BrassArathiLampPainter(
              flameFlicker: _flameFlickerController.value,
              glowColor: deity.accentColor,
            ),
          ),
        );
      },
    );
  }

  // --- Sacred Mantra Banner ---

  Widget _buildSacredMantraBanner(GarbhagruhaEnvironment deity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: LiquidGlass(
        style: GlassStyle.card,
        tint: deity.primaryColor,
        cornerRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(
              deity.moolaSanskrit,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.goldLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              deity.moolaKannada,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Ritual Action Console ---

  Widget _buildRitualActionBar(GarbhagruhaEnvironment deity) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF140804).withOpacity(0.95),
        border: const Border(
          top: BorderSide(color: Color(0x44C8A050), width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRitualButton(
            icon: Icons.notifications_active,
            label: 'Ring Bell',
            subLabel: 'ಘಂಟಾನಾದ',
            isActive: _isBellRinging,
            onTap: _triggerBellRing,
            deity: deity,
          ),
          _buildRitualButton(
            icon: Icons.local_florist,
            label: 'Flowers',
            subLabel: 'ಪುಷ್ಪಾರ್ಪಣೆ',
            isActive: _isFlowerShowering,
            onTap: _triggerFlowerShower,
            deity: deity,
          ),
          _buildRitualButton(
            icon: Icons.local_fire_department,
            label: 'Mangalarathi',
            subLabel: 'ಮಂಗಳಾರತಿ',
            isActive: _isAartiActive,
            onTap: _toggleAarti,
            deity: deity,
          ),
          _buildRitualButton(
            icon: Icons.air,
            label: 'Incense',
            subLabel: 'ಧೂಪ',
            isActive: _isDhoopaActive,
            onTap: _toggleDhoopa,
            deity: deity,
          ),
          _buildRitualButton(
            icon: _leftDiyaLit || _rightDiyaLit ? Icons.wb_sunny : Icons.wb_sunny_outlined,
            label: 'Light Diya',
            subLabel: 'ದೀಪ',
            isActive: _leftDiyaLit && _rightDiyaLit,
            onTap: () {
              final turnOn = !(_leftDiyaLit && _rightDiyaLit);
              setState(() {
                _leftDiyaLit = turnOn;
                _rightDiyaLit = turnOn;
              });
              if (turnOn) _incrementPoojaCount();
            },
            deity: deity,
          ),
        ],
      ),
    );
  }

  Widget _buildRitualButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required bool isActive,
    required VoidCallback onTap,
    required GarbhagruhaEnvironment deity,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          AppColors.goldLight,
                          deity.primaryColor,
                        ],
                      )
                    : const LinearGradient(
                        colors: [
                          Color(0xFF2C160F),
                          Color(0xFF1E0C06),
                        ],
                      ),
                border: Border.all(
                  color: isActive ? AppColors.goldLight : AppColors.goldPrimary.withOpacity(0.4),
                  width: isActive ? 2.0 : 1.0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.goldPrimary.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.black87 : AppColors.goldLight,
                size: 20,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.goldLight : Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Painters for Temple Aesthetics ---

class FlowerShowerPainter extends CustomPainter {
  final List<FlowerPetal> petals;

  FlowerShowerPainter(this.petals);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      final px = p.x * size.width;
      final py = p.y * size.height;
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      // Draw petal oval shape
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 1.5,
      );
      canvas.drawOval(rect, paint);

      // Inner petal highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity((p.opacity * 0.4).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      final innerRect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size * 0.4,
        height: p.size * 0.8,
      );
      canvas.drawOval(innerRect, highlightPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant FlowerShowerPainter oldDelegate) => true;
}

class SmokePainter extends CustomPainter {
  final List<SmokeParticle> particles;

  SmokePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in particles) {
      final paint = Paint()
        ..color = const Color(0xFFECEFF1).withOpacity(s.opacity.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SmokePainter oldDelegate) => true;
}
