// lib/components/map_view.dart
class MapLocation {
  final double latitude;
  final double longitude;
  final String? label;
  final IconData? icon;
  final Color? color;

  MapLocation({
    required this.latitude,
    required this.longitude,
    this.label,
    this.icon,
    this.color,
  });
}

class MapView extends StatelessWidget {
  final List<MapLocation> locations;
  final MapLocation? currentLocation;
  final double height;
  final VoidCallback? onFullScreen;

  const MapView({
    super.key,
    required this.locations,
    this.currentLocation,
    this.height = 300,
    this.onFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return HWYCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: HWYTheme.neutral100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(HWYTheme.radiusLarge),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: HWYTheme.neutral400,
                      ),
                      const SizedBox(height: HWYTheme.space2),
                      Text(
                        'Map View',
                        style: HWYTheme.textTheme.bodyMedium?.copyWith(
                          color: HWYTheme.neutral500,
                        ),
                      ),
                      Text(
                        '${locations.length} location${locations.length != 1 ? 's' : ''}',
                        style: HWYTheme.textTheme.bodySmall?.copyWith(
                          color: HWYTheme.neutral400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onFullScreen != null)
                  Positioned(
                    top: HWYTheme.space3,
                    right: HWYTheme.space3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: HWYTheme.neutral900.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: HWYIconButton(
                        icon: Icons.fullscreen,
                        onPressed: onFullScreen,
                        variant: HWYIconButtonVariant.ghost,
                        tooltip: 'Full Screen',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (locations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(HWYTheme.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentLocation != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.my_location,
                          size: 16,
                          color: HWYTheme.primaryBlue,
                        ),
                        const SizedBox(width: HWYTheme.space2),
                        Text(
                          'Current Location',
                          style: HWYTheme.textTheme.labelSmall?.copyWith(
                            color: HWYTheme.neutral600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: HWYTheme.space1),
                    Text(
                      currentLocation!.label ?? 
                          '${currentLocation!.latitude.toStringAsFixed(4)}, ${currentLocation!.longitude.toStringAsFixed(4)}',
                      style: HWYTheme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: HWYTheme.space3),
                    const HWYDivider(),
                    const SizedBox(height: HWYTheme.space3),
                  ],
                  Text(
                    'Waypoints',
                    style: HWYTheme.textTheme.labelMedium?.copyWith(
                      color: HWYTheme.neutral600,
                    ),
                  ),
                  const SizedBox(height: HWYTheme.space2),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: locations.length,
                    separatorBuilder: (context, index) => const SizedBox(height: HWYTheme.space2),
                    itemBuilder: (context, index) {
                      final location = locations[index];
                      return Row(
                        children: [
                          Icon(
                            location.icon ?? Icons.location_on,
                            size: 16,
                            color: location.color ?? HWYTheme.accentRed,
                          ),
                          const SizedBox(width: HWYTheme.space2),
                          Expanded(
                            child: Text(
                              location.label ?? 
                                  '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                              style: HWYTheme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// lib/components/stat_card.dart
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final HWYBadgeVariant variant;
  final String? trend;
  final bool trendPositive;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.variant = HWYBadgeVariant.primary,
    this.trend,
    this.trendPositive = true,
    this.onTap,
  });

  Color _getColor(HWYBadgeVariant variant) {
    switch (variant) {
      case HWYBadgeVariant.primary:
        return HWYTheme.primaryBlue;
      case HWYBadgeVariant.success:
        return HWYTheme.statusActive;
      case HWYBadgeVariant.warning:
        return HWYTheme.statusWarning;
      case HWYBadgeVariant.danger:
        return HWYTheme.statusDanger;
      case HWYBadgeVariant.info:
        return HWYTheme.statusInfo;
      case HWYBadgeVariant.neutral:
        return HWYTheme.neutral600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(variant);

    return HWYCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: HWYTheme.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: HWYTheme.textTheme.labelMedium?.copyWith(
                    color: HWYTheme.neutral600,
                  ),
                ),
                const SizedBox(height: HWYTheme.space1),
                Row(
                  children: [
                    Text(
                      value,
                      style: HWYTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (trend != null) ...[
                      const SizedBox(width: HWYTheme.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: HWYTheme.space2,
                          vertical: HWYTheme.space1,
                        ),
                        decoration: BoxDecoration(
                          color: trendPositive
                              ? HWYTheme.statusActive.withOpacity(0.1)
                              : HWYTheme.statusDanger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(HWYTheme.radiusSmall),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trendPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: trendPositive ? HWYTheme.statusActive : HWYTheme.statusDanger,
                            ),
                            const SizedBox(width: HWYTheme.space1),
                            Text(
                              trend!,
                              style: HWYTheme.textTheme.bodySmall?.copyWith(
                                color: trendPositive ? HWYTheme.statusActive : HWYTheme.statusDanger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// lib/components/quick_action_grid.dart
class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final HWYBadgeVariant variant;
  final String? badge;

  QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.variant = HWYBadgeVariant.primary,
    this.badge,
  });
}

class QuickActionGrid extends StatelessWidget {
  final List<QuickAction> actions;
  final int crossAxisCount;

  const QuickActionGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 2,
  });

  Color _getColor(HWYBadgeVariant variant) {
    switch (variant) {
      case HWYBadgeVariant.primary:
        return HWYTheme.primaryBlue;
      case HWYBadgeVariant.success:
        return HWYTheme.statusActive;
      case HWYBadgeVariant.warning:
        return HWYTheme.statusWarning;
      case HWYBadgeVariant.danger:
        return HWYTheme.statusDanger;
      case HWYBadgeVariant.info:
        return HWYTheme.statusInfo;
      case HWYBadgeVariant.neutral:
        return HWYTheme.neutral600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(// lib/components/load_card.dart
import 'package:flutter/material.dart';
import '../design_system/theme.dart';
import '../design_system/atoms/hwy_card.dart';
import '../design_system/atoms/hwy_badge.dart';
import '../design_system/atoms/hwy_button.dart';

enum LoadStatus {
  available,
  assigned,
  inTransit,
  delivered,
  cancelled,
}

class LoadCardData {
  final String id;
  final String origin;
  final String originCity;
  final String originState;
  final String destination;
  final String destinationCity;
  final String destinationState;
  final DateTime pickupDate;
  final DateTime deliveryDate;
  final double weight;
  final double rate;
  final double miles;
  final String commodity;
  final LoadStatus status;
  final String? driverName;
  final String? equipmentType;
  final bool isHazmat;

  LoadCardData({
    required this.id,
    required this.origin,
    required this.originCity,
    required this.originState,
    required this.destination,
    required this.destinationCity,
    required this.destinationState,
    required this.pickupDate,
    required this.deliveryDate,
    required this.weight,
    required this.rate,
    required this.miles,
    required this.commodity,
    required this.status,
    this.driverName,
    this.equipmentType,
    this.isHazmat = false,
  });
}

class LoadCard extends StatelessWidget {
  final LoadCardData load;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool showActions;
  final bool compact;

  const LoadCard({
    super.key,
    required this.load,
    this.onTap,
    this.onAccept,
    this.onDecline,
    this.showActions = false,
    this.compact = false,
  });

  HWYBadgeVariant _getStatusVariant(LoadStatus status) {
    switch (status) {
      case LoadStatus.available:
        return HWYBadgeVariant.info;
      case LoadStatus.assigned:
        return HWYBadgeVariant.warning;
      case LoadStatus.inTransit:
        return HWYBadgeVariant.primary;
      case LoadStatus.delivered:
        return HWYBadgeVariant.success;
      case LoadStatus.cancelled:
        return HWYBadgeVariant.danger;
    }
  }

  String _getStatusLabel(LoadStatus status) {
    switch (status) {
      case LoadStatus.available:
        return 'Available';
      case LoadStatus.assigned:
        return 'Assigned';
      case LoadStatus.inTransit:
        return 'In Transit';
      case LoadStatus.delivered:
        return 'Delivered';
      case LoadStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return HWYCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Load #${load.id}',
                      style: HWYTheme.textTheme.titleMedium,
                    ),
                    const SizedBox(width: HWYTheme.space2),
                    if (load.isHazmat)
                      const HWYBadge(
                        label: 'HAZMAT',
                        variant: HWYBadgeVariant.danger,
                        size: HWYBadgeSize.small,
                        icon: Icons.warning,
                      ),
                  ],
                ),
              ),
              HWYBadge(
                label: _getStatusLabel(load.status),
                variant: _getStatusVariant(load.status),
                size: HWYBadgeSize.small,
              ),
            ],
          ),
          const SizedBox(height: HWYTheme.space4),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(HWYTheme.space3),
                      decoration: BoxDecoration(
                        color: HWYTheme.neutral100,
                        borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trip_origin, size: 16, color: HWYTheme.accentGreen),
                              const SizedBox(width: HWYTheme.space2),
                              Text(
                                'Pickup',
                                style: HWYTheme.textTheme.labelSmall?.copyWith(
                                  color: HWYTheme.neutral500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: HWYTheme.space1),
                          Text(
                            '${load.originCity}, ${load.originState}',
                            style: HWYTheme.textTheme.titleSmall,
                          ),
                          Text(
                            _formatDate(load.pickupDate),
                            style: HWYTheme.textTheme.bodySmall?.copyWith(
                              color: HWYTheme.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: HWYTheme.space2),
                    const Icon(Icons.arrow_downward, size: 20, color: HWYTheme.neutral400),
                    const SizedBox(height: HWYTheme.space2),
                    Container(
                      padding: const EdgeInsets.all(HWYTheme.space3),
                      decoration: BoxDecoration(
                        color: HWYTheme.neutral100,
                        borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: HWYTheme.accentRed),
                              const SizedBox(width: HWYTheme.space2),
                              Text(
                                'Delivery',
                                style: HWYTheme.textTheme.labelSmall?.copyWith(
                                  color: HWYTheme.neutral500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: HWYTheme.space1),
                          Text(
                            '${load.destinationCity}, ${load.destinationState}',
                            style: HWYTheme.textTheme.titleSmall,
                          ),
                          Text(
                            _formatDate(load.deliveryDate),
                            style: HWYTheme.textTheme.bodySmall?.copyWith(
                              color: HWYTheme.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: HWYTheme.space4),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Commodity',
                    value: load.commodity,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    icon: Icons.scale_outlined,
                    label: 'Weight',
                    value: '${load.weight.toStringAsFixed(0)} lbs',
                  ),
                ),
              ],
            ),
            const SizedBox(height: HWYTheme.space3),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.route_outlined,
                    label: 'Distance',
                    value: '${load.miles.toStringAsFixed(0)} mi',
                  ),
                ),
                if (load.equipmentType != null)
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.local_shipping_outlined,
                      label: 'Equipment',
                      value: load.equipmentType!,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: HWYTheme.space4),
          Container(
            padding: const EdgeInsets.all(HWYTheme.space3),
            decoration: BoxDecoration(
              color: HWYTheme.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
              border: Border.all(color: HWYTheme.primaryBlue.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Rate',
                      style: HWYTheme.textTheme.labelSmall?.copyWith(
                        color: HWYTheme.neutral600,
                      ),
                    ),
                    Text(
                      _formatCurrency(load.rate),
                      style: HWYTheme.textTheme.headlineSmall?.copyWith(
                        color: HWYTheme.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Per Mile',
                      style: HWYTheme.textTheme.labelSmall?.copyWith(
                        color: HWYTheme.neutral600,
                      ),
                    ),
                    Text(
                      _formatCurrency(load.rate / load.miles),
                      style: HWYTheme.textTheme.titleMedium?.copyWith(
                        color: HWYTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (load.driverName != null) ...[
            const SizedBox(height: HWYTheme.space3),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: HWYTheme.neutral500),
                const SizedBox(width: HWYTheme.space2),
                Text(
                  'Driver: ${load.driverName}',
                  style: HWYTheme.textTheme.bodySmall?.copyWith(
                    color: HWYTheme.neutral600,
                  ),
                ),
              ],
            ),
          ],
          if (showActions && (onAccept != null || onDecline != null)) ...[
            const SizedBox(height: HWYTheme.space4),
            Row(
              children: [
                if (onDecline != null) ...[
                  Expanded(
                    child: HWYButton(
                      label: 'Decline',
                      onPressed: onDecline,
                      variant: HWYButtonVariant.outline,
                    ),
                  ),
                  const SizedBox(width: HWYTheme.space3),
                ],
                if (onAccept != null)
                  Expanded(
                    child: HWYButton(
                      label: 'Accept Load',
                      onPressed: onAccept,
                      variant: HWYButtonVariant.primary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: HWYTheme.neutral500),
        const SizedBox(width: HWYTheme.space2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: HWYTheme.textTheme.labelSmall?.copyWith(
                color: HWYTheme.neutral500,
              ),
            ),
            Text(
              value,
              style: HWYTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// lib/components/driver_card.dart
enum DriverStatus {
  available,
  onTrip,
  offDuty,
  inactive,
}

class DriverCardData {
  final String id;
  final String name;
  final String? photoUrl;
  final String phone;
  final String? email;
  final DriverStatus status;
  final String? currentLocation;
  final double? hoursRemaining;
  final String? truckNumber;
  final String? trailerNumber;
  final DateTime? lastUpdated;
  final int totalLoads;
  final double rating;

  DriverCardData({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.phone,
    this.email,
    required this.status,
    this.currentLocation,
    this.hoursRemaining,
    this.truckNumber,
    this.trailerNumber,
    this.lastUpdated,
    this.totalLoads = 0,
    this.rating = 0.0,
  });
}

class DriverCard extends StatelessWidget {
  final DriverCardData driver;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final bool showActions;
  final bool compact;

  const DriverCard({
    super.key,
    required this.driver,
    this.onTap,
    this.onCall,
    this.onMessage,
    this.showActions = true,
    this.compact = false,
  });

  HWYBadgeVariant _getStatusVariant(DriverStatus status) {
    switch (status) {
      case DriverStatus.available:
        return HWYBadgeVariant.success;
      case DriverStatus.onTrip:
        return HWYBadgeVariant.primary;
      case DriverStatus.offDuty:
        return HWYBadgeVariant.warning;
      case DriverStatus.inactive:
        return HWYBadgeVariant.neutral;
    }
  }

  String _getStatusLabel(DriverStatus status) {
    switch (status) {
      case DriverStatus.available:
        return 'Available';
      case DriverStatus.onTrip:
        return 'On Trip';
      case DriverStatus.offDuty:
        return 'Off Duty';
      case DriverStatus.inactive:
        return 'Inactive';
    }
  }

  IconData _getStatusIcon(DriverStatus status) {
    switch (status) {
      case DriverStatus.available:
        return Icons.check_circle;
      case DriverStatus.onTrip:
        return Icons.local_shipping;
      case DriverStatus.offDuty:
        return Icons.bedtime;
      case DriverStatus.inactive:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HWYCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              HWYAvatar(
                imageUrl: driver.photoUrl,
                initials: driver.name.split(' ').map((n) => n[0]).take(2).join(),
                size: compact ? HWYAvatarSize.medium : HWYAvatarSize.large,
              ),
              const SizedBox(width: HWYTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: compact ? HWYTheme.textTheme.titleSmall : HWYTheme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: HWYTheme.space1),
                    Text(
                      driver.phone,
                      style: HWYTheme.textTheme.bodySmall?.copyWith(
                        color: HWYTheme.neutral600,
                      ),
                    ),
                    if (!compact && driver.rating > 0) ...[
                      const SizedBox(height: HWYTheme.space1),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: HWYTheme.accentYellow),
                          const SizedBox(width: HWYTheme.space1),
                          Text(
                            driver.rating.toStringAsFixed(1),
                            style: HWYTheme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' • ${driver.totalLoads} loads',
                            style: HWYTheme.textTheme.bodySmall?.copyWith(
                              color: HWYTheme.neutral600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              HWYBadge(
                label: _getStatusLabel(driver.status),
                variant: _getStatusVariant(driver.status),
                icon: _getStatusIcon(driver.status),
                size: HWYBadgeSize.small,
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: HWYTheme.space4),
            if (driver.currentLocation != null)
              _DriverInfoRow(
                icon: Icons.location_on_outlined,
                label: 'Current Location',
                value: driver.currentLocation!,
              ),
            if (driver.hoursRemaining != null) ...[
              const SizedBox(height: HWYTheme.space2),
              _DriverInfoRow(
                icon: Icons.schedule,
                label: 'Hours Remaining',
                value: '${driver.hoursRemaining!.toStringAsFixed(1)} hrs',
                valueColor: driver.hoursRemaining! < 2 ? HWYTheme.accentRed : null,
              ),
            ],
            if (driver.truckNumber != null) ...[
              const SizedBox(height: HWYTheme.space2),
              Row(
                children: [
                  Expanded(
                    child: _DriverInfoRow(
                      icon: Icons.local_shipping_outlined,
                      label: 'Truck',
                      value: driver.truckNumber!,
                    ),
                  ),
                  if (driver.trailerNumber != null)
                    Expanded(
                      child: _DriverInfoRow(
                        icon: Icons.rv_hookup_outlined,
                        label: 'Trailer',
                        value: driver.trailerNumber!,
                      ),
                    ),
                ],
              ),
            ],
            if (driver.lastUpdated != null) ...[
              const SizedBox(height: HWYTheme.space3),
              Text(
                'Last updated ${_getTimeSince(driver.lastUpdated!)}',
                style: HWYTheme.textTheme.bodySmall?.copyWith(
                  color: HWYTheme.neutral500,
                ),
              ),
            ],
          ],
          if (showActions && (onCall != null || onMessage != null)) ...[
            const SizedBox(height: HWYTheme.space4),
            Row(
              children: [
                if (onCall != null) ...[
                  Expanded(
                    child: HWYButton(
                      label: 'Call',
                      icon: Icons.phone,
                      onPressed: onCall,
                      variant: HWYButtonVariant.outline,
                    ),
                  ),
                  const SizedBox(width: HWYTheme.space3),
                ],
                if (onMessage != null)
                  Expanded(
                    child: HWYButton(
                      label: 'Message',
                      icon: Icons.message,
                      onPressed: onMessage,
                      variant: HWYButtonVariant.primary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getTimeSince(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _DriverInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DriverInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: HWYTheme.neutral500),
        const SizedBox(width: HWYTheme.space2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: HWYTheme.textTheme.labelSmall?.copyWith(
                  color: HWYTheme.neutral500,
                ),
              ),
              Text(
                value,
                style: HWYTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// lib/components/document_viewer.dart
enum DocumentType {
  bol,
  pod,
  rateConfirmation,
  invoice,
  receipt,
  permit,
  inspection,
  other,
}

class DocumentData {
  final String id;
  final String name;
  final DocumentType type;
  final DateTime uploadedDate;
  final String? uploadedBy;
  final String? fileUrl;
  final int? fileSize;
  final String? thumbnail;

  DocumentData({
    required this.id,
    required this.name,
    required this.type,
    required this.uploadedDate,
    this.uploadedBy,
    this.fileUrl,
    this.fileSize,
    this.thumbnail,
  });
}

class DocumentViewer extends StatelessWidget {
  final List<DocumentData> documents;
  final Function(DocumentData)? onView;
  final Function(DocumentData)? onDownload;
  final Function(DocumentData)? onDelete;
  final VoidCallback? onUpload;

  const DocumentViewer({
    super.key,
    required this.documents,
    this.onView,
    this.onDownload,
    this.onDelete,
    this.onUpload,
  });

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.bol:
        return Icons.receipt_long;
      case DocumentType.pod:
        return Icons.task_alt;
      case DocumentType.rateConfirmation:
        return Icons.attach_money;
      case DocumentType.invoice:
        return Icons.receipt;
      case DocumentType.receipt:
        return Icons.credit_card;
      case DocumentType.permit:
        return Icons.badge;
      case DocumentType.inspection:
        return Icons.verified;
      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }

  String _getDocumentTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.bol:
        return 'Bill of Lading';
      case DocumentType.pod:
        return 'Proof of Delivery';
      case DocumentType.rateConfirmation:
        return 'Rate Confirmation';
      case DocumentType.invoice:
        return 'Invoice';
      case DocumentType.receipt:
        return 'Receipt';
      case DocumentType.permit:
        return 'Permit';
      case DocumentType.inspection:
        return 'Inspection';
      case DocumentType.other:
        return 'Document';
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return HWYCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Documents',
                style: HWYTheme.textTheme.titleMedium,
              ),
              if (onUpload != null)
                HWYIconButton(
                  icon: Icons.upload_file,
                  onPressed: onUpload,
                  tooltip: 'Upload Document',
                ),
            ],
          ),
          const SizedBox(height: HWYTheme.space4),
          if (documents.isEmpty)
            HWYEmptyState(
              icon: Icons.folder_open,
              title: 'No Documents',
              description: 'Upload documents to get started',
              actionLabel: onUpload != null ? 'Upload Document' : null,
              onAction: onUpload,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.length,
              separatorBuilder: (context, index) => const SizedBox(height: HWYTheme.space3),
              itemBuilder: (context, index) {
                final doc = documents[index];
                return Container(
                  padding: const EdgeInsets.all(HWYTheme.space3),
                  decoration: BoxDecoration(
                    color: HWYTheme.neutral50,
                    borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
                    border: Border.all(color: HWYTheme.neutral200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: HWYTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
                        ),
                        child: Icon(
                          _getDocumentIcon(doc.type),
                          color: HWYTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: HWYTheme.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.name,
                              style: HWYTheme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: HWYTheme.space1),
                            Text(
                              '${_getDocumentTypeLabel(doc.type)} • ${_formatFileSize(doc.fileSize)}',
                              style: HWYTheme.textTheme.bodySmall?.copyWith(
                                color: HWYTheme.neutral500,
                              ),
                            ),
                            Text(
                              'Uploaded ${_formatDate(doc.uploadedDate)}',
                              style: HWYTheme.textTheme.bodySmall?.copyWith(
                                color: HWYTheme.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onView != null)
                        HWYIconButton(
                          icon: Icons.visibility,
                          onPressed: () => onView!(doc),
                          variant: HWYIconButtonVariant.ghost,
                          size: HWYIconButtonSize.small,
                          tooltip: 'View',
                        ),
                      if (onDownload != null)
                        HWYIconButton(
                          icon: Icons.download,
                          onPressed: () => onDownload!(doc),
                          variant: HWYIconButtonVariant.ghost,
                          size: HWYIconButtonSize.small,
                          tooltip: 'Download',
                        ),
                      if (onDelete != null)
                        HWYIconButton(
                          icon: Icons.delete,
                          onPressed: () => onDelete!(doc),
                          variant: HWYIconButtonVariant.ghost,
                          size: HWYIconButtonSize.small,
                          tooltip: 'Delete',
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// lib/components/status_badge_extended.dart
class StatusBadgeExtended extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData icon;
  final HWYBadgeVariant variant;
  final VoidCallback? onTap;

  const StatusBadgeExtended({
    super.key,
    required this.label,
    this.sublabel,
    required this.icon,
    this.variant = HWYBadgeVariant.neutral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    
    switch (variant) {
      case HWYBadgeVariant.primary:
        backgroundColor = HWYTheme.primaryBlue.withOpacity(0.1);
        textColor = HWYTheme.primaryBlue;
        break;
      case HWYBadgeVariant.success:
        backgroundColor = HWYTheme.statusActive.withOpacity(0.1);
        textColor = HWYTheme.statusActive;
        break;
      case HWYBadgeVariant.warning:
        backgroundColor = HWYTheme.statusWarning.withOpacity(0.1);
        textColor = HWYTheme.statusWarning;
        break;
      case HWYBadgeVariant.danger:
        backgroundColor = HWYTheme.statusDanger.withOpacity(0.1);
        textColor = HWYTheme.statusDanger;
        break;
      case HWYBadgeVariant.info:
        backgroundColor = HWYTheme.statusInfo.withOpacity(0.1);
        textColor = HWYTheme.statusInfo;
        break;
      case HWYBadgeVariant.neutral:
        backgroundColor = HWYTheme.neutral200;
        textColor = HWYTheme.neutral700;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(HWYTheme.space3),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(HWYTheme.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: HWYTheme.space3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: HWYTheme.textTheme.titleSmall?.copyWith(
                    color: textColor,
                  ),
                ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: HWYTheme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// lib/components/message_thread.dart
class MessageData {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool isSentByMe;

  MessageData({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.isSentByMe = false,
  });
}

class MessageThread extends StatefulWidget {
  final List<MessageData> messages;
  final Function(String)? onSendMessage;
  final String currentUserId;

  const MessageThread({
    super.key,
    required this.messages,
    this.onSendMessage,
    required this.currentUserId,
  });

  @override
  State<MessageThread> createState() => _MessageThreadState();
}

class _MessageThreadState extends State<MessageThread> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && widget.onSendMessage != null) {
      widget.onSendMessage!(_messageController.text.trim());
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[dateTime.weekday % 7];
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.messages.isEmpty
              ? const HWYEmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No Messages',
                  description: 'Start a conversation',
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(HWYTheme.space4),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final message = widget.messages[index];
                    final showAvatar = index == 0 || 
                        widget.messages[index - 1].senderId != message.senderId;

                    return Padding(
                      padding: EdgeInsets.only(
                        top: showAvatar ? HWYTheme.space4 : HWYTheme.space2,
                      ),
                      child: Row(
                        mainAxisAlignment: message.isSentByMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!message.isSentByMe && showAvatar)
                            HWYAvatar(
                              imageUrl: message.senderPhoto,
                              initials: message.senderName.split(' ').map((n) => n[0]).take(2).join(),
                              size: HWYAvatarSize.small,
                            )
                          else if (!message.isSentByMe)
                            const SizedBox(width: 32),
                          const SizedBox(width: HWYTheme.space2),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: message.isSentByMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (showAvatar && !message.isSentByMe)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: HWYTheme.space2,
                                      bottom: HWYTheme.space1,
                                    ),
                                    child: Text(
                                      message.senderName,
                                      style: HWYTheme.textTheme.labelSmall?.copyWith(
                                        color: HWYTheme.neutral600,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: HWYTheme.space4,
                                    vertical: HWYTheme.space3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: message.isSentByMe
                                        ? HWYTheme.primaryBlue
                                        : HWYTheme.neutral200,
                                    borderRadius: BorderRadius.circular(HWYTheme.radiusLarge),
                                  ),
                                  child: Text(
                                    message.content,
                                    style: HWYTheme.textTheme.bodyMedium?.copyWith(
                                      color: message.isSentByMe
                                          ? Colors.white
                                          : HWYTheme.neutral900,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: HWYTheme.space2,
                                    right: HWYTheme.space2,
                                    top: HWYTheme.space1,
                                  ),
                                  child: Text(
                                    _formatTime(message.timestamp),
                                    style: HWYTheme.textTheme.bodySmall?.copyWith(
                                      color: HWYTheme.neutral500,
                                    ),
                                  ),
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
        if (widget.onSendMessage != null)
          Container(
            padding: const EdgeInsets.all(HWYTheme.space4),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: HWYTheme.neutral200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: HWYTheme.textTheme.bodyMedium?.copyWith(
                        color: HWYTheme.neutral400,
                      ),
                      filled: true,
                      fillColor: HWYTheme.neutral100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: HWYTheme.space4,
                        vertical: HWYTheme.space3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(HWYTheme.radiusFull),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: HWYTheme.space3),
                HWYIconButton(
                  icon: Icons.send,
                  onPressed: _sendMessage,
                  size: HWYIconButtonSize.large,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// lib/components/trip_timeline.dart
enum TripEventType {
  pickup,
  delivery,
  checkpoint,
  rest,
  fuel,
  inspection,
}

class TripEvent {
  final TripEventType type;
  final String location;
  final DateTime dateTime;
  final bool isCompleted;
  final String? notes;
  final double? latitude;
  final double? longitude;

  TripEvent({
    required this.type,
    required this.location,
    required this.dateTime,
    this.isCompleted = false,
    this.notes,
    this.latitude,
    this.longitude,
  });
}

class TripTimeline extends StatelessWidget {
  final List<TripEvent> events;
  final String? currentLocation;

  const TripTimeline({
    super.key,
    required this.events,
    this.currentLocation,
  });

  IconData _getEventIcon(TripEventType type) {
    switch (type) {
      case TripEventType.pickup:
        return Icons.trip_origin;
      case TripEventType.delivery:
        return Icons.location_on;
      case TripEventType.checkpoint:
        return Icons.flag;
      case TripEventType.rest:
        return Icons.hotel;
      case TripEventType.fuel:
        return Icons.local_gas_station;
      case TripEventType.inspection:
        return Icons.fact_check;
    }
  }

  Color _getEventColor(TripEventType type, bool isCompleted) {
    if (isCompleted) {
      return HWYTheme.statusActive;
    }
    switch (type) {
      case TripEventType.pickup:
        return HWYTheme.accentGreen;
      case TripEventType.delivery:
        return HWYTheme.accentRed;
      case TripEventType.checkpoint:
        return HWYTheme.primaryBlue;
      case TripEventType.rest:
        return HWYTheme.accentOrange;
      case TripEventType.fuel:
        return HWYTheme.accentYellow;
      case TripEventType.inspection:
        return HWYTheme.neutral600;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${months[dateTime.month - 1]} ${dateTime.day}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return HWYCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Timeline',
            style: HWYTheme.textTheme.titleMedium,
          ),
          if (currentLocation != null) ...[
            const SizedBox(height: HWYTheme.space2),
            Row(
              children: [
                const Icon(Icons.my_location, size: 16, color: HWYTheme.primaryBlue),
                const SizedBox(width: HWYTheme.space2),
                Text(
                  'Current: $currentLocation',
                  style: HWYTheme.textTheme.bodySmall?.copyWith(
                    color: HWYTheme.neutral600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: HWYTheme.space4),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              final color = _getEventColor(event.type, event.isCompleted);

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: event.isCompleted ? color : Colors.white,
                            border: Border.all(color: color, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            event.isCompleted ? Icons.check : _getEventIcon(event.type),
                            size: 16,
                            color: event.isCompleted ? Colors.white : color,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: event.isCompleted ? color : HWYTheme.neutral300,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: HWYTheme.space3),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: isLast ? 0 : HWYTheme.space4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.location,
                              style: HWYTheme.textTheme.titleSmall?.copyWith(
                                color: event.isCompleted ? HWYTheme.neutral800 : HWYTheme.neutral600,
                              ),
                            ),
                            const SizedBox(height: HWYTheme.space1),
                            Text(
                              _formatDateTime(event.dateTime),
                              style: HWYTheme.textTheme.bodySmall?.copyWith(
                                color: HWYTheme.neutral500,
                              ),
                            ),
                            if (event.notes != null) ...[
                              const SizedBox(height: HWYTheme.space2),
                              Text(
                                event.notes!,
                                style: HWYTheme.textTheme.bodySmall?.copyWith(
                                  color: HWYTheme.neutral600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}