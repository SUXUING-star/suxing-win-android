
class ActivityTypes{
  String getActivityTypeName(String type) {
    switch (type) {
      case 'game_comment':
        return '游戏评论';
      case 'game_like':
        return '游戏点赞';
      case 'game_collection':
        return '游戏收藏';
      case 'postReply':
        return '帖子回复';
      case 'userFollow':
        return '用户关注';
      case 'checkIn':
        return '每日签到';
      default:
        return '其他活动';
    }
  }
}
