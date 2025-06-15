// lib/screens/common/about_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/providers/windows/window_state_provider.dart';
import 'package:suxingchahui/utils/device/device_utils.dart';
import 'package:suxingchahui/utils/network/open_web_url_utils.dart';
import 'package:suxingchahui/utils/network/url_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/url/open_url_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/snack_bar/app_snackBar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class AboutScreen extends StatelessWidget {
  final WindowStateProvider windowStateProvider;

  const AboutScreen({
    super.key,
    required this.windowStateProvider,
  });

  // --- 辅助函数部分 (保持不变) ---
  Future<void> _handleOpenLink(
      BuildContext context, String? title, String url) async {
    final validUrl = UrlUtils.getSafeUrl(url);
    OpenWebUrlUtils.showOpenOptions(context, validUrl, title);
  }

  Future<void> _handlerQQGroup(BuildContext context) async {
    await BaseInputDialog.show<bool>(
      context: context,
      title: "加入 QQ 交流群",
      iconData: Icons.group_add_outlined,
      maxWidth: 320,
      confirmButtonText: "关闭",
      isDraggable: true,
      contentBuilder: (dialogContext) => _buildQQDialogContent(),
      onConfirm: () async => true,
    );
  }

  Widget _buildQQDialogContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            GlobalConstants.qrCodeAssetPath,
            width: 180,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 180,
              height: 180,
              color: Colors.grey[200],
              child: const Center(
                child: Text('无法加载二维码',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppText('QQ群号：${GlobalConstants.groupNumber}',
            fontSize: 16, fontWeight: FontWeight.w500),
        const SizedBox(height: 12),
        FunctionalButton(
          icon: Icons.copy_rounded,
          iconSize: 18,
          label: '复制群号',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: GlobalConstants.groupNumber));
            AppSnackBar.showSuccess('群号已复制到剪贴板！');
          },
        ),
      ],
    );
  }

  // --- 组件构建函数 ---

  // 1.【核心修改】构建自适应的顶部信息卡片 (修复渲染错误)
  Widget _buildTopInfoCard(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);

    // 图片组件
    Widget imageContent = ClipRRect(
      borderRadius: isDesktop
          ? const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            )
          : BorderRadius.circular(8.0),
      child: Image.asset(
        GlobalConstants.aboutImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: theme.colorScheme.surfaceVariant,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                  SizedBox(height: 8),
                  AppText('图片加载失败', color: Colors.redAccent),
                ],
              ),
            ),
          );
        },
      ),
    );

    // 文字和按钮组件
    Widget textContent = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
        children: [
          AppText('关于宿星茶会',
              style: theme.textTheme.headlineSmall,
              fontWeight: FontWeight.bold),
          const SizedBox(height: 16.0),
          AppText(
            '这个app是我完全一个人制作的个人开发项目，一个专注于分享和交流Galgame的平台，为大家提供游戏下载、评论和交流的空间。',
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            fontSize: 14,
            textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            children: [
              FunctionalButton(
                  icon: Icons.code,
                  label: 'GitHub',
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  onPressed: () => _handleOpenLink(
                      context, "github仓库", GlobalConstants.githubUrl)),
              FunctionalButton(
                  icon: Icons.message,
                  label: 'QQ群',
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  onPressed: () => _handlerQQGroup(context)),
              FunctionalButton(
                  icon: Icons.video_library,
                  label: 'bilibili',
                  backgroundColor: Colors.pink.shade400,
                  foregroundColor: Colors.white,
                  onPressed: () =>
                      _handleOpenLink(context, "我的b站账号", GlobalConstants.bUrl)),
            ],
          ),
        ],
      ),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: isDesktop
          // 桌面端: 卡片内左右两栏，稳健布局
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  // 【【【【【【 这是关键修复 】】】】】】
                  // 给图片一个SizedBox来约束高度，这样Row就知道自己该多高了
                  child: SizedBox(
                    height: 400, // 给一个固定的高度
                    child: imageContent,
                  ),
                ),
                Expanded(flex: 4, child: textContent),
              ],
            )
          // 移动端: 卡片内上下堆叠
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      AppText('关于宿星茶会',
                          style: theme.textTheme.headlineSmall,
                          fontWeight: FontWeight.bold),
                      const SizedBox(height: 12.0),
                      const AppText(
                        '这个app是我完全一个人制作的个人开发项目\n一个专注于分享和交流Galgame的平台，为大家提供游戏下载、评论和交流的空间。',
                        color: Colors.grey,
                        fontSize: 14,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20.0),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          FunctionalButton(
                              icon: Icons.code,
                              label: 'GitHub',
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              onPressed: () => _handleOpenLink(context,
                                  "github仓库", GlobalConstants.githubUrl)),
                          FunctionalButton(
                              icon: Icons.message,
                              label: 'QQ群',
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              onPressed: () => _handlerQQGroup(context)),
                          FunctionalButton(
                              icon: Icons.video_library,
                              label: 'bilibili',
                              backgroundColor: Colors.pink.shade400,
                              foregroundColor: Colors.white,
                              onPressed: () => _handleOpenLink(
                                  context, "我的b站账号", GlobalConstants.bUrl)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: AspectRatio(aspectRatio: 16 / 9, child: imageContent),
                ),
              ],
            ),
    );
  }

  // 2. 构建 "支持" 部分的卡片列表
  List<Widget> _buildSupportCards(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return [
      _buildSupportCard(context,
          title: '请杯咖啡 ☕️',
          subtitle: '小额赞助，帮助我们覆盖服务器和开发成本。',
          icon: Icons.coffee_outlined,
          iconColor: Colors.brown.shade400,
          trailing: OpenUrlButton(
              url: GlobalConstants.donationUrl,
              webViewTitle: '赞助我们',
              icon: Icons.open_in_new,
              color: primaryColor)),
      _buildSupportCard(context,
          title: '订阅和支持我们的最新服务',
          subtitle: '获取最新的版本和消息。',
          icon: Icons.feedback_outlined,
          iconColor: Colors.green.shade500,
          trailing: OpenUrlButton(
              url: GlobalConstants.feedbackUrl,
              webViewTitle: 'Release页面',
              icon: Icons.open_in_new,
              color: primaryColor)),
      _buildSupportCard(context,
          title: '参与贡献 (GitHub)',
          subtitle: '欢迎提交代码、报告 Issue 或参与讨论。',
          icon: Icons.code_outlined,
          iconColor: theme.brightness == Brightness.dark
              ? Colors.grey.shade400
              : Colors.black87,
          trailing: OpenUrlButton(
              url: GlobalConstants.githubUrl,
              webViewTitle: 'GitHub 仓库',
              icon: Icons.open_in_new,
              color: primaryColor)),
    ];
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget trailing,
  }) {
    final theme = Theme.of(context);
    final subtitleColor =
        theme.textTheme.bodySmall?.color ?? Colors.grey.shade600;
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        leading: CircleAvatar(
          backgroundColor: iconColor.withSafeOpacity(0.1),
          foregroundColor: iconColor,
          child: Icon(icon, size: 24),
        ),
        title: AppText(title, fontWeight: FontWeight.bold),
        subtitle: AppText(subtitle, color: subtitleColor, fontSize: 13),
        trailing: trailing,
      ),
    );
  }

  // 3. 构建 "技术栈" 部分的列表
  Widget _buildTechStackSectionList(BuildContext context,
      {int baseDelay = 500}) {
    final techStackIcon = Icons.build_outlined;
    final techStackIconColor = Colors.teal.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: AppText('所用技术栈',
              style: Theme.of(context).textTheme.titleMedium,
              fontWeight: FontWeight.bold),
        ),
        if (GlobalConstants.techStacks.isEmpty)
          const Center(child: AppText('暂无技术栈信息', color: Colors.grey)),
        ...GlobalConstants.techStacks.map((section) {
          int index = GlobalConstants.techStacks.indexOf(section);
          return FadeInSlideUpItem(
            delay: Duration(milliseconds: baseDelay + (index * 100)),
            child: _buildTechStackCard(
              context,
              title: section['title'] as String,
              items: List<Map<String, String>>.from((section['items'] as List)
                  .map((item) => Map<String, String>.from(item))),
              icon: techStackIcon,
              iconColor: techStackIconColor,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTechStackCard(
    BuildContext context, {
    required String title,
    required List<Map<String, String>> items,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final listTileSubtitleColor =
        theme.textTheme.bodySmall?.color ?? Colors.grey.shade600;
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withSafeOpacity(0.1),
          foregroundColor: iconColor,
          child: Icon(icon, size: 24),
        ),
        title: AppText(title, fontWeight: FontWeight.bold),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
        children: <Widget>[
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              children: items
                  .map((item) => ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 0),
                        title: AppText(item['name'] ?? '', fontSize: 14),
                        subtitle: AppText(item['desc'] ?? '',
                            fontSize: 12, color: listTileSubtitleColor),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = DeviceUtils.isDesktopScreen(context);
    final supportCards = _buildSupportCards(context);

    return Scaffold(
      appBar: const CustomAppBar(title: '关于宿星茶会'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isDesktop
              // --- 桌面端: 两栏布局 ---
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左栏
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Column(
                          children: [
                            FadeInSlideUpItem(
                                delay: const Duration(milliseconds: 200),
                                child: _buildTopInfoCard(context, isDesktop)),
                            const SizedBox(height: 24),
                            _buildTechStackSectionList(context, baseDelay: 400),
                          ],
                        ),
                      ),
                    ),
                    // 右栏
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          children: [
                            FadeInSlideUpItem(
                                delay: const Duration(milliseconds: 300),
                                child: supportCards[0]),
                            const SizedBox(height: 16),
                            FadeInSlideUpItem(
                                delay: const Duration(milliseconds: 400),
                                child: supportCards[1]),
                            const SizedBox(height: 16),
                            FadeInSlideUpItem(
                                delay: const Duration(milliseconds: 500),
                                child: supportCards[2]),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              // --- 移动端: 单列布局 ---
              : Column(
                  children: [
                    FadeInSlideUpItem(
                        delay: const Duration(milliseconds: 200),
                        child: _buildTopInfoCard(context, isDesktop)),
                    const SizedBox(height: 24),
                    FadeInSlideUpItem(
                        delay: const Duration(milliseconds: 400),
                        child: supportCards[0]),
                    const SizedBox(height: 16),
                    FadeInSlideUpItem(
                        delay: const Duration(milliseconds: 500),
                        child: supportCards[1]),
                    const SizedBox(height: 16),
                    FadeInSlideUpItem(
                        delay: const Duration(milliseconds: 600),
                        child: supportCards[2]),
                    const SizedBox(height: 24),
                    _buildTechStackSectionList(context, baseDelay: 700),
                  ],
                ),
        ),
      ),
    );
  }
}
