# TalkBox Mobile

Flutter 跨平台移动客户端，支持 iOS 和 Android。

## 功能特性

- 用户注册/登录
- 用户列表（可直接发起私聊）
- 私聊和群聊
- 群组设置（改名、成员管理、Bot 管理）
- 多种消息类型（文字、图片、视频、文件、卡片）
- @提及和引用回复
- WebSocket 实时消息
- Bot 创建和管理
- 可配置服务器地址

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/
│   ├── user.dart             # 用户模型
│   ├── conversation.dart     # 会话模型
│   ├── message.dart          # 消息模型
│   └── bot.dart              # Bot 模型
├── services/
│   ├── api_service.dart      # HTTP API 服务
│   └── websocket_service.dart # WebSocket 服务
├── providers/
│   ├── auth_provider.dart         # 认证状态
│   ├── conversation_provider.dart # 会话状态
│   ├── message_provider.dart      # 消息状态
│   ├── friend_provider.dart       # 用户列表状态
│   └── bot_provider.dart          # Bot 状态
├── screens/
│   ├── login_screen.dart          # 登录页
│   ├── register_screen.dart       # 注册页
│   ├── home_screen.dart           # 主页
│   ├── chat_screen.dart           # 聊天页
│   ├── friends_screen.dart        # 好友页
│   ├── settings_screen.dart       # 设置页
│   ├── group_settings_screen.dart # 群设置页
│   └── bot_list_screen.dart       # Bot 管理页
└── widgets/
    └── message_bubble.dart        # 消息气泡组件
```

## 环境要求

- Flutter 3.24+
- Dart 3.2+
- iOS: Xcode 15+, iOS 13+
- Android: SDK 24+

## 快速开始

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 运行

```bash
# 开发模式
flutter run

# 指定设备
flutter run -d <device_id>
```

### 3. 构建发布

```bash
# Android APK
flutter build apk --release

# Android APK (按架构分包)
flutter build apk --release --split-per-abi

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 依赖说明

| 依赖 | 版本 | 说明 |
|------|------|------|
| provider | ^6.1.1 | 状态管理 |
| dio | ^5.4.0 | HTTP 客户端 |
| web_socket_channel | ^2.4.0 | WebSocket 通信 |
| shared_preferences | ^2.2.2 | 本地存储 |
| image_picker | ^1.0.7 | 图片选择 |
| file_picker | ^10.0.0 | 文件选择 |
| cached_network_image | ^3.3.1 | 图片缓存 |
| url_launcher | ^6.2.4 | 打开链接 |
| video_player | ^2.8.2 | 视频播放 |
| chewie | ^1.7.4 | 视频播放器 UI |
| intl | ^0.19.0 | 国际化 |

## 配置说明

服务器地址支持在设置页面动态配置，默认为 `http://localhost:8080`。

配置会保存在本地存储中，下次启动自动加载。

## 消息类型

| 类型 | 说明 |
|------|------|
| text | 文字消息，支持 @提及 |
| image | 图片消息 |
| video | 视频消息 |
| file | 文件消息 |
| card | 卡片消息（标题、内容、备注、链接） |

## License

MIT
