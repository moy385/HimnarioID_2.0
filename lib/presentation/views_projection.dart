/// Barrel file para vistas de proyección (views_projection).
///
/// Exporta los widgets de las pantallas de proyección y control
/// para facilitar la importación desde otros módulos.
library views_projection;

// Controller (remote control panel)
export 'views_projection/controller/live_control_screen.dart';
export 'views_projection/controller/widgets/discover_display_sheet.dart';

// Display (projection / receiver)
export 'views_projection/display/receptor_binding.dart';
export 'views_projection/display/standby_screen.dart';
export 'views_projection/display/live_projection_screen.dart';
export 'views_projection/display/widgets/keyboard_handler.dart';
