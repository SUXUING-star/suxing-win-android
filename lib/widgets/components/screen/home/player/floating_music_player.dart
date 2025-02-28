// // lib/widgets/components/player/floating_music_player.dart
// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:provider/provider.dart';
// import 'dart:async';
// import '../../../../../services/main/audio/audio_service.dart';
// import '../../../../../models/audio/audio.dart';
//
// class FloatingMusicPlayer extends StatefulWidget {
//   @override
//   _FloatingMusicPlayerState createState() => _FloatingMusicPlayerState();
// }
//
// class _FloatingMusicPlayerState extends State<FloatingMusicPlayer> with WidgetsBindingObserver {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   AudioMetadata? _currentMetadata;
//   bool _isPlaying = false;
//   bool _isExpanded = false;
//   List<String> _playlist = [];
//   int _currentIndex = -1;
//   bool _isLoading = false;
//   String _errorMessage = '';
//   int _retryCount = 0;
//   Timer? _retryTimer;
//   bool _autoPlayEnabled = true;
//   bool _isBuffering = false;
//   bool _isInitializing = true;
//   Duration _bufferTime = Duration(seconds: 3); // 增加缓冲时间
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initPlayer();
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // 确保在状态初始化后加载播放列表
//     if (_isInitializing) {
//       _isInitializing = false;
//       _loadPlaylist();
//     }
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // 应用恢复前台时检查播放状态
//     if (state == AppLifecycleState.resumed) {
//       if (_isPlaying && !_audioPlayer.playing) {
//         _audioPlayer.play();
//       }
//     } else if (state == AppLifecycleState.paused) {
//       // 应用进入后台时暂停播放，避免资源浪费
//       if (_audioPlayer.playing) {
//         _audioPlayer.pause();
//       }
//     }
//   }
//
//   Future<void> _initPlayer() async {
//     try {
//       print('初始化浮动音乐播放器...');
//
//       // 设置音频缓冲配置
//       await _audioPlayer.setAutomaticallyWaitsToMinimizeStalling(true);
//
//       // 增加监听项
//       _audioPlayer.processingStateStream.listen((state) {
//         print('处理状态变化: $state');
//         if (mounted) {
//           setState(() {
//             _isBuffering = state == ProcessingState.buffering;
//           });
//         }
//       });
//
//       // 错误流监听
//       _audioPlayer.playerStateStream.listen((state) {
//         print('播放状态更新: ${state.playing}, ${state.processingState}');
//
//         if (mounted) {
//           setState(() {
//             _isPlaying = state.playing;
//           });
//         }
//
//         // 当前歌曲结束，自动播放下一首
//         if (state.processingState == ProcessingState.completed && _autoPlayEnabled) {
//           print('当前歌曲播放完成，自动播放下一首');
//           _playNext();
//         }
//
//         // 处理播放失败的情况，但不要对缓冲状态误判为错误
//         if (state.processingState == ProcessingState.idle &&
//             _currentMetadata != null &&
//             !_isBuffering) {
//           _handlePlaybackError();
//         }
//       });
//
//       // 监听播放位置变化，作为播放成功的额外确认
//       _audioPlayer.positionStream.listen((position) {
//         // 如果播放超过3秒，重置重试计数器，表示播放成功
//         if (position.inSeconds > 3 && _retryCount > 0) {
//           print('播放已稳定，重置重试计数器');
//           _retryCount = 0;
//         }
//       });
//
//     } catch (e) {
//       print('初始化播放器错误: $e');
//       if (mounted) {
//         setState(() {
//           _errorMessage = '初始化失败: $e';
//         });
//       }
//     }
//   }
//
//   void _handlePlaybackError() {
//     if (_retryCount < 3) {
//       print('播放出错，准备重试 (${_retryCount + 1}/3)...');
//       _retryCount++;
//
//       // 取消之前的重试计时器
//       _retryTimer?.cancel();
//
//       // 设置增加延迟的重试，每次重试增加等待时间
//       _retryTimer = Timer(Duration(seconds: 2 * _retryCount), () {
//         if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
//           print('重新尝试播放：${_playlist[_currentIndex]}');
//           _playAudio(_playlist[_currentIndex], forceReload: true);
//         }
//       });
//     } else {
//       print('多次重试失败，跳到下一首');
//       _retryCount = 0;
//       _playNext();
//     }
//   }
//
//   Future<void> _loadPlaylist() async {
//     if (_isLoading) return;
//
//     print('开始加载播放列表...');
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });
//
//     try {
//       final audioService = Provider.of<AudioService>(context, listen: false);
//       print('从服务获取音频列表...');
//       final playlist = await audioService.getAudioList();
//
//       print('获取到 ${playlist.length} 首歌曲');
//
//       if (mounted) {
//         setState(() {
//           _playlist = playlist;
//           _isLoading = false;
//
//           // 如果获取到播放列表且当前未选中任何歌曲，自动播放第一首
//           if (playlist.isNotEmpty && _currentIndex == -1 && _autoPlayEnabled) {
//             print('自动播放第一首歌曲');
//             _currentIndex = 0;
//             _playAudio(playlist[0]);
//           }
//         });
//       }
//     } catch (e) {
//       print('加载播放列表错误: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = '加载失败: $e';
//         });
//
//         // 5秒后重试
//         Timer(Duration(seconds: 5), () {
//           if (mounted) {
//             print('重试加载播放列表');
//             _loadPlaylist();
//           }
//         });
//       }
//     }
//   }
//
//   // 添加播放控制方法
//   void _playNext() {
//     if (_playlist.isEmpty) return;
//     final nextIndex = (_currentIndex + 1) % _playlist.length;
//     print('播放下一首: $nextIndex - ${_playlist[nextIndex]}');
//     setState(() {
//       _currentIndex = nextIndex;
//       _retryCount = 0; // 重置重试计数器
//     });
//     _playAudio(_playlist[nextIndex]);
//   }
//
//   void _playPrevious() {
//     if (_playlist.isEmpty) return;
//     final prevIndex = _currentIndex <= 0 ? _playlist.length - 1 : _currentIndex - 1;
//     print('播放上一首: $prevIndex - ${_playlist[prevIndex]}');
//     setState(() {
//       _currentIndex = prevIndex;
//       _retryCount = 0; // 重置重试计数器
//     });
//     _playAudio(_playlist[prevIndex]);
//   }
//
//   Future<void> _playAudio(String objectName, {bool forceReload = false}) async {
//     if (_isLoading && !forceReload) return;
//
//     print('准备播放: $objectName');
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//       if (!forceReload) {
//         _retryCount = 0;
//       }
//     });
//
//     try {
//       final audioService = Provider.of<AudioService>(context, listen: false);
//       print('正在获取元数据: $objectName');
//       final metadata = await audioService.getMetadata(objectName);
//       final url = audioService.getAudioUrl(objectName);
//
//       print('正在设置音频源: $url');
//
//       // 先停止当前播放
//       await _audioPlayer.stop();
//
//       // 预先设置一个较长的缓冲时间
//       await Future.delayed(_bufferTime);
//
//       // 设置新的URL
//       await _audioPlayer.setUrl(url);
//
//       // 增加一个短暂的延迟，让缓冲有时间进行
//       await Future.delayed(Duration(milliseconds: 500));
//
//       // 根据自动播放设置决定是否播放
//       if (_autoPlayEnabled) {
//         print('音频源设置成功，开始播放...');
//         await _audioPlayer.play();
//       }
//
//       if (mounted) {
//         setState(() {
//           _currentMetadata = metadata;
//           _isPlaying = _autoPlayEnabled;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print('播放音频错误: $e');
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = '播放失败: $e';
//         });
//
//         if (!forceReload) {
//           _handlePlaybackError();
//         }
//       }
//     }
//   }
//
//   Widget _buildCollapsedPlayer() {
//     return GestureDetector(
//       onTap: () => setState(() => _isExpanded = true),
//       child: Container(
//         width: 60,
//         height: 60,
//         decoration: BoxDecoration(
//           color: _errorMessage.isNotEmpty
//               ? Colors.red
//               : (_isLoading ? Colors.orange : Theme.of(context).primaryColor),
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black26,
//               blurRadius: 10,
//               spreadRadius: 2,
//             ),
//           ],
//         ),
//         child: _isLoading
//             ? Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
//             : Icon(
//           _isPlaying ? Icons.pause : Icons.play_arrow,
//           color: Colors.white,
//           size: 30,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildExpandedPlayer() {
//     return Container(
//       width: 300,
//       padding: EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: Theme.of(context).primaryColor,
//         borderRadius: BorderRadius.circular(40),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black26,
//             blurRadius: 10,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (_errorMessage.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//               child: Text(
//                 _errorMessage,
//                 style: TextStyle(color: Colors.red.shade100, fontSize: 10),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           Row(
//             children: [
//               IconButton(
//                 icon: Icon(Icons.keyboard_arrow_left, color: Colors.white),
//                 onPressed: () => setState(() => _isExpanded = false),
//               ),
//               IconButton(
//                 icon: Icon(Icons.skip_previous, color: Colors.white),
//                 onPressed: _playPrevious,
//               ),
//               Expanded(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _currentMetadata?.title ?? '未选择歌曲',
//                       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     SizedBox(height: 2),
//                     Text(
//                       _currentMetadata?.artist ?? '',
//                       style: TextStyle(color: Colors.white70),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//               _isLoading || _isBuffering
//                   ? Container(
//                 width: 32,
//                 height: 32,
//                 padding: EdgeInsets.all(4),
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//                   : IconButton(
//                 icon: Icon(
//                   _isPlaying ? Icons.pause : Icons.play_arrow,
//                   color: Colors.white,
//                 ),
//                 onPressed: () {
//                   if (_isPlaying) {
//                     _audioPlayer.pause();
//                   } else {
//                     _audioPlayer.play();
//                   }
//                 },
//               ),
//               IconButton(
//                 icon: Icon(Icons.skip_next, color: Colors.white),
//                 onPressed: _playNext,
//               ),
//               IconButton(
//                 icon: Icon(
//                   _autoPlayEnabled ? Icons.repeat : Icons.repeat_one,
//                   color: Colors.white.withOpacity(_autoPlayEnabled ? 1.0 : 0.5),
//                   size: 20,
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _autoPlayEnabled = !_autoPlayEnabled;
//                   });
//                   print('自动播放已${_autoPlayEnabled ? '启用' : '禁用'}');
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _retryTimer?.cancel();
//     _audioPlayer.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       left: 16,
//       top: MediaQuery.of(context).size.height / 2 - 30,
//       child: _isExpanded ? _buildExpandedPlayer() : _buildCollapsedPlayer(),
//     );
//   }
// }