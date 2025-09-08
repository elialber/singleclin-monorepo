import 'package:flutter/material.dart';
import 'package:singleclin_mobile/features/clinic_discovery/models/clinic.dart';
import 'package:singleclin_mobile/core/constants/app_colors.dart';

class SocialMediaSection extends StatelessWidget {
  final Clinic clinic;

  const SocialMediaSection({
    Key? key,
    required this.clinic,
  }) : super(key: key);

  // Mock social media data - in real implementation, this would come from clinic model
  List<SocialMediaLink> get _socialMediaLinks => [
    SocialMediaLink(
      platform: SocialPlatform.instagram,
      url: 'https://instagram.com/${clinic.name.replaceAll(' ', '').toLowerCase()}',
      handle: '@${clinic.name.replaceAll(' ', '').toLowerCase()}',
      followersCount: 1250,
      isVerified: true,
    ),
    SocialMediaLink(
      platform: SocialPlatform.website,
      url: 'https://www.${clinic.name.replaceAll(' ', '').toLowerCase()}.com.br',
      handle: 'Site oficial',
      followersCount: 0,
      isVerified: false,
    ),
    SocialMediaLink(
      platform: SocialPlatform.whatsapp,
      url: 'https://wa.me/5511999999999',
      handle: clinic.contact.phone.isNotEmpty ? clinic.contact.phone : '(11) 99999-9999',
      followersCount: 0,
      isVerified: false,
    ),
    SocialMediaLink(
      platform: SocialPlatform.facebook,
      url: 'https://facebook.com/${clinic.name.replaceAll(' ', '').toLowerCase()}',
      handle: clinic.name,
      followersCount: 850,
      isVerified: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Redes sociais e contato',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Conecte-se com a clínica',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            // Online Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Social Media Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.8,
          ),
          itemCount: _socialMediaLinks.length,
          itemBuilder: (context, index) {
            return _buildSocialMediaCard(_socialMediaLinks[index]);
          },
        ),
        
        const SizedBox(height: 16),
        
        // Quick Actions
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildSocialMediaCard(SocialMediaLink link) {
    return InkWell(
      onTap: () => _openSocialLink(link),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: link.platform.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: link.platform.color.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Platform Icon and Verification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: link.platform.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    link.platform.icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                if (link.isVerified)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
              ],
            ),
            
            // Platform Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.platform.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: link.platform.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  link.handle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (link.followersCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_formatFollowerCount(link.followersCount)} seguidores',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações rápidas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.phone,
                  label: 'Ligar',
                  color: Colors.green,
                  onTap: () => _makePhoneCall(),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _openWhatsApp(),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.email,
                  label: 'Email',
                  color: Colors.blue,
                  onTap: () => _sendEmail(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFollowerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  void _openSocialLink(SocialMediaLink link) {
    // TODO: Implement URL launcher to open social media links
    // Example: launch(link.url);
    
    // For now, show a placeholder message
    if (link.platform == SocialPlatform.whatsapp) {
      _openWhatsApp();
    } else {
      // Show a snackbar for other platforms
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Abrindo ${link.platform.displayName}...'),
      //     duration: const Duration(seconds: 1),
      //   ),
      // );
    }
  }

  void _makePhoneCall() {
    // TODO: Implement phone call functionality
    // Example: launch('tel:${clinic.phone}');
    
    // For now, show a placeholder message
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text('Iniciando chamada...'),
    //     duration: Duration(seconds: 1),
    //   ),
    // );
  }

  void _openWhatsApp() {
    // TODO: Implement WhatsApp functionality
    // Example: launch('https://wa.me/5511999999999');
    
    // For now, show a placeholder message
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text('Abrindo WhatsApp...'),
    //     duration: Duration(seconds: 1),
    //   ),
    // );
  }

  void _sendEmail() {
    // TODO: Implement email functionality
    // Example: launch('mailto:contato@clinica.com.br');
    
    // For now, show a placeholder message
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(
    //     content: Text('Abrindo email...'),
    //     duration: Duration(seconds: 1),
    //   ),
    // );
  }
}

enum SocialPlatform {
  instagram,
  facebook,
  whatsapp,
  website,
}

extension SocialPlatformExtension on SocialPlatform {
  String get displayName {
    switch (this) {
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.whatsapp:
        return 'WhatsApp';
      case SocialPlatform.website:
        return 'Website';
    }
  }

  IconData get icon {
    switch (this) {
      case SocialPlatform.instagram:
        return Icons.camera_alt;
      case SocialPlatform.facebook:
        return Icons.facebook;
      case SocialPlatform.whatsapp:
        return Icons.chat;
      case SocialPlatform.website:
        return Icons.language;
    }
  }

  Color get color {
    switch (this) {
      case SocialPlatform.instagram:
        return const Color(0xFFE4405F);
      case SocialPlatform.facebook:
        return const Color(0xFF1877F2);
      case SocialPlatform.whatsapp:
        return const Color(0xFF25D366);
      case SocialPlatform.website:
        return const Color(0xFF6B73FF);
    }
  }
}

class SocialMediaLink {
  final SocialPlatform platform;
  final String url;
  final String handle;
  final int followersCount;
  final bool isVerified;

  SocialMediaLink({
    required this.platform,
    required this.url,
    required this.handle,
    required this.followersCount,
    required this.isVerified,
  });
}