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
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _heightAnimation = Tween<double>(begin: 260, end: 420).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
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

    return Container(
      decoration: AppTheme.elevatedCard(isDark: isDarkMode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, isDarkMode),
          _buildMapSection(context),
          if (_isExpanded) _buildExpandedInfo(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Row(
        children: [
          _buildStatusBadge(context, isDarkMode),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(child: _buildLocationInfo(context, isDarkMode)),
          const SizedBox(width: AppTheme.spacing12),
          _buildRefreshButton(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isDarkMode) {
    final statusColor = widget.isInOfficeArea
        ? AppTheme.getStatusColor('present')
        : AppTheme.getStatusColor('late');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.location_on_rounded,
        color: statusColor,
        size: 20,
      ),
    );
  }

  Widget _buildLocationInfo(BuildContext context, bool isDarkMode) {
    final statusColor = widget.isInOfficeArea
        ? AppTheme.getStatusColor('present')
        : AppTheme.getStatusColor('late');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.isInOfficeArea
              ? "location.in_radius_ppkd".tr()
              : "location.out_radius_ppkd".tr(),
          style: GoogleFonts.manrope(
            fontSize: 11,
            color: statusColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.currentAddress,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: AppTheme.getTextPrimaryColor(context),
            letterSpacing: -0.1,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRefreshButton(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
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
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    color: theme.colorScheme.primary,
                    size: 16,
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
              bottomLeft: Radius.circular(AppTheme.radius16),
              bottomRight: Radius.circular(AppTheme.radius16),
            ),
      child: AnimatedBuilder(
        animation: _heightAnimation,
        builder: (context, child) {
          return SizedBox(
            height: _heightAnimation.value,
            child: Stack(
              children: [
                _buildGoogleMap(),
                _buildMapControls(context),
              ],
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

  Widget _buildMapControls(BuildContext context) {
    final isDarkMode = AppTheme.isDarkMode(context);
    return Stack(
      children: [
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              _buildMapTypeButton(context, isDarkMode),
              const SizedBox(height: AppTheme.spacing8),
              _buildZoomControls(context, isDarkMode),
            ],
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: _buildExpandButton(context, isDarkMode),
        ),
      ],
    );
  }

  Widget _buildMapTypeButton(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: PopupMenuButton<MapType>(
        tooltip: "Ubah Jenis Peta",
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius12),
        ),
        color: theme.cardColor,
        elevation: 8,
        offset: const Offset(-8, 40),
        onSelected: (type) => setState(() => _currentMapType = type),
        itemBuilder: (context) => [
          _buildMapTypeItem(MapType.normal, 'Normal', Icons.map_outlined),
          _buildMapTypeItem(MapType.satellite, 'Satelit', Icons.satellite_alt),
          _buildMapTypeItem(MapType.terrain, 'Medan', Icons.terrain),
          _buildMapTypeItem(MapType.hybrid, 'Hybrid', Icons.layers),
        ],
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.layers_rounded,
            color: theme.colorScheme.primary,
            size: 18,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<MapType> _buildMapTypeItem(
    MapType type,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = _currentMapType == type;
    final isDarkMode = AppTheme.isDarkMode(context);

    return PopupMenuItem<MapType>(
      value: type,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? theme.colorScheme.primary
                : AppTheme.getTextSecondaryColor(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
                color: isSelected
                    ? theme.colorScheme.primary
                    : AppTheme.getTextPrimaryColor(context),
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 16,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildZoomButton(
            Icons.add,
            () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
            theme,
            isTop: true,
          ),
          Container(
            height: 1,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
          _buildZoomButton(
            Icons.remove,
            () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
            theme,
            isTop: false,
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(
    IconData icon,
    VoidCallback onPressed,
    ThemeData theme, {
    required bool isTop,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(AppTheme.radius12) : Radius.zero,
          bottom:
              isTop ? Radius.zero : const Radius.circular(AppTheme.radius12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandButton(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppTheme.radius12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpand,
          borderRadius: BorderRadius.circular(AppTheme.radius12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _isExpanded ? 'Tutup' : 'Detail',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedInfo(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppTheme.radius16),
            bottomRight: Radius.circular(AppTheme.radius16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Lokasi',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildInfoRow(
              Icons.pin_drop_outlined,
              'Koordinat',
              '${widget.officeLocation.latitude.toStringAsFixed(6)}, ${widget.officeLocation.longitude.toStringAsFixed(6)}',
              context,
              isDarkMode,
            ),
            const SizedBox(height: AppTheme.spacing12),
            _buildInfoRow(
              Icons.access_time_rounded,
              'Terakhir Diperbarui',
              DateFormat('HH:mm, dd MMM yyyy').format(DateTime.now()),
              context,
              isDarkMode,
            ),
            const SizedBox(height: AppTheme.spacing12),
            _buildInfoRow(
              Icons.location_searching_rounded,
              'Akurasi',
              'Tinggi (GPS Aktif)',
              context,
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    BuildContext context,
    bool isDarkMode,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radius8),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppTheme.getTextSecondaryColor(context),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextPrimaryColor(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
