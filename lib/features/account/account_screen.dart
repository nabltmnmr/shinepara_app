import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';
import '../../services/providers.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _launchWhatsApp({String? message}) async {
    final encodedMessage = message != null ? Uri.encodeComponent(message) : '';
    const phoneNumber = '9647744445057';
    final url = Uri.parse('https://wa.me/$phoneNumber${encodedMessage.isNotEmpty ? "?text=$encodedMessage" : ""}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label (coming soon)'),
        backgroundColor: AppColors.bottomNavBackground.withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showAvatarActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBottomPanel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 46,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                _SheetAction(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Take photo');
                  },
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Choose photo');
                  },
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.delete_outline,
                  label: 'Remove Photo',
                  accent: const Color(0xFFE05A5A),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon(context, 'Remove photo');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final wishlistCount = ref.watch(wishlistProvider).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _ProfileBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(
                    title: 'My Profile',
                    onTapSettings: user == null
                        ? () => _showComingSoon(context, 'Settings')
                        : () => _showEditProfileDialog(context, ref),
                  ),
                  const SizedBox(height: 18),
                  _AvatarSection(
                    name: user?.fullName ?? 'Shine Guest',
                    // UI-only placeholder for "set profile picture" + edit badge
                    onTapEdit: user == null ? () => context.push('/login') : () => _showAvatarActions(context),
                    imageProvider: const AssetImage('assets/images/placeholder.png'),
                  ),
                  const SizedBox(height: 18),
                  _SkinHealthCard(
                    onTapFullReport: () => _showComingSoon(context, 'Full Report'),
                    onTapCard: () => _showComingSoon(context, 'Skin Health'),
                  ),
                  const SizedBox(height: 18),
                  Column(
                    children: [
                      _MenuRow(
                        title: 'My Routine',
                        icon: Icons.face_retouching_natural_outlined,
                        onTap: () => _showComingSoon(context, 'My Routine'),
                      ),
                      const SizedBox(height: 12),
                      _MenuRow(
                        title: 'Orders',
                        icon: Icons.local_shipping_outlined,
                        onTap: () => user == null ? context.push('/login') : context.push('/orders'),
                      ),
                      const SizedBox(height: 12),
                      _MenuRow(
                        title: 'Payment Methods',
                        icon: Icons.credit_card,
                        onTap: () => _showComingSoon(context, 'Payment Methods'),
                      ),
                      const SizedBox(height: 12),
                      _MenuRow(
                        title: 'Wishlist',
                        icon: Icons.favorite_rounded,
                        leadingCount: wishlistCount,
                        onTap: () => context.push('/wishlist'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ExpertCta(
                    onTap: () => _launchWhatsApp(message: 'Hello Shine 👋'),
                  ),
                  if (user == null) ...[
                    const SizedBox(height: 12),
                    _LoginRow(
                      onLogin: () => context.push('/login'),
                      onSignup: () => context.push('/signup'),
                    ),
                  ] else ...[
                    const SizedBox(height: 18),
                    _MenuRow(
                      title: 'Logout',
                      icon: Icons.logout,
                      accentColor: const Color(0xFFE05A5A),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Logout', style: TextStyle(color: Color(0xFFE05A5A))),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/');
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider);
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final locationController = TextEditingController(text: user.location ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الملف الشخصي', textDirection: TextDirection.rtl),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'الموقع',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(authProvider.notifier).updateProfile(
                  fullName: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  location: locationController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم تحديث البيانات بنجاح', textDirection: TextDirection.rtl),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل تحديث البيانات: ${e.toString()}', textDirection: TextDirection.rtl),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // Previous ListTile menu removed in favor of screenshot-matching rows.
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF261411),
                  AppColors.background,
                  Color(0xFF160C0A),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -120,
          child: _GlowBlob(color: AppColors.accentGold.withOpacity(0.20), size: 340),
        ),
        Positioned(
          top: 180,
          left: -140,
          child: _GlowBlob(color: AppColors.primary.withOpacity(0.10), size: 320),
        ),
        Positioned(
          bottom: -160,
          left: -140,
          child: _GlowBlob(color: AppColors.accentGold.withOpacity(0.14), size: 360),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 140,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onTapSettings;

  const _TopBar({required this.title, required this.onTapSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          IconButton(
            onPressed: onTapSettings,
            icon: const Icon(Icons.settings_outlined, color: AppColors.white, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final String name;
  final VoidCallback onTapEdit;
  final ImageProvider imageProvider;

  const _AvatarSection({
    required this.name,
    required this.onTapEdit,
    required this.imageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // outer glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withOpacity(0.35),
                      blurRadius: 46,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
              // ring
              Container(
                width: 118,
                height: 118,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentGold,
                      AppColors.accentGold.withOpacity(0.35),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1D110F),
                    border: Border.all(color: Colors.black.withOpacity(0.35), width: 2),
                  ),
                  child: ClipOval(
                    child: Image(image: imageProvider, fit: BoxFit.cover),
                  ),
                ),
              ),
              // edit badge
              Positioned(
                bottom: 8,
                right: 10,
                child: GestureDetector(
                  onTap: onTapEdit,
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2A1A16),
                      border: Border.all(color: AppColors.accentGold.withOpacity(0.7), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGold.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit, size: 16, color: AppColors.accentGold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          textAlign: TextAlign.center,
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 30,
          ),
        ),
      ],
    );
  }
}

class _SkinHealthCard extends StatelessWidget {
  final VoidCallback? onTapFullReport;
  final VoidCallback? onTapCard;

  const _SkinHealthCard({this.onTapFullReport, this.onTapCard});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground.withOpacity(0.48),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapFullReport,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_right_alt_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Full Report',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Skin Health',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last Scan: Today, 9:00 AM',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: _StatTileGlow()),
                SizedBox(width: 12),
                Expanded(child: _StatTileRing(label: 'TEXTURE', valueText: '92', progress: 0.92)),
                SizedBox(width: 12),
                Expanded(child: _StatTileRing(label: 'HYDRATION', valueText: '85%', progress: 0.85)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginRow extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  const _LoginRow({required this.onLogin, required this.onSignup});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Login'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: onSignup,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.white.withOpacity(0.18)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: const Text('Sign Up'),
          ),
        ),
      ],
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppColors.accentGold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, color: c),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTileBase extends StatelessWidget {
  final Widget child;
  const _StatTileBase({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.14),
            border: Border.all(color: AppColors.white.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatTileGlow extends StatelessWidget {
  const _StatTileGlow();

  @override
  Widget build(BuildContext context) {
    return _StatTileBase(
      child: Column(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGold.withOpacity(0.10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.22),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: AppColors.accentGold.withOpacity(0.40)),
            ),
            child: const Icon(Icons.wb_sunny_outlined, color: AppColors.accentGold),
          ),
          const SizedBox(height: 12),
          Text(
            'GLOW',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.iconTint,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTileRing extends StatelessWidget {
  final String label;
  final String valueText;
  final double progress;
  const _StatTileRing({required this.label, required this.valueText, required this.progress});

  @override
  Widget build(BuildContext context) {
    return _StatTileBase(
      child: Column(
        children: [
          SizedBox(
            height: 56,
            width: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: AppColors.white.withOpacity(0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                ),
                Text(
                  valueText,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.iconTint,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int? leadingCount;
  final Color? accentColor;

  const _MenuRow({
    required this.title,
    required this.icon,
    required this.onTap,
    this.leadingCount,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.accentGold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.bottomNavBackground.withOpacity(0.44),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            if (leadingCount != null) ...[
              Text(
                '$leadingCount',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white.withOpacity(0.90),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Icon(Icons.chevron_left, color: AppColors.white.withOpacity(0.55)),
            const Spacer(),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.14),
                border: Border.all(color: accent.withOpacity(0.55)),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpertCta extends StatelessWidget {
  final VoidCallback onTap;
  const _ExpertCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: const Color(0xFF1B100E).withOpacity(0.78),
          border: Border.all(color: AppColors.accentGold.withOpacity(0.30), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.18),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.whatsappGreen.withOpacity(0.16),
                border: Border.all(color: AppColors.whatsappGreen.withOpacity(0.35)),
              ),
              child: const Icon(Icons.arrow_forward, color: AppColors.whatsappGreen),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Expert',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Chat on WhatsApp',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.iconTint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.whatsappGreen.withOpacity(0.18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.whatsappGreen.withOpacity(0.28),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: AppColors.whatsappGreen),
            ),
          ],
        ),
      ),
    );
  }
}

