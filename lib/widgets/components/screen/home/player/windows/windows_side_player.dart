// // lib/widgets/components/player/windows_side_player.dart
// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:provider/provider.dart';
// import 'dart:async';
// import '../../../../../../services/main/audio/audio_service.dart';
// import '../../../../../../models/audio/audio.dart';
//
// class WindowsSidePlayer extends StatefulWidget {
//   @override
//   _WindowsSidePlayerState createState() => _WindowsSidePlayerState();
// }
//
// class _WindowsSidePlayerState extends State<WindowsSidePlayer> with WidgetsBindingObserver {
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
//   double _volume = 0.7;  // 默认音量 70%
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
//       // 确保在初始化时就设置音量
//       await _audioPlayer.setVolume(_volume);
//       print('初始化设置音量: $_volume');
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
//       // 监听音量变化
//       _audioPlayer.volumeStream.listen((vol) {
//         print('音量变化: $vol');
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
//       // 确保设置音量
//       await _audioPlayer.setVolume(_volume);
//       print('播放前设置音量: $_volume');
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
//   void _setVolume(double value) async {
//     // 直接在UI上更新
//     setState(() {
//       _volume = value;
//     });
//
//     // 然后应用到播放器
//     try {
//       await _audioPlayer.setVolume(value);
//       print('音量设置成功: $value');
//     } catch (e) {
//       print('音量设置失败: $e');
//     }
//   }
//
//   void _toggleMute() async {
//     double newVolume = _volume > 0 ? 0.0 : 0.7;
//
//     // 直接在UI上更新
//     setState(() {
//       _volume = newVolume;
//     });
//
//     // 然后应用到播放器
//     try {
//       await _audioPlayer.setVolume(newVolume);
//       print('音量切换成功: $newVolume');
//     } catch (e) {
//       print('音量切换失败: $e');
//     }
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
//     final primaryColor = Theme.of(context).primaryColor;
//
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[100],
//         border: Border(
//           top: BorderSide(color: Colors.grey[300]!, width: 1),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 音乐标题和艺术家
//           Text(
//             _currentMetadata?.title ?? '未选择歌曲',
//             style: TextStyle(
//               color: Colors.grey[800],
//               fontWeight: FontWeight.bold,
//               fontSize: 14,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           SizedBox(height: 4),
//           Text(
//             _currentMetadata?.artist ?? '',
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: 12,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//
//           SizedBox(height: 10),
//
//           // 进度条
//           SliderTheme(
//             data: SliderThemeData(
//               trackHeight: 3,
//               thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
//               overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
//               activeTrackColor: primaryColor,
//               inactiveTrackColor: Colors.grey[300],
//               thumbColor: primaryColor,
//               overlayColor: primaryColor.withOpacity(0.3),
//             ),
//             child: Slider(
//               value: _position.inSeconds.toDouble(),
//               min: 0,
//               max: _duration.inSeconds.toDouble() == 0 ? 1 : _duration.inSeconds.toDouble(),
//               onChanged: (value) {
//                 _audioPlayer.seek(Duration(seconds: value.toInt()));
//               },
//             ),
//           ),
//
//           // 时间显示
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 _formatDuration(_position),
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 10,
//                 ),
//               ),
//               Text(
//                 _formatDuration(_duration),
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 10,
//                 ),
//               ),
//             ],
//           ),
//
//           SizedBox(height: 10),
//
//           // 播放控制按钮和音量
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // 播放控制
//               Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.skip_previous, color: Colors.grey[700]),
//                     iconSize: 24,
//                     padding: EdgeInsets.zero,
//                     constraints: BoxConstraints(),
//                     onPressed: _playPrevious,
//                   ),
//                   SizedBox(width: 10),
//                   _isLoading
//                       ? Container(
//                     width: 30,
//                     height: 30,
//                     padding: EdgeInsets.all(6),
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//                     ),
//                   )
//                       : IconButton(
//                     icon: Icon(
//                       _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
//                       color: primaryColor,
//                     ),
//                     iconSize: 30,
//                     padding: EdgeInsets.zero,
//                     constraints: BoxConstraints(),
//                     onPressed: () {
//                       if (_isPlaying) {
//                         _audioPlayer.pause();
//                       } else {
//                         _audioPlayer.play();
//                       }
//                     },
//                   ),
//                   SizedBox(width: 10),
//                   IconButton(
//                     icon: Icon(Icons.skip_next, color: Colors.grey[700]),
//                     iconSize: 24,
//                     padding: EdgeInsets.zero,
//                     constraints: BoxConstraints(),
//                     onPressed: _playNext,
//                   ),
//                 ],
//               ),
//
//               // 音量控制
//               Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(
//                       _volume > 0 ? Icons.volume_up : Icons.volume_off,
//                       color: Colors.grey[700],
//                     ),
//                     iconSize: 20,
//                     padding: EdgeInsets.zero,
//                     constraints: BoxConstraints(),
//                     onPressed: _toggleMute,
//                   ),
//                   Container(
//                     width: 60,
//                     child: SliderTheme(
//                       data: SliderThemeData(
//                         trackHeight: 3,
//                         thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
//                         overlayShape: RoundSliderOverlayShape(overlayRadius: 10),
//                         activeTrackColor: primaryColor,
//                         inactiveTrackColor: Colors.grey[300],
//                         thumbColor: primaryColor,
//                         overlayColor: primaryColor.withOpacity(0.3),
//                       ),
//                       child: Slider(
//                         value: _volume,
//                         min: 0,
//                         max: 1,
//                         onChanged: _setVolume,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(
//                       _autoPlayEnabled ? Icons.repeat : Icons.repeat_one,
//                       color: _autoPlayEnabled ? primaryColor : Colors.grey[500],
//                       size: 20,
//                     ),
//                     padding: EdgeInsets.zero,
//                     constraints: BoxConstraints(),
//                     onPressed: _toggleAutoPlay,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//
//           // 错误消息
//           if (_errorMessage.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Text(
//                 _errorMessage,
//                 style: TextStyle(
//                   color: Colors.red[700],
//                   fontSize: 10,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }