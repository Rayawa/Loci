# 暂定日历＋地点版 · 2026-10-24

用户暂定采用concepts/reference-calendar-place.png。该图另存为preview.png，保留认可时的原始构图。

使用内置image_gen将原图拆为两层，sips统一尺寸为1024×1024。保留日历记录页、独立地点标记、冰蓝路径和浅色背景的视觉方向。原始构图生成提示词见concepts/reference-calendar-place-prompt.md。

## 透明前景

Remove the pale background from this approved icon and output a genuine transparent PNG cutout. Keep the existing blue two-ring calendar with curled ivory page, coral location marker, and blue path exactly as shown, at the same positions and scale on the square canvas. Keep all foreground details and colors. Remove only the background/floor, including blank areas inside holes, with smooth clean alpha edges. No redesign, no added elements, no frame. 1024x1024.

首次长提示词生成耗时过长，已终止后以本段短提示词重试。选用的透明前景先通过sips补至1536×1536透明画布，再缩放至1024×1024，恢复与认可整图接近的主体占比，避免系统圆角裁掉路径。已检查补边角像素alpha为0。

## 不透明背景

Use case: precise-object-edit. Edit target: supplied approved provisional 时迹 app icon. Create ONLY its empty opaque background layer. Remove the entire calendar/journal, binder rings, location marker and blue curved path, including all their cast shadows, reflections, halos and any residual silhouettes. Reconstruct an uninterrupted clean softly lit pale ice-blue to near-white smooth gradient that matches the original picture's gentle cool-blue upper-left and brighter center. Maintain the original light background palette, no dark blue and no additional decorations. Square full bleed 1024x1024, every pixel opaque, no pre-rounded corners, no frame or border. No objects, no text, no texture, no grain and no ghost impressions. This will sit below a separate transparent foreground cutout of the original objects.
