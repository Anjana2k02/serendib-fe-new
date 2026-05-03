import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../models/artifact.dart';

class CategoryArtifactsSheet extends StatefulWidget {
  final String category;
  final List<Artifact> artifacts;

  const CategoryArtifactsSheet({
    super.key,
    required this.category,
    required this.artifacts,
  });

  @override
  State<CategoryArtifactsSheet> createState() => _CategoryArtifactsSheetState();
}

class _CategoryArtifactsSheetState extends State<CategoryArtifactsSheet> {
  final DraggableScrollableController _controller =
      DraggableScrollableController();

  double _arrowRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSheetSizeChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSheetSizeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSheetSizeChanged() {
    if (!_controller.isAttached) return;
    final size = _controller.size;
    // Rotate arrow from 0 (pointing up at 0.3) to 0.5 turns (pointing down at 0.75)
    final rotation = ((size - 0.3) / (0.75 - 0.3)).clamp(0.0, 1.0) * 0.5;
    if ((rotation - _arrowRotation).abs() > 0.01) {
      setState(() => _arrowRotation = rotation);
    }
  }

  void _toggleExpand() {
    if (!_controller.isAttached) return;
    final isExpanded = _controller.size >= 0.6;
    _controller.animateTo(
      isExpanded ? 0.3 : 0.75,
      duration: AppConstants.animationNormal,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.75,
      snap: true,
      snapSizes: const [0.3, 0.75],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusLg),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x334A2C1A),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar + expand arrow
              GestureDetector(
                onTap: _toggleExpand,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingSm,
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      // Expand/collapse arrow
                      AnimatedRotation(
                        turns: _arrowRotation,
                        duration: AppConstants.animationFast,
                        child: const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: AppColors.primaryBrown,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingLg,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacingSm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBrown.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusSm),
                      ),
                      child: const Icon(
                        Icons.category_outlined,
                        color: AppColors.primaryBrown,
                        size: AppConstants.iconSizeMd,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: AppColors.darkBrown,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${widget.artifacts.length} artifact${widget.artifacts.length == 1 ? '' : 's'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // Divider
              Divider(
                color: AppColors.lightCream,
                height: 1,
                indent: AppConstants.spacingLg,
                endIndent: AppConstants.spacingLg,
              ),

              // Artifact cards list
              Expanded(
                child: widget.artifacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.museum_outlined,
                              size: 48,
                              color: AppColors.textSecondary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            Text(
                              'No artifacts in this category',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMd,
                          vertical: AppConstants.spacingSm,
                        ),
                        itemCount: widget.artifacts.length,
                        itemBuilder: (context, index) {
                          return _CategoryArtifactCard(
                            artifact: widget.artifacts[index],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryArtifactCard extends StatelessWidget {
  final Artifact artifact;

  const _CategoryArtifactCard({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSm),
      elevation: AppConstants.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      color: AppColors.creamWhite,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/artifacts/detail',
            arguments: artifact,
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryBrown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(
                    color: AppColors.primaryBrown.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.museum,
                  color: AppColors.primaryBrown,
                  size: 36,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBrown,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    if (artifact.description != null &&
                        artifact.description!.isNotEmpty)
                      Text(
                        artifact.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'No description available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    if (artifact.isOnDisplay) ...[
                      const SizedBox(height: AppConstants.spacingXs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingSm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusSm),
                        ),
                        child: Text(
                          'On Display',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: AppConstants.iconSizeMd,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showCategoryArtifactsSheet(
  BuildContext context,
  String category,
  List<Artifact> artifacts,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => CategoryArtifactsSheet(
      category: category,
      artifacts: artifacts,
    ),
  );
}
