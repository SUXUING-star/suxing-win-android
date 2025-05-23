import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:suxingchahui/constants/global_constants.dart';
import 'package:suxingchahui/utils/network/open_web_url_utils.dart';
import 'package:suxingchahui/utils/network/url_utils.dart';
import 'package:suxingchahui/widgets/ui/animation/fade_in_slide_up_item.dart'; // 确保引入动画组件
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_button.dart';
import 'package:suxingchahui/widgets/ui/buttons/url/open_url_button.dart';
import 'package:suxingchahui/widgets/ui/dart/color_extensions.dart';
import 'package:suxingchahui/widgets/ui/dialogs/base_input_dialog.dart';
import 'package:suxingchahui/widgets/ui/snackbar/app_snackbar.dart';
import 'package:suxingchahui/widgets/ui/text/app_text.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _handleOpenLink(
      BuildContext context, String? title, String url) async {
    final validUrl = UrlUtils.getSafeUrl(url);
    OpenWebUrlUtils.showOpenOptions(context, validUrl, title);
  }

  Future<void> _handlerQQGourp(BuildContext context) async {
    await BaseInputDialog.show<bool>(
      // 使用你提供的 BaseInputDialog
      context: context,
      title: "加入 QQ 交流群",
      iconData: Icons.group_add_outlined, // 可以换个更合适的图标
      maxWidth: 320, // 可以根据内容调整宽度
      confirmButtonText: "关闭", // 将确认按钮改为“关闭”
      isDraggable: true,

      // --- 这里构建对话框内容 ---
      contentBuilder: (dialogContext) {
        // dialogContext 用于 SnackBar
        return Column(
          mainAxisSize: MainAxisSize.min, // 让 Column 包裹内容
          crossAxisAlignment: CrossAxisAlignment.center, // 居中对齐
          children: [
            // 1. 显示图片
            ClipRRect(
              // 给图片加个圆角，可选
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                GlobalConstants.qrCodeAssetPath,
                width: 180, // 调整图片大小
                height: 180,
                fit: BoxFit.cover,
                // 添加错误处理，以防图片加载失败
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 180,
                    height: 180,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text(
                        '无法加载二维码',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 2. 显示群号文本
            AppText(
              'QQ群号：$GlobalConstants.groupNumber',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(height: 12),

            // 3. 复制按钮
            FunctionalButton(
              // 使用带边框和图标的按钮
              icon: Icons.copy_rounded,
              iconSize: 18,
              label: '复制群号',

              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: GlobalConstants.groupNumber));
                // 显示提示信息
                AppSnackBar.showSuccess(context, '群号已复制到剪贴板！');
              },
            ),
          ],
        );
      },

      // onConfirm 只需要关闭对话框，返回一个非 null 的 Future 即可
      onConfirm: () async {
        return true; // 返回 true 会让 BaseInputDialog 关闭
      },
      onCancel: null, // 默认行为是关闭对话框
      allowDismissWhenNotProcessing: true, // 允许在非处理状态下点击外部关闭
      barrierDismissible: true, // 允许点击遮罩层关闭
    );
  }

  // 支持部分的构建函数 (保持不变)
  Widget _buildSupportSection(
    BuildContext context, {
    required int delay,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final Color subtitleColor =
        theme.textTheme.bodySmall?.color ?? Colors.grey.shade600;

    return FadeInSlideUpItem(
      delay: Duration(milliseconds: delay),
      child: Card(
        elevation: 1.5,
        margin: const EdgeInsets.only(bottom: 16.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
          onTap: onTap,
          dense: false,
        ),
      ),
    );
  }

  // --- 新增: 构建技术栈的可展开项 ---
  Widget _buildTechStackSection(
    BuildContext context, {
    required int delay,
    required String title,
    required List<Map<String, String>> items,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final Color listTileSubtitleColor =
        theme.textTheme.bodySmall?.color ?? Colors.grey.shade600;

    return FadeInSlideUpItem(
      delay: Duration(milliseconds: delay),
      child: Card(
        elevation: 1.5, // 和 _buildSupportSection 保持一致
        margin:
            const EdgeInsets.only(bottom: 16.0), // 和 _buildSupportSection 保持一致
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12.0)), // 和 _buildSupportSection 保持一致
        // 使用 ClipRRect 来确保 ExpansionTile 展开时的背景色和圆角一致
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          // --- ExpansionTile Header ---
          leading: CircleAvatar(
            // 使用 CircleAvatar 保持风格统一
            backgroundColor: iconColor.withSafeOpacity(0.1),
            foregroundColor: iconColor,
            child: Icon(icon, size: 24),
          ),
          title: AppText(title, fontWeight: FontWeight.bold), // 标题加粗
          // 移除默认的尾部箭头，如果需要自定义可以放在 trailing
          trailing: const Icon(Icons.expand_more),
          // 设置内边距，让头部看起来和 ListTile 类似
          tilePadding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 2.0), // 调整垂直padding让其更紧凑
          // 控制展开和关闭时的背景色和图标颜色
          backgroundColor: theme.cardColor, // 展开时的背景色
          collapsedBackgroundColor: theme.cardColor, // 收起时的背景色
          iconColor: theme.iconTheme.color, // 展开箭头的颜色
          collapsedIconColor: theme.iconTheme.color, // 收起箭头的颜色

          // --- ExpansionTile Content (展开后的内容) ---
          children: <Widget>[
            // 添加一个分隔线，视觉上区分头部和内容
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
            // 使用 Column + ListTile 来展示技术项列表
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0), // 给列表下方加点间距
              child: Column(
                children: items.map((item) {
                  return ListTile(
                    dense: true, // 让列表项更紧凑
                    // 可以选择性地给技术项也加上图标
                    // leading: Icon(Icons.code, size: 20, color: iconColor),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 0), // 调整内边距
                    title: AppText(item['name'] ?? '', fontSize: 14),
                    subtitle: AppText(
                      item['desc'] ?? '',
                      fontSize: 12,
                      color: listTileSubtitleColor,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryColor = theme.primaryColor;
    // 给技术栈定义图标和颜色
    final IconData techStackIcon =
        Icons.build_outlined; // 或者 Icons.memory, Icons.developer_mode 等
    final Color techStackIconColor = Colors.teal.shade400; // 换个颜色区分

    return Scaffold(
      appBar: const CustomAppBar(
        title: '关于宿星茶会',
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // --- 顶部信息卡片 (保持不变) ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      AppText(
                        '关于宿星茶会',
                        style: Theme.of(context).textTheme.titleLarge,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: 8.0),
                      const AppText(
                        '这个app是我完全一个人制作的个人开发项目\n一个专注于分享和交流Galgame的平台，为大家提供游戏下载、评论和交流的空间。',
                        color: Colors.grey,
                        fontSize: 14,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16.0),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Wrap(
                            spacing: 8, // 水平间距
                            runSpacing: 8, // 垂直间距
                            alignment: WrapAlignment.center,
                            children: [
                              SizedBox(
                                width: constraints.maxWidth > 600
                                    ? null
                                    : (constraints.maxWidth - 16) / 3,
                                child: FunctionalButton(
                                  icon: Icons.code,
                                  iconSize: 16,
                                  label: 'GitHub',
                                  onPressed: () => _handleOpenLink(context,
                                      "github仓库", GlobalConstants.githubUrl),
                                ),
                              ),
                              SizedBox(
                                width: constraints.maxWidth > 600
                                    ? null
                                    : (constraints.maxWidth - 16) / 3,
                                child: FunctionalButton(
                                    icon: Icons.message,
                                    iconSize: 16,
                                    label: 'QQ群',
                                    onPressed: () => _handlerQQGourp(context)),
                              ),
                              SizedBox(
                                width: constraints.maxWidth > 600
                                    ? null
                                    : (constraints.maxWidth - 16) / 3,
                                child: FunctionalButton(
                                  icon: Icons.video_library,
                                  iconSize: 16,
                                  label: 'bilibili',
                                  onPressed: () => _handleOpenLink(
                                      context,
                                      "我的b站账号",
                                      GlobalConstants.bUrl), // 这里需要补充b站链接或逻辑
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24.0), // 增加间距

              // --- 支持部分 (保持不变) ---
              _buildSupportSection(
                context,
                delay: 200,
                title: '请杯咖啡 ☕️',
                subtitle: '小额赞助，帮助我们覆盖服务器和开发成本。',
                icon: Icons.coffee_outlined,
                iconColor: Colors.brown.shade400,
                trailing: OpenUrlButton(
                  url: GlobalConstants.donationUrl,
                  tooltip: '打开赞助页面',
                  icon: Icons.open_in_new,
                  color: primaryColor,
                  webViewTitle: '赞助我们',
                ),
              ),
              _buildSupportSection(
                context,
                delay: 400,
                title: '订阅和支持我们的最新服务',
                subtitle: '获取最新的版本和消息。',
                icon: Icons.feedback_outlined,
                iconColor: Colors.green.shade500,
                trailing: OpenUrlButton(
                  url: GlobalConstants.feedbackUrl,
                  tooltip: '前往发布页面',
                  icon: Icons.open_in_new,
                  color: primaryColor,
                  webViewTitle: 'Release页面',
                ),
              ),
              _buildSupportSection(
                context,
                delay: 500,
                title: '参与贡献 (GitHub)',
                subtitle: '欢迎提交代码、报告 Issue 或参与讨论。',
                icon: Icons.code_outlined,
                iconColor: theme.brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.black87,
                trailing: OpenUrlButton(
                  url: GlobalConstants.githubUrl,
                  tooltip: '访问 GitHub 仓库',
                  icon: Icons.open_in_new,
                  color: primaryColor,
                  webViewTitle: 'GitHub 仓库',
                ),
              ),

              const SizedBox(height: 8.0), // 技术栈部分的间距稍微小一点

              // 遍历 techStacks 列表，为每个分类创建一个可展开项
              ...GlobalConstants.techStacks.map((section) {
                // 计算延迟，让它们依次出现
                int index = GlobalConstants.techStacks.indexOf(section);
                int baseDelay = 600; // 基础延迟，接在支持部分之后
                int itemDelay = 100; // 每个技术栈项之间的延迟差
                int currentDelay = baseDelay + (index * itemDelay);

                return _buildTechStackSection(
                  context,
                  delay: currentDelay, // 应用动画延迟
                  title: section['title'] as String,
                  // 需要显式转换类型 List<dynamic> to List<Map<String, String>>
                  items: List<Map<String, String>>.from(
                      (section['items'] as List)
                          .map((item) => Map<String, String>.from(item))),
                  icon: techStackIcon, // 使用统一定义的图标
                  iconColor: techStackIconColor, // 使用统一定义的颜色
                );
              }),

              // 如果 techStacks 为空，可以显示提示信息
              if (GlobalConstants.techStacks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(child: AppText('暂无技术栈信息', color: Colors.grey)),
                ),

              const SizedBox(height: 24.0), // 底部留白
            ],
          ),
        ),
      ),
    );
  }
}
