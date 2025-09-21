import Foundation
import SwiftUI

final class SubtitleEditorViewModel: ObservableObject {
    @Published var subtitles: [SubtitleItem] = []
    @Published var selectedIDs: Set<UUID> = []
    @Published var statusMessage: String = "就绪"
    @Published var modified: Bool = false


    private(set) var currentFile: URL?
    private let autosaveFileName = "autosave.json"
    private var autosaveTimer: Timer?

    var hasAutosave: Bool { FileManager.default.fileExists(atPath: autosaveURL.path) }
    private var autosaveURL: URL { URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(autosaveFileName) }

    init() {
        // try load autosave metadata lazily
    }

    func setupAutosave() {
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.modified && !self.subtitles.isEmpty {
                self.saveAutosave()
            }
        }
    }

    func setModified(_ m: Bool) {
        DispatchQueue.main.async { self.modified = m }
    }

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["txt"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let s = try String(contentsOf: url, encoding: .utf8)
                let lines = s.components(separatedBy: .newlines)
                var arr: [SubtitleItem] = []
                for line in lines {
                    if let item = SubtitleItem.fromLine(line) { arr.append(item) }
                }
                DispatchQueue.main.async {
                    self.subtitles = arr
                    self.currentFile = url
                    self.setModified(false)
                    self.updateStatus("已打开文件: \(url.lastPathComponent)")
                }
            } catch {
                self.updateStatus("打开文件失败: \(error.localizedDescription)")
            }
        }
    }

    func saveFile() {
        if let url = currentFile {
            do {
                let text = subtitles.map { $0.toLine() }.joined(separator: "\n")
                try text.write(to: url, atomically: true, encoding: .utf8)
                setModified(false)
                updateStatus("已保存: \(url.lastPathComponent)")
            } catch {
                // If write failed (permission), fallback to Save As to get user permission
                updateStatus("保存失败: \(error.localizedDescription)，尝试另存为...")
                DispatchQueue.main.async {
                    self.saveAs()
                }
            }
        } else {
            saveAs()
        }
    }

    func saveAs() {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["txt"]
        if panel.runModal() == .OK, let url = panel.url {
            currentFile = url
            saveFile()
        }
    }

    // Export as JSON
    func exportJSON() {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["json"]
        panel.nameFieldStringValue = "subtitles.json"
        if panel.runModal() == .OK, let url = panel.url {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            do {
                let data = try encoder.encode(subtitles)
                try data.write(to: url)
                updateStatus("已导出 JSON: \(url.lastPathComponent)")
            } catch {
                updateStatus("导出 JSON 失败: \(error.localizedDescription)")
            }
        }
    }

    // Export as SRT
    func exportSRT() {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["srt"]
        panel.nameFieldStringValue = "subtitles.srt"
        if panel.runModal() == .OK, let url = panel.url {
            var lines: [String] = []
            for (i, item) in subtitles.enumerated() {
                let idx = i + 1
                let start = formatToSRT(time: item.startTime)
                let end = formatToSRT(time: item.endTime)
                lines.append("\(idx)")
                lines.append("\(start) --> \(end)")
                lines.append(item.content)
                lines.append("")
            }
            let text = lines.joined(separator: "\n")
            do {
                try text.write(to: url, atomically: true, encoding: .utf8)
                updateStatus("已导出 SRT: \(url.lastPathComponent)")
            } catch {
                updateStatus("导出 SRT 失败: \(error.localizedDescription)")
            }
        }
    }

    private func formatToSRT(time: String) -> String {
        // input: HH:MM:SS -> output: HH:MM:SS,000
        if time.range(of: #"^\d{2}:\d{2}:\d{2}$"#, options: .regularExpression) != nil {
            return "\(time),000"
        }
        return time
    }

    // Auto open first .txt in current working directory (non-blocking)
    func autoOpenTxt() {
        DispatchQueue.global(qos: .userInitiated).async {
            let currentDir = FileManager.default.currentDirectoryPath
            let fm = FileManager.default
            guard let items = try? fm.contentsOfDirectory(atPath: currentDir) else { return }
            let txts = items.filter { $0.lowercased().hasSuffix(".txt") }
            if let first = txts.first {
                let url = URL(fileURLWithPath: currentDir).appendingPathComponent(first)
                do {
                    let s = try String(contentsOf: url, encoding: .utf8)
                    let lines = s.components(separatedBy: .newlines)
                    var arr: [SubtitleItem] = []
                    for line in lines {
                        if let item = SubtitleItem.fromLine(line) { arr.append(item) }
                    }
                    if !arr.isEmpty {
                        DispatchQueue.main.async {
                            self.subtitles = arr
                            self.currentFile = url
                            self.setModified(false)
                            self.updateStatus("已自动打开: \(first)")
                        }
                    }
                } catch {
                    // ignore
                }
            }
        }
    }

    func addSubtitle(at index: Int? = nil) {
        let i = index ?? subtitles.count
        var videoID = "hebtv-11007440"
        var url = "https://web.cmc.hebtv.com/cms/rmt0336/0/0rmhlm/qy/hbggpd/xw6hx/11007440.shtml"
        var start = "00:00:00"
        var end = "00:00:01"
        if !subtitles.isEmpty {
            if i > 0 {
                let prev = subtitles[i-1]
                videoID = prev.videoID
                url = prev.url
                start = prev.endTime
                end = secondsToTime(timeToSeconds(start) + 1)
            } else if i < subtitles.count {
                let next = subtitles[i]
                videoID = next.videoID
                url = next.url
            }
        }
        let item = SubtitleItem(videoID: videoID, startTime: start, endTime: end, content: "新字幕", url: url)
        subtitles.insert(item, at: i)
        setModified(true)
    }

    func deleteSelected() {
        let ids = selectedIDs
        if ids.isEmpty { updateStatus("请先选择要删除的字幕"); return }
        subtitles.removeAll { ids.contains($0.id) }
        selectedIDs.removeAll()
        setModified(true)
    }

    func deleteSubtitle(at index: Int) {
        guard subtitles.indices.contains(index) else { return }
        subtitles.remove(at: index)
        setModified(true)
    }

    func moveSelected(up: Bool) {
        let indexes = subtitles.enumerated().filter { selectedIDs.contains($0.element.id) }.map { $0.offset }
        if indexes.isEmpty { updateStatus("请先选择要移动的字幕"); return }
        if up {
            if indexes.min() == 0 { return }
            for i in indexes {
                subtitles.swapAt(i, i-1)
            }
        } else {
            if indexes.max() == subtitles.count - 1 { return }
            for i in indexes.reversed() {
                subtitles.swapAt(i, i+1)
            }
        }
        setModified(true)
    }

    func toggleSelection(item: SubtitleItem, multiSelect: Bool) {
        if multiSelect {
            if selectedIDs.contains(item.id) { selectedIDs.remove(item.id) } else { selectedIDs.insert(item.id) }
        } else {
            if selectedIDs.contains(item.id) { selectedIDs.removeAll() } else { selectedIDs = [item.id] }
        }
    }

    func setSelection(_ ids: Set<UUID>) { selectedIDs = ids }

    func updateStatus(_ msg: String) {
        DispatchQueue.main.async {
            self.statusMessage = msg
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.statusMessage = "就绪" }
        }
    }

    // Autosave
    func saveAutosave() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = AutosaveData(currentFilePath: currentFile?.path, subtitles: subtitles, timestamp: ISO8601DateFormatter().string(from: Date()))
        do {
            let d = try encoder.encode(data)
            try d.write(to: autosaveURL)
        } catch {
            // ignore
        }
    }

    func restoreAutosave() {
        do {
            let d = try Data(contentsOf: autosaveURL)
            let decoder = JSONDecoder()
            let data = try decoder.decode(AutosaveData.self, from: d)
            self.subtitles = data.subtitles
            self.currentFile = data.currentFilePath.flatMap { URL(fileURLWithPath: $0) }
            self.setModified(true)
            self.updateStatus("已恢复自动保存的数据")
        } catch {
            // ignore
        }
    }

    // Helpers: time conversion
    func timeToSeconds(_ time: String) -> Int {
        let parts = time.split(separator: ":").map { Int($0) ?? 0 }
        if parts.count == 3 { return parts[0]*3600 + parts[1]*60 + parts[2] }
        return 0
    }

    func secondsToTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

private struct AutosaveData: Codable {
    var currentFilePath: String?
    var subtitles: [SubtitleItem]
    var timestamp: String
}
