import 'package:flutter/material.dart';

import '../../config/theme_config.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_loader.dart';
import '../../utils/app_logger.dart';
import '../../utils/responsive_utils.dart';

class MattersScreen extends StatefulWidget {
  final bool? isFromFiles;

  const MattersScreen({super.key, required this.isFromFiles});

  @override
  State<MattersScreen> createState() => _MattersScreenState();
}

class _MattersScreenState extends State<MattersScreen> {
  late Future<Map<String, dynamic>> _mattersFuture;

  @override
  void initState() {
    super.initState();
    _mattersFuture = ApiService.getMattersCached();
  }

  void _confirmSelection() {
    if (!AuthService.isMatterSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a matter'),
          backgroundColor: Colors.redAccent.shade400,
        ),
      );
      return;
    }

    if (widget.isFromFiles == true) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
            (route) => false,
        arguments: AuthService.selectedMatterId.toString(),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Matter confirmed!'),
        backgroundColor: ThemeConfig.navyBlue,
      ),
    );

    AppLogger.info('Selected Matter ID: ${AuthService.selectedMatterId}');
  }

  Widget _buildConfirmBar() {
    final hasSelection = AuthService.isMatterSelected;
    final selectedName = AuthService.selectedMatterName;
    final selectedId = AuthService.selectedMatterId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: selection display ──────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: hasSelection
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  'Tap a matter from the list to select it',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            secondChild: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: ThemeConfig.navyBlue.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ThemeConfig.goldenYellow.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: ThemeConfig.goldenYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: ThemeConfig.goldenYellow,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECTED MATTER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedName ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ThemeConfig.navyBlue,
                          ),
                          maxLines: 2,
                        ),
                        if (selectedId != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            'ID: ${selectedId.toString()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF27AE60),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Row 2: confirm button ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: hasSelection ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.goldenYellow,
                disabledBackgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasSelection
                        ? Icons.check_circle_rounded
                        : Icons.touch_app_rounded,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasSelection ? 'Confirm Selection' : 'Select a matter to continue',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Select Matter',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: ThemeConfig.goldenYellow,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: _buildConfirmBar(),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _mattersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: viewportHeight,
                child: const Center(child: AppLoader()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: viewportHeight,
                child: Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data!['data'] == null ||
                snapshot.data!['data']['matters'].isEmpty) {
              return SizedBox(
                height: viewportHeight,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_off_rounded,
                        size: 52,
                        color: Colors.black12,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No matters found.',
                        style: TextStyle(color: Colors.black38, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            }

            final List matters = snapshot.data!['data']['matters'];
            final selectedMatterId = AuthService.selectedMatterId;

            return ListView.builder(
              padding: AppResponsive.pagePadding(context)
                  .copyWith(top: 16, bottom: 100),
              itemCount: matters.length,
              itemBuilder: (context, index) {
                final matter = matters[index];
                final matterId = matter['matter_id'];
                final matterName = matter['matter_name'];
                final isSelected = selectedMatterId == matterId;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppResponsive.maxContentWidth,
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        await AuthService.selectMatter(
                          matterId: matterId,
                          matterName: matterName,
                        );
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ThemeConfig.goldenYellow.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? ThemeConfig.goldenYellow
                                : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ThemeConfig.goldenYellow
                                        .withValues(alpha: 0.18)
                                    : ThemeConfig.navyBlue
                                        .withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.folder_rounded,
                                color: isSelected
                                    ? ThemeConfig.goldenYellow
                                    : ThemeConfig.navyBlue
                                        .withValues(alpha: 0.4),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Name + ID
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    matterName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? ThemeConfig.navyBlue
                                          : ThemeConfig.navyBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'ID: ${matterId.toString()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? ThemeConfig.goldenYellow
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Selection indicator
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      key: ValueKey('selected'),
                                      color: ThemeConfig.goldenYellow,
                                      size: 24,
                                    )
                                  : Icon(
                                      Icons.radio_button_unchecked_rounded,
                                      key: const ValueKey('unselected'),
                                      color: Colors.grey.shade300,
                                      size: 24,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
