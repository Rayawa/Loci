# 时迹应用图标 · 暂定版

2026-10-24用户暂定采用「日历记录页＋独立地点标记」。日历与纸页表达每天的生活记录，珊瑚色地点标记表达地点；冰蓝玻璃、纸张和弯曲路径形成轻立体层次。保留原始认可构图，不再继续探索新方向。

两层均为1024×1024、1:1，无预制边框或圆角；系统负责启动器遮罩。

- `preview.png`：认可时的完整设计原图，保留供以后调整。
- `foreground.png`：上层日历、地点标记和路径，PNG alpha透明背景。
- `background.png`：下层浅冰蓝至近白色背景，完全不透明。
- `layered_image.json`：HarmonyOS分层资源描述，与AppScope和entry一致。

工程资源副本位于AppScope与entry的`resources/base/media/app_icon_foreground.png`和`app_icon_background.png`。启动器、启动窗口及应用内品牌图标均继续使用layered_image；应用内经DrawableDescriptor渲染。

使用内置image_gen拆分两层，以系统sips透明补边及缩放到精确1024×1024，保留前景alpha和主体安全区。[最终图层提示词](provisional-layer-prompts.md)、[原始构图提示词](concepts/reference-calendar-place-prompt.md)及[参考依据](concepts/reference-design-notes.md)一并保存。

旧平面图钉版、立体图钉版、手账地图版及抽象版保留在versions；concepts包含此前设计探索。当前暂定应用资源以本目录foreground/background为准。
