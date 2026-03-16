import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/audio_guide.dart';
import '../controllers/audio_guide_list_controller.dart';
import '../widgets/audio_guide_tile.dart';
import '../widgets/common_app_bar.dart';
import 'audio_guide_detail_page.dart';

class AudioGuideListPage extends ConsumerStatefulWidget {
  const AudioGuideListPage({super.key});

  @override
  ConsumerState<AudioGuideListPage> createState() => _AudioGuideListPageState();
}

class _AudioGuideListPageState extends ConsumerState<AudioGuideListPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    const threshold = 240.0;
    final position = _scrollController.position;
    final shouldLoadMore =
        position.pixels >= position.maxScrollExtent - threshold;
    if (shouldLoadMore) {
      unawaited(ref.read(audioGuideListControllerProvider.notifier).loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(audioGuideListControllerProvider);
    final controller = ref.read(audioGuideListControllerProvider.notifier);
    return Scaffold(
      appBar: const CommonAppBar(),
      body: Builder(
        builder: (context) {
          if (state.isInitialLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: controller.loadInitial,
                      child: const Text('重新載入'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: controller.loadInitial,
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount:
                        state.items.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final guide = state.items[index];
                      return AudioGuideTile(
                        guide: guide,
                        isDownloading: state.downloadingIds.contains(guide.id),
                        onActionPressed: () => _handleAction(context, guide),
                      );
                    },
                  ),
                ),
                if (state.errorMessage != null && state.items.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: AppColors.errorSurface,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, AudioGuide guide) async {
    if (guide.isDownloaded && guide.localFilePath != null) {
      _openDetail(context, guide);
      return;
    }
    final error = await ref
        .read(audioGuideListControllerProvider.notifier)
        .downloadGuide(guide);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final latestState = ref.read(audioGuideListControllerProvider);
    final latestGuide = latestState.items.firstWhere(
      (item) => item.id == guide.id,
      orElse: () => guide,
    );
    if (latestGuide.localFilePath != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('下載完成')));
    }
  }

  void _openDetail(BuildContext context, AudioGuide guide) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AudioGuideDetailPage(guide: guide),
      ),
    );
  }
}
