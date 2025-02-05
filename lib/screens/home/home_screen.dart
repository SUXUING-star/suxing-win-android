// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/home/home_hot.dart'; // 引入 HomeHot
import '../../widgets/home/home_latest.dart'; // 引入 HomeLatest

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('宿星茶会'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // 实现搜索功能
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 实现下拉刷新
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildBanner(),
              HomeHot(), // 使用 HomeHot 组件
              HomeLatest(), // 使用 HomeLatest 组件
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      height: 200,
      width: double.infinity,
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                'https://galshare.oss-cn-beijing.aliyuncs.com/home/kaev_02l_9.jpg',
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}