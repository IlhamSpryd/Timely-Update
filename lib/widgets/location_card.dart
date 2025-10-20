import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timely/utils/app_theme.dart';

class LocationCard extends StatefulWidget {
  final String currentAddress;
  final bool isLoadingLocation;
  final bool isInOfficeArea;
  final Set<Marker> markers;
  final Circle? officeCircle;
  final LatLng officeLocation;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onRefreshLocation;

  const LocationCard({
    super.key,
    required this.currentAddress,
    required this.isLoadingLocation,
    required this.isInOfficeArea,
    required this.markers,
    this.officeCircle,
    required this.officeLocation,
    required this.onMapCreated,
    required this.onRefreshLocation,
  });

  @override
  State<LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<LocationCard>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _heightAnimation = Tween<double>(begin: 280, end: 460).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _setMapStyle() async {
    if (_mapController == null) return;
    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final style = await rootBundle.loadString(
        isDarkMode
            ? 'assets/maps/maps_styles_dark.json'
            : 'assets/maps/maps_styles_ligh.json',
      );
      await _mapController!.setMapStyle(style);
    } catch (e) {
      debugPrint('Error setting map style: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    widget.onMapCreated(controller);
    _setMapStyle();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _setMapStyle();
    final isDarkMode = AppTheme.isDarkMode(context);

    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Container(
          decoration: AppTheme.elevatedCard(isDark: isDarkMode),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              _buildMapSection(context),
              if (_isExpanded) _buildExpandedInfo(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLocationIcon(context),
          const SizedBox(width: 14),
          Expanded(child: _buildLocationInfo(context)),
          const SizedBox(width: 10),
          _buildRefreshButton(context),
        ],
      ),
    );
  }

  Widget _buildLocationIcon(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Widget _buildLocationInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildStatusIndicator(context),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.isInOfficeArea
                    ? "location.in_radius_ppkd".tr()
                    : "location.out_radius_ppkd".tr(),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: widget.isInOfficeArea
                      ? AppTheme.getStatusColor('present')
                      : AppTheme.getStatusColor('late'),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.currentAddress,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: AppTheme.getTextPrimaryColor(context),
            letterSpacing: -0.1,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final color = widget.isInOfficeArea
        ? AppTheme.getStatusColor('present')
        : AppTheme.getStatusColor('late');
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 6,
            spreadRadius: 1.5,
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(color: theme.colorScheme.outline, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoadingLocation ? null : widget.onRefreshLocation,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: widget.isLoadingLocation
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return ClipRRect(
      borderRadius: _isExpanded
          ? BorderRadius.zero
          : const BorderRadius.only(
              bottomLeft: Radius.circular(AppTheme.radius28),
              bottomRight: Radius.circular(AppTheme.radius28),
            ),
      child: AnimatedBuilder(
        animation: _heightAnimation,
        builder: (context, child) {
          return SizedBox(
            height: _heightAnimation.value,
            child: Stack(
              children: [_buildGoogleMap(), _buildMapOverlay(context)],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: widget.officeLocation,
        zoom: 16.5,
      ),
      markers: widget.markers,
      circles: widget.officeCircle != null ? {widget.officeCircle!} : {},
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: _isExpanded,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      mapType: _currentMapType,
    );
  }

  Widget _buildMapOverlay(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildMapTypeSelector(context),
              const SizedBox(height: 12),
              _buildZoomControls(context),
            ],
          ),
        ),
        Positioned(bottom: 16, left: 16, child: _buildExpandButton(context)),
      ],
    );
  }

  Widget _buildMapTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius20),
        border: Border.all(color: theme.colorScheme.outline, width: 1.5),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: PopupMenuButton<MapType>(
        tooltip: "Ubah Jenis Peta",
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius16),
        ),
        color: theme.cardColor,
        elevation: 12,
        offset: const Offset(-8, 48),
        onSelected: (type) => setState(() => _currentMapType = type),
        itemBuilder: (context) => [
          _buildMapTypeMenuItem(
            MapType.normal,
            'Normal',
            Icons.map_outlined,
            context,
          ),
          _buildMapTypeMenuItem(
            MapType.satellite,
            'Satelit',
            Icons.satellite_alt,
            context,
          ),
          _buildMapTypeMenuItem(
            MapType.terrain,
            'Medan',
            Icons.terrain,
            context,
          ),
          _buildMapTypeMenuItem(
            MapType.hybrid,
            'Hybrid',
            Icons.layers,
            context,
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Icon(
            Icons.layers_rounded,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<MapType> _buildMapTypeMenuItem(
    MapType type,
    String label,
    IconData icon,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final isSelected = _currentMapType == type;

    return PopupMenuItem<MapType>(
      value: type,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radius12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : AppTheme.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : AppTheme.getTextPrimaryColor(context),
                  letterSpacing: -0.1,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius20),
        border: Border.all(color: theme.colorScheme.outline, width: 1.5),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          _buildZoomButton(
            Icons.add_rounded,
            () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
            context,
            isTop: true,
          ),
          Container(height: 1.5, color: theme.colorScheme.outline),
          _buildZoomButton(
            Icons.remove_rounded,
            () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
            context,
            isTop: false,
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(
    IconData icon,
    VoidCallback onPressed,
    BuildContext context, {
    required bool isTop,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(AppTheme.radius20) : Radius.zero,
          bottom:
              isTop ? Radius.zero : const Radius.circular(AppTheme.radius20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
      ),
    );
  }

  Widget _buildExpandButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = AppTheme.isDarkMode(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius20),
        border: Border.all(color: theme.colorScheme.outline, width: 1.5),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpand,
          borderRadius: BorderRadius.circular(AppTheme.radius20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  _isExpanded ? 'Sembunyikan' : 'Detail',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.getTextPrimaryColor(context),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedInfo(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppTheme.radius28),
              bottomRight: Radius.circular(AppTheme.radius28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Lokasi',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getTextPrimaryColor(context),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow(
                Icons.pin_drop_outlined,
                'Koordinat',
                '${widget.officeLocation.latitude.toStringAsFixed(6)}, ${widget.officeLocation.longitude.toStringAsFixed(6)}',
                context,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.access_time_rounded,
                'Terakhir Diperbarui',
                DateFormat('HH:mm, dd MMM yyyy').format(DateTime.now()),
                context,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.location_searching_rounded,
                'Akurasi',
                'Tinggi (GPS Aktif)',
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radius12),
            border: Border.all(color: theme.colorScheme.outline, width: 1),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppTheme.getTextSecondaryColor(context),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimaryColor(context),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
