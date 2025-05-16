// // lib/widgets/player/windows_music_player.dart
// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:provider/provider.dart';
// import 'dart:async';
// import '../../../../../../services/main/audio/audio_service.dart';
// import '../../../../../../models/audio/audio.dart';
//
// class WindowsMusicPlayer extends StatefulWidget {
//   @override
//   _WindowsMusicPlayerState createState() => _WindowsMusicPlayerState();
// }
//
// class _WindowsMusicPlayerState extends State<WindowsMusicPlayer> with WidgetsBindingObserver {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   AudioMetadata? _currentMetadata;
//   bool _isPlaying = false;
//   List<String> _playlist = [];
//   int _currentIndex = -1;
//   bool _isLoading = false;
//   String _errorMessage = '';
//   Duration _duration = Duration.zero;
//   Duration _position = Duration.zero;
//   StreamSubscription? _playerStateSubscription;
//   StreamSubscription? _durationSubscription;
//   StreamSubscription? _positionSubscription;
//   bool _autoPlayEnabled = true;  // 默认启用自动播放
//   int _retryCount = 0;
//   Timer? _retryTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initAudioPlayer();
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // 在依赖更新后加载播放列表
//     _loadPlaylist();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // 应用恢复前台时重新检查播放状态
//     if (state == AppLifecycleState.resumed) {
//       if (_isPlaying && !_audioPlayer.playing) {
//         _audioPlayer.play();
//       }
//     }
//   }
//
//   Future<void> _initAudioPlayer() async {
//     try {
//       print('初始化音频播放器...');
//
//       // 监听播放状态
//       _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
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
//         // 如果出现错误，尝试重新播放
//         if (state.processingState == ProcessingState.idle && _currentMetadata != null) {
//           _handlePlaybackError();
//         }
//       });
//
//       // 监听持续时间
//       _durationSubscription = _audioPlayer.durationStream.listen((d) {
//         if (d != null && mounted) {
//           setState(() {
//             _duration = d;
//           });
//         }
//       });
//
//       // 监听当前位置
//       _positionSubscription = _audioPlayer.positionStream.listen((p) {
//         if (mounted) {
//           setState(() {
//             _position = p;
//           });
//         }
//       });
//
//     } catch (e) {
//       print('初始化音频播放器错误: $e');
//       if (mounted) {
//         setState(() {
//           _errorMessage = '初始化播放器失败: $e';
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
//       // 设置延迟重试
//       _retryTimer = Timer(Duration(seconds: 2), () {
//         if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
//           print('重新尝试播放：${_playlist[_currentIndex]}');
//           _playAudio(_playlist[_currentIndex]);
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
//       print('正在获取音频列表...');
//       final playlist = await audioService.getAudioList();
//
//       print('获取到 ${playlist.length} 首歌曲');
//
//       if (mounted) {
//         setState(() {
//           _playlist = playlist;
//           _isLoading = false;
//
//           // 如果获取到播放列表且启用了自动播放，自动播放第一首
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
//           _errorMessage = '加载播放列表失败: $e';
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
//   Future<void> _playAudio(String objectName) async {
//     if (_isLoading) return;
//
//     print('准备播放: $objectName');
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//       _retryCount = 0;
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
//       // 设置新的URL
//       await _audioPlayer.setUrl(url);
//
//       // 自动播放
//       if (_autoPlayEnabled) {
//         print('音频源设置成功，正在播放...');
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
//         _handlePlaybackError();
//       }
//     }
//   }
//
//   void _playNext() {
//     if (_playlist.isEmpty) return;
//
//     final nextIndex = (_currentIndex + 1) % _playlist.length;
//     _currentIndex = nextIndex;
//
//     print('播放下一首: $_currentIndex - ${_playlist[nextIndex]}');
//     _playAudio(_playlist[nextIndex]);
//   }
//
//   void _playPrevious() {
//     if (_playlist.isEmpty) return;
//
//     final prevIndex = _currentIndex <= 0 ? _playlist.length - 1 : _currentIndex - 1;
//     _currentIndex = prevIndex;
//
//     print('播放上一首: $_currentIndex - ${_playlist[prevIndex]}');
//     _playAudio(_playlist[prevIndex]);
//   }
//
//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$minutes:$seconds";
//   }
//
//   void _toggleAutoPlay() {
//     setState(() {
//       _autoPlayEnabled = !_autoPlayEnabled;
//     });
//     print('自动播放已${_autoPlayEnabled ? '启用' : '禁用'}');
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _playerStateSubscription?.cancel();
//     _durationSubscription?.cancel();
//     _positionSubscription?.cancel();
//     _retryTimer?.cancel();
//     _audioPlayer.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: 160,
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withSafeOpacity(0.1),
//             blurRadius: 8,
//             offset: Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // 播放器控制区
//           Row(
//             children: [
//               // 当前歌曲信息
//               Expanded(
//                 flex: 3,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _currentMetadata?.title ?? '未选择歌曲',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       _currentMetadata?.artist ?? '',
//                       style: TextStyle(
//                         color: Colors.grey[700],
//                         fontSize: 14,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       _currentMetadata?.album ?? '',
//                       style: TextStyle(
//                         color: Colors.grey[500],
//                         fontSize: 12,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//
//               // 播放控制按钮
//               Expanded(
//                 flex: 4,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     IconButton(
//                       icon: Icon(Icons.skip_previous),
//                       iconSize: 32,
//                       onPressed: _playPrevious,
//                     ),
//                     SizedBox(width: 8),
//                     _isLoading
//                         ? Container(
//                       width: 48,
//                       height: 48,
//                       padding: EdgeInsets.all(4),
//                       child: CircularProgressIndicator(),
//                     )
//                         : IconButton(
//                       icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
//                       iconSize: 48,
//                       onPressed: () {
//                         if (_isPlaying) {
//                           _audioPlayer.pause();
//                         } else {
//                           _audioPlayer.play();
//                         }
//                       },
//                     ),
//                     SizedBox(width: 8),
//                     IconButton(
//                       icon: Icon(Icons.skip_next),
//                       iconSize: 32,
//                       onPressed: _playNext,
//                     ),
//                     SizedBox(width: 8),
//                     IconButton(
//                       icon: Icon(_autoPlayEnabled ? Icons.repeat : Icons.repeat_one),
//                       color: _autoPlayEnabled ? Theme.of(context).primaryColor : Colors.grey,
//                       onPressed: _toggleAutoPlay,
//                       tooltip: _autoPlayEnabled ? '自动播放已启用' : '自动播放已禁用',
//                     ),
//                   ],
//                 ),
//               ),
//
//               // 音量控制
//               Expanded(
//                 flex: 3,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Icon(Icons.volume_down),
//                     Expanded(
//                       child: Slider(
//                         value: _audioPlayer.volume,
//                         min: 0,
//                         max: 1,
//                         onChanged: (value) {
//                           setState(() {
//                             _audioPlayer.setVolume(value);
//                           });
//                         },
//                       ),
//                     ),
//                     Icon(Icons.volume_up),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//
//           SizedBox(height: 8),
//
//           // 进度条
//           Row(
//             children: [
//               Text(_formatDuration(_position)),
//               Expanded(
//                 child: Slider(
//                   value: _position.inSeconds.toDouble(),
//                   min: 0,
//                   max: _duration.inSeconds.toDouble() == 0 ? 1 : _duration.inSeconds.toDouble(),
//                   onChanged: (value) {
//                     _audioPlayer.seek(Duration(seconds: value.toInt()));
//                   },
//                 ),
//               ),
//               Text(_formatDuration(_duration)),
//             ],
//           ),
//
//           // 错误消息
//           if (_errorMessage.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Text(
//                 _errorMessage,
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }