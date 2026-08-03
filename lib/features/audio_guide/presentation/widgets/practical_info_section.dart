import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';

class PracticalInfoSection extends StatelessWidget {
  const PracticalInfoSection({required this.attraction, super.key});

  final Attraction? attraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          if (attraction == null) ...[
            const _InfoRow(icon: Icons.info_outline, text: '未找到對應景點資訊'),
          ] else ...[
            if (attraction!.address.isNotEmpty)
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: attraction!.address,
              ),
            if (attraction!.openTime.isNotEmpty)
              _InfoRow(
                icon: Icons.access_time_outlined,
                text: attraction!.openTime,
              ),
            if (attraction!.tel.isNotEmpty)
              _InfoRow(icon: Icons.phone_outlined, text: attraction!.tel),
            if (attraction!.ticket.isNotEmpty)
              _InfoRow(
                icon: Icons.confirmation_number_outlined,
                text: attraction!.ticket,
              ),
            if (attraction!.remind.isNotEmpty)
              _InfoRow(icon: Icons.info_outline, text: attraction!.remind),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
