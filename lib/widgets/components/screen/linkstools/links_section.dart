// lib/widgets/components/screen/linkstools/links_section.dart
import 'package:flutter/material.dart';
import 'package:suxingchahui/models/linkstools/site_link.dart';
import 'package:suxingchahui/providers/inputs/input_state_provider.dart';
import 'package:suxingchahui/services/main/linktool/link_tool_service.dart';
import 'package:suxingchahui/widgets/components/form/linkform/link_form_dialog.dart';
import 'package:suxingchahui/widgets/ui/animation/animated_sliver_list.dart';
import 'package:suxingchahui/widgets/ui/snackBar/app_snackBar.dart';
import 'link_list_item.dart';

class LinksSection extends StatelessWidget {
  final List<SiteLink> links;
  final bool isAdmin;
  final Function() onRefresh;
  final LinkToolService linkToolService;
  final InputStateService inputStateService;

  const LinksSection({
    super.key,
    required this.links,
    required this.isAdmin,
    required this.onRefresh,
    required this.linkToolService,
    required this.inputStateService,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: AnimatedSliverList<SiteLink>(
        items: links,
        itemBuilder: (context, index, link) {
          return LinkListItem(
            link: link,
            isAdmin: isAdmin,
            onEdit: () => _showEditDialog(context, link),
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, SiteLink link) {
    showDialog(
      context: context,
      builder: (context) => LinkFormDialog(
        link: link,
        inputStateService: inputStateService,
      ),
    ).then((linkData) async {
      if (linkData != null) {
        try {
          await linkToolService.updateLink(SiteLink.fromJson(linkData));
          AppSnackBar.showSuccess('更新链接成功');
          onRefresh();
        } catch (e) {
          AppSnackBar.showError("操作失败,${e.toString()}");
        }
      }
    });
  }
}
