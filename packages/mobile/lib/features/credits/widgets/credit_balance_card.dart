import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

class CreditBalanceCard extends StatefulWidget {
  const CreditBalanceCard({
    required this.balance,
    super.key,
    this.lockedBalance = 0,
    this.isLowBalance = false,
    this.onTap,
  });
  final int balance;
  final int lockedBalance;
  final bool isLowBalance;
  final VoidCallback? onTap;

  @override
  State<CreditBalanceCard> createState() => _CreditBalanceCardState();
}

class _CreditBalanceCardState extends State<CreditBalanceCard>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Sparkle animation for golden effect
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    // Pulse animation for low balance warning
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer animation for golden shine
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _startAnimations();
  }

  void _startAnimations() {
    // Continuous sparkle animation
    _sparkleController.repeat(reverse: true);

    // Shimmer every 5 seconds
    _shimmerController.repeat();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _shimmerController.repeat();
    });

    // Pulse animation only for low balance
    if (widget.isLowBalance) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(CreditBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start/stop pulse animation based on low balance status
    if (widget.isLowBalance != oldWidget.isLowBalance) {
      if (widget.isLowBalance) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableBalance = widget.balance - widget.lockedBalance;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _sparkleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isLowBalance ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sgPrimary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  if (widget.isLowBalance)
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Main gradient background
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isLowBalance
                            ? [Colors.red.shade400, Colors.red.shade600]
                            : [AppColors.sgPrimary, AppColors.sgSecondary],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with SG logo/icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Saldo de Créditos SG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (widget.isLowBalance)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'BAIXO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Main balance display
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              availableBalance.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'SG',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Disponível para uso',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),

                        if (widget.lockedBalance > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.lockedBalance} SG bloqueados',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Animated shimmer overlay
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return Shimmer.fromColors(
                          baseColor: Colors.transparent,
                          highlightColor: Colors.white.withOpacity(0.3),
                          period: const Duration(seconds: 2),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: const Alignment(-1.0, -0.3),
                                end: const Alignment(1.0, 0.3),
                                colors: const [
                                  Colors.transparent,
                                  Colors.white24,
                                  Colors.transparent,
                                ],
                                stops: [0.0, _shimmerController.value, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Sparkle effects
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _sparkleAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: SparklePainter(
                            animationValue: _sparkleAnimation.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // Tap indicator
                  if (widget.onTap != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Icon(
                        Icons.touch_app,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SparklePainter extends CustomPainter {
  SparklePainter({required this.animationValue});
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Create sparkle positions
    final sparkles = [
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.8),
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.6, size.height * 0.1),
    ];

    for (int i = 0; i < sparkles.length; i++) {
      final opacity = (animationValue + (i * 0.2)) % 1.0;
      final sparkleSize = 2.0 + (opacity * 3.0);

      paint.color = Colors.white.withOpacity(opacity * 0.8);

      // Draw sparkle as a small star
      _drawStar(canvas, sparkles[i], sparkleSize, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const angles = [
      0.0,
      0.628,
      1.257,
      1.885,
      2.513,
      3.141,
      3.769,
      4.398,
      5.026,
      5.654,
    ];

    for (int i = 0; i < angles.length; i++) {
      final radius = i.isEven ? size : size * 0.5;
      final x = center.dx + radius * 0.5 * (i.isEven ? 1 : 0.6);
      final y = center.dy + radius * 0.5 * (i.isEven ? 1 : 0.6);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
