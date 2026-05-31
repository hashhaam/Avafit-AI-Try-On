class Brand {
  final String id; // must match backend brand id e.g. 'breakout'
  final String name;
  final String tagline;
  final String imagePath;
  final String websiteUrl; // legacy, no longer used for navigation

  const Brand({
    required this.id,
    required this.name,
    required this.tagline,
    required this.imagePath,
    this.websiteUrl = '',
  });
}
