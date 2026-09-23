---
name: guoqing-city-checkin-templates
description: Generate six National Day city check-in poster templates from a user-provided travel photo. Use when the user asks for 国庆城市打卡、国庆旅行照片模板、六款海报预览、批量图片模板，or reusable template assets for an app.
---

# 国庆城市打卡模板生成

## 目标

从一张用户照片生成 6 款可复用的国庆城市打卡模板，并保留照片主体与完整画幅：

1. 红金经典
2. 城市票根
3. 国风山河
4. 复古号外
5. 夜色烟花
6. 极简假期

详细视觉规范见 `references/design-spec.md`。

## 必要输入

优先获取或从上下文推断：

- `ImagePath`：用户照片的绝对路径，必须存在。
- `City`：城市，例如“北京”。
- `Landmark`：地标，例如“天坛”。
- `Date`：显示日期，例如“2026.10.01”。
- `Coordinates`：可选坐标，例如“39.8822°N · 116.4066°E”。
- `Theme`：统一打卡文案，默认“国庆城市打卡”。
- `DayProgress`：假期进度，例如“DAY 1 / 7”。

若用户没有提供城市和地标，先查看图片并推断；无法可靠判断时再询问。不要修改原图。

## 工作流

1. 读取并检查图片的宽高、主体位置和明暗关系。
2. 判断文字安全区：顶部、底部、左右两侧不能遮挡人物或地标主体。
3. 使用以下命令生成六款高清 PNG：

```powershell
& "$SkillDir\scripts\generate_templates.ps1" `
  -ImagePath "C:\path\to\photo.jpg" `
  -City "北京" `
  -Landmark "天坛" `
  -Date "2026.10.01" `
  -Coordinates "39.8822°N · 116.4066°E" `
  -Theme "国庆城市打卡" `
  -DayProgress "DAY 1 / 7" `
  -OutputDir "C:\path\to\output"
```

4. 生成 720px 预览和 2×3 合集图：

```powershell
& "$SkillDir\scripts\make_previews.ps1" -OutputDir "C:\path\to\output"
```

5. 逐张检查文字是否裁切、遮挡、错位，并确认六款风格差异明显。
6. 最终输出高清 PNG、JPG 预览和合集预览，不删除源文件。

## 使用边界

- 使用中国红、金色、星光、烟花、祥云、印章、票根、山水等节庆元素。
- 不使用国旗、国徽、天安门、领导人或未经授权的官方标志，避免暗示官方背书。
- 不擅自改变照片中的地标结构、人物数量或核心内容。
- 字体缺失时，优先使用 Windows 中文字体：`STKaiti`、`Microsoft YaHei`、`SimHei`。

## App 化交付建议

如果用户要把模板用于 App，除了成品图片，还应把每款模板拆成：

- 背景图或用户照片；
- 可编辑文字层；
- 装饰图形层；
- 色彩变量；
- 文字安全区；
- 城市、日期、坐标、Day X/7 等参数。

不要只交付一张不可编辑的合成图。