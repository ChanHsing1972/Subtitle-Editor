import Foundation

struct SubtitleItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var videoID: String
    var startTime: String
    var endTime: String
    var content: String
    var url: String

    init(videoID: String = "hebtv-11007440", startTime: String = "00:00:00", endTime: String = "00:00:01", content: String = "新字幕", url: String = "https://web.cmc.hebtv.com/cms/rmt0336/0/0rmhlm/qy/hbggpd/xw6hx/11007440.shtml") {
        self.videoID = videoID
        self.startTime = startTime
        self.endTime = endTime
        self.content = content
        self.url = url
    }
}

extension SubtitleItem {
    func toLine() -> String {
        return "\(videoID) \(startTime) \(endTime) \(content) \(url)"
    }

    static func fromLine(_ line: String) -> SubtitleItem? {
        let pattern = "^(\\S+)\\s+(\\d{2}:\\d{2}:\\d{2})\\s+(\\d{2}:\\d{2}:\\d{2})\\s+(.+?)\\s+(https?://\\S+)$"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: line.utf16.count)
            if let m = regex.firstMatch(in: line, options: [], range: range) {
                func group(_ i: Int) -> String { String((line as NSString).substring(with: m.range(at: i))) }
                return SubtitleItem(videoID: group(1), startTime: group(2), endTime: group(3), content: group(4), url: group(5))
            }
        }
        return nil
    }
}
