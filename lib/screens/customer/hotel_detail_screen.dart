import 'package:flutter/material.dart';

import '../../models/property.dart';
import 'rooms_screen.dart';

/// The Stitch flow combines the property overview and room selection in one
/// focused page.  Keep this route so existing navigation keeps working.
class PropertyDetailScreen extends StatelessWidget {
  const PropertyDetailScreen({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) => RoomsScreen(property: property);
}
