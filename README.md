# TalkBox Mobile

Flutter 实现的跨平台移动客户端，支持 iOS 和 Android。

## 功能特性

- 用户注册/登录
- 好友管理
- 私聊和群聊
- 多种消息类型（文字、图片、视频、文件、卡片）
- @提及和引用回复
- WebSocket 实时消息
- Bot 管理
- 文件上传

## 项目结构

```
mobile/
├── pubspec.yaml
├── analysis_options.yaml
└── lib/
    ├── main.dart                # 入口
    ├── models/
    │   ├── user.dart            # 用户模型
    │   ├── conversation.dart    # 会话模型
    │   ├── message.dart         # 消息模型
    │   └── bot.dart             # Bot 模型
    ├── services/
    │   ├── api_service.dart     # API 服务
    │   └── websocket_service.dart # WebSocket 服务
    ├── providers/
    │   ├── auth_provider.dart         # 认证状态
    │   ├── conversation_provider.dart # 会话状态
    │   ├── message_provider.dart      # 消息状态
    │   └── friend_provider.dart       # 好友状态
    ├── screens/
    │   ├── login_screen.dart         # 登录
    │   ├── register_screen.dart      # 注册
    │   ├── home_screen.dart          # 主页
    │   ├── chat_screen.dart          # 聊天
    │   ├── friends_screen.dart       # 好友
    │   ├── settings_screen.dart      # 设置
    │   └── bot_list_screen.dart      # Bot 管理
    └── widgets/
        └── message_bubble.dart       # 消息气泡
```

## 环境要求

- Flutter 3.16+
- Dart 3.2+
- iOS: Xcode 15+
- Android: Android Studio, SDK 21+

## 快速开始

### 1. 获取依赖

```bash
flutter pub get
```

### 2. 配置服务端地址

编辑 `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://your-server:8080';
```

### 3. 运行

```bash
# 运行在模拟器/设备
flutter run

# 指定设备
flutter run -d <device_id>
```

### 4. 构建发布

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 依赖说明

| 依赖 | 说明 |
|------|------|
| provider | 状态管理 |
| dio | HTTP 客户端 |
| web_socket_channel | WebSocket |
| shared_preferences | 本地存储 |
| image_picker | 图片选择 |
| file_picker | 文件选择 |
| cached_network_image | 图片缓存 |
| url_launcher | 打开链接 |
| video_player | 视频播放 |

## 页面说明

### 登录/注册
- Material Design 3 风格
- 表单验证
- 错误提示

### 主页
- 底部导航：会话、好友、设置
- 会话列表（下拉刷新）
- 创建群聊

### 聊天
- 消息列表（上拉加载更多）
- 发送文字消息
- 发送文件
- 长按回复
- 实时消息推送

### 好友
- 搜索用户
- 好友请求
- 好友列表
- 点击发起私聊

### 设置
- 修改昵称
- Bot 管理
- 退出登录

### Bot 管理
- 创建 Bot
- 查看/复制 Token
- 删除 Bot

## 状态管理

使用 Provider 进行状态管理：

```dart
// 获取状态
final auth = context.watch<AuthProvider>();

// 调用方法
await context.read<AuthProvider>().login(username, password);
```

### Provider 列表
- `AuthProvider` - 用户认证、登录状态
- `ConversationProvider` - 会话列表
- `MessageProvider` - 消息收发
- `FriendProvider` - 好友管理

## API 服务

`ApiService` 单例类，封装所有 HTTP 请求：

```dart
final api = ApiService();

// 登录
final data = await api.login(username, password);

// 获取消息
final messages = await api.getMessages(conversationId);
```

## WebSocket 服务

`WebSocketService` 单例类，处理实时消息：

```dart
final ws = WebSocketService();

// 连接
ws.connect(token);

// 监听消息
ws.onMessage = (data) {
  // 处理新消息
};

// 发送消息
ws.sendMessage(conversationId, 'text', {'text': 'hello'});
```

## 消息类型

### 文字消息
```dart
{'type': 'text', 'content': {'text': '消息内容'}}
```

### 图片消息
```dart
{'type': 'image', 'content': {'url': '/files/xxx.jpg', 'width': 800, 'height': 600}}
```

### 视频消息
```dart
{'type': 'video', 'content': {'url': '/files/xxx.mp4', 'duration': 120}}
```

### 文件消息
```dart
{'type': 'file', 'content': {'url': '/files/xxx.pdf', 'name': '文档.pdf', 'size': 1024}}
```

### 卡片消息
```dart
{
  'type': 'card',
  'content': {
    'color': '#1890FF',
    'title': '标题',
    'content': '内容',
    'note': '备注',
    'url': 'https://example.com'
  }
}
```

## 推送通知（待实现）

计划集成 Firebase Cloud Messaging (FCM) 和 APNs：

1. 添加依赖
```yaml
dependencies:
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.3.0
```

2. 配置 Firebase
3. 注册设备 Token
4. 处理后台消息

## iOS 配置

### Info.plist
```xml
<!-- 相机权限 -->
<key>NSCameraUsageDescription</key>
<string>用于拍照发送图片</string>

<!-- 相册权限 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>用于选择图片发送</string>
```

## Android 配置

### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

## 开发调试

### 查看日志
```bash
flutter logs
```

### 热重载
按 `r` 键热重载，`R` 键热重启。

### 调试工具
```bash
flutter run --debug
```

## Git Commit 规范

### 格式要求

- 使用英文
- 第一行为简短标题（50 字符以内），概括改动内容
- 如有详细说明，空一行后使用列表形式描述
- 不要添加 AI 生成签名（如 `Generated with Claude Code`、`Co-Authored-By` 等）

## License

MIT
