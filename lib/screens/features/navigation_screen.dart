import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/map_navigation_provider.dart';
import '../../providers/activity_provider.dart';
import '../../widgets/navigation/interactive_map_viewer.dart';
import '../../widgets/navigation/poi_search_bar.dart';
import '../../widgets/navigation/route_instructions.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  @override
  void initState() {
    super.initState();
    // Start activity recognition when map screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityProvider = context.read<ActivityProvider>();
      activityProvider.start();
    });
  }

  @override
  void dispose() {
    // Stop activity recognition when leaving map screen
    context.read<ActivityProvider>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MapNavigationProvider()..loadMapData(),
      child: Scaffold(
        backgroundColor: AppColors.offWhite,
        appBar: AppBar(
          title: const Text('Indoor Navigation'),
          actions: [
            Consumer<MapNavigationProvider>(
              builder: (context, provider, child) {
                if (provider.activeRoute != null) {
                  return IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear Route',
                    onPressed: () {
                      provider.clearRoute();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Consumer<MapNavigationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryBrown,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading map...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Map',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          provider.loadMapData();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const Stack(
              children: [
                InteractiveMapViewer(),
                POISearchBar(),
                RouteInstructions(),
              ],
            );
          },
        ),
      ),
    );
  }
}
