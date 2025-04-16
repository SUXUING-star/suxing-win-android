import 'package:flutter/material.dart';
import 'package:suxingchahui/utils/navigation/navigation_utils.dart';
import 'package:suxingchahui/widgets/ui/appbar/custom_app_bar.dart';
import 'package:suxingchahui/widgets/ui/buttons/functional_text_button.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '404 - Page Not Found',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                '你来到了一个不存在的地方',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              const Text(
                '您访问的页面似乎不存在。请检查URL地址是否正确，或者返回主页。',
                style: TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              FunctionalTextButton(
                onPressed: () {
                  NavigationUtils.navigateToHome(context);
                },
                label: '返回主页'
              ),
            ],
          ),
        ),
      ),
    );
  }
}