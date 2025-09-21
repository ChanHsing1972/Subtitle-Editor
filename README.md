# Subtitle-Editor (Swift/macOS)

实现功能：

- 打开 `.txt` 字幕文件（格式：`video_id start_time end_time content url`）
- 编辑字幕条目（开始/结束时间、多行内容）
- 新建字幕、删除选中、上移/下移
- 自动保存（每 30 秒）到 `autosave.json` 并支持恢复
- 状态栏与修改标记
- 快捷键支持：Cmd+O（打开）、Cmd+S（保存）、Cmd+N（新建）等

文件结构：
- `SubtitleItem.swift`：数据模型（Codable）
- `SubtitleEditorViewModel.swift`：视图模型，包含文件 I/O、自动保存、编辑操作
- `ContentView.swift`：主视图（Toolbar、字幕列表、状态栏）
- `SubtitleRowView.swift`：每一行的视图