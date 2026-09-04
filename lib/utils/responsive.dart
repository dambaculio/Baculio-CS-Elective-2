/// Centralized breakpoints — the "Responsive & Adaptive Design" PDF's
/// rule: define breakpoints ONCE and have every screen read from this
/// same source of truth, instead of scattering magic numbers.
enum DeviceType { compact, medium, expanded, large }

/// Material 3 window size classes, straight from the slides:
///   compact  < 600dp    -> phones (portrait)
///   medium   600-839dp  -> tablets, foldables
///   expanded 840-1199dp -> small desktop / split-view
///   large    >= 1200dp  -> desktop, large tablets
DeviceType deviceTypeOf(double width) {
  if (width < 600) return DeviceType.compact;
  if (width < 840) return DeviceType.medium;
  if (width < 1200) return DeviceType.expanded;
  return DeviceType.large;
}

/// How many grid columns to show for each device class.
/// Phones get 2, tablets and up get 3+ (per the design spec).
int gridColumnsFor(DeviceType type) {
  switch (type) {
    case DeviceType.compact:
      return 2;
    case DeviceType.medium:
      return 3;
    case DeviceType.expanded:
      return 3;
    case DeviceType.large:
      return 5;
  }
}