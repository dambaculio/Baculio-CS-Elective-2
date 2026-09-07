
enum DeviceType { compact, medium, expanded, large }


DeviceType deviceTypeOf(double width) {
  if (width < 600) return DeviceType.compact;
  if (width < 840) return DeviceType.medium;
  if (width < 1200) return DeviceType.expanded;
  return DeviceType.large;
}

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