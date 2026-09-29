import 'package:flutter/material.dart';

class ShimmerSongTile extends StatefulWidget {
  const ShimmerSongTile({super.key});

  @override
  State<ShimmerSongTile> createState() => _ShimmerSongTileState();
}

class _ShimmerSongTileState extends State<ShimmerSongTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final shimmerValue = _shimmerController.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEADBCE)),
          ),
          child: Row(
            children: [
              // Artwork Shimmer
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: const [
                      Color(0xFFEDE5D8),
                      Color(0xFFFBF8F2),
                      Color(0xFFEDE5D8),
                    ],
                    stops: [shimmerValue - 0.3, shimmerValue, shimmerValue + 0.3],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Title & Deity Shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: const [
                            Color(0xFFEDE5D8),
                            Color(0xFFFBF8F2),
                            Color(0xFFEDE5D8),
                          ],
                          stops: [shimmerValue - 0.3, shimmerValue, shimmerValue + 0.3],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: const [
                            Color(0xFFEDE5D8),
                            Color(0xFFFBF8F2),
                            Color(0xFFEDE5D8),
                          ],
                          stops: [shimmerValue - 0.3, shimmerValue, shimmerValue + 0.3],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Action Button Shimmer
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF3ECE0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
