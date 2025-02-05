// lib/widgets/game_form.dart
import 'package:flutter/material.dart';
import '../../models/game.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class GameForm extends StatefulWidget {
  final Game? game;
  final Function(Game) onSubmit;

  const GameForm({
    Key? key,
    this.game,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _GameFormState createState() => _GameFormState();
}

class _GameFormState extends State<GameForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _musicUrlController = TextEditingController();
  String? _coverImageUrl;
  List<String> _gameImages = [];
  List<Map<String, String>> _downloadLinks = [];
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.game != null) {
      _titleController.text = widget.game!.title;
      _summaryController.text = widget.game!.summary;
      _descriptionController.text = widget.game!.description;
      _categoryController.text = widget.game!.category;
      _musicUrlController.text = widget.game!.musicUrl ?? '';
      _coverImageUrl = widget.game!.coverImage;
      _gameImages = List.from(widget.game!.images);
      _downloadLinks = List.from(widget.game!.downloadLinks);
      _rating = widget.game!.rating;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _musicUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // 这里应该实现图片上传到服务器的逻辑
      setState(() {
        _coverImageUrl = image.path;
      });
    }
  }

  Future<void> _pickGameImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      // 这里应该实现图片上传到服务器的逻辑
      setState(() {
        _gameImages.addAll(images.map((image) => image.path));
      });
    }
  }

  void _addDownloadLink() {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final urlController = TextEditingController();

        return AlertDialog(
          title: Text('添加下载链接'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '链接标题',
                  hintText: '例如：官方下载、Steam',
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: '下载链接',
                  hintText: 'https://',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                  setState(() {
                    _downloadLinks.add({
                      'title': titleController.text,
                      'url': urlController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('添加'),
            ),
          ],
        );
      },
    );
  }

  void _removeDownloadLink(int index) {
    setState(() {
      _downloadLinks.removeAt(index);
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final game = Game(
        id: widget.game?.id ?? DateTime.now().toString(), // 临时ID生成方式
        title: _titleController.text,
        summary: _summaryController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        coverImage: _coverImageUrl ?? '',
        images: _gameImages,
        rating: _rating,
        viewCount: widget.game?.viewCount ?? 0,
        createTime: widget.game?.createTime ?? DateTime.now(),
        updateTime: DateTime.now(),
        likeCount: widget.game?.likeCount ?? 0,
        likedBy: widget.game?.likedBy ?? [],
        downloadLinks: _downloadLinks,
        musicUrl: _musicUrlController.text.isEmpty ? null : _musicUrlController.text,
      );

      widget.onSubmit(game);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // 封面图片
          _buildCoverImage(),
          SizedBox(height: 16),

          // 标题
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '游戏标题',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入游戏标题';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // 简介
          TextFormField(
            controller: _summaryController,
            decoration: InputDecoration(
              labelText: '游戏简介',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入游戏简介';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // 详细描述
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: '详细描述',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入详细描述';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // 分类
          TextFormField(
            controller: _categoryController,
            decoration: InputDecoration(
              labelText: '游戏分类',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入游戏分类';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // 音乐链接
          TextFormField(
            controller: _musicUrlController,
            decoration: InputDecoration(
              labelText: '背景音乐链接(可选)',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),

          // 下载链接
          _buildDownloadLinks(),
          SizedBox(height: 16),

          // 评分
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('评分: ${_rating.toStringAsFixed(1)}'),
              Slider(
                value: _rating,
                min: 0,
                max: 10,
                divisions: 100,
                label: _rating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 16),

          // 游戏截图
          _buildGameImages(),
          SizedBox(height: 24),

          // 提交按钮
          ElevatedButton(
            onPressed: _submitForm,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(widget.game == null ? '添加游戏' : '保存修改'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('封面图片'),
        SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _coverImageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _coverImageUrl!,
                  fit: BoxFit.cover,
                ),
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 48),
                    Text('点击上传封面图片'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('游戏截图'),
            TextButton.icon(
              onPressed: _pickGameImages,
              icon: Icon(Icons.add),
              label: Text('添加截图'),
            ),
          ],
        ),
        if (_gameImages.isNotEmpty)
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _gameImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Image.network(
                        _gameImages[index],
                        width: 160,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => setState(() => _gameImages.removeAt(index)),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDownloadLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('下载链接'),
            TextButton.icon(
              onPressed: _addDownloadLink,
              icon: Icon(Icons.add),
              label: Text('添加链接'),
            ),
          ],
        ),
        if (_downloadLinks.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _downloadLinks.length,
            itemBuilder: (context, index) {
              final link = _downloadLinks[index];
              return Card(
                child: ListTile(
                  title: Text(link['title'] ?? ''),
                  subtitle: Text(link['url'] ?? ''),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeDownloadLink(index),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}