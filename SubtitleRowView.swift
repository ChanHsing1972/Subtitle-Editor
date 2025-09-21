import SwiftUI

struct SubtitleRowView: View {
    @EnvironmentObject var vm: SubtitleEditorViewModel
    let index: Int
    @Binding var item: SubtitleItem
    var selected: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(String(format: "#%03d", index + 1))
                    .bold()
                Spacer()
                HStack(spacing: 6) {
                    Button(action: { vm.addSubtitle(at: index) }) { Text("↑+") }
                        .frame(width: 40)
                    Button(action: { vm.addSubtitle(at: index + 1) }) { Text("↓+") }
                        .frame(width: 40)
                    Button(action: { vm.deleteSubtitle(at: index) }) { Text("×").foregroundColor(.red) }
                        .frame(width: 32)
                }
            }

            HStack(spacing: 8) {
                Text("开始:")
                TextField("00:00:00", text: $item.startTime)
                    .frame(width: 90)
                VStack {
                    Button("+1s") { item.startTime = SubtitleRowView.adjust(time: item.startTime, delta: 1); vm.setModified(true) }
                    Button("-1s") { item.startTime = SubtitleRowView.adjust(time: item.startTime, delta: -1); vm.setModified(true) }
                }
                Text("结束:")
                TextField("00:00:01", text: $item.endTime)
                    .frame(width: 90)
                VStack {
                    Button("+1s") { item.endTime = SubtitleRowView.adjust(time: item.endTime, delta: 1); vm.setModified(true) }
                    Button("-1s") { item.endTime = SubtitleRowView.adjust(time: item.endTime, delta: -1); vm.setModified(true) }
                }
                Text(durationText(start: item.startTime, end: item.endTime))
                    .foregroundColor(durationColor(start: item.startTime, end: item.endTime))
                Spacer()
            }

            HStack(alignment: .top) {
                Text("内容:")
                TextEditor(text: $item.content)
                    .frame(minHeight: 40)
                    .font(.system(size: 14))
            }
        }
        .padding(8)
        .background(selected ? Color(NSColor.selectedControlColor).opacity(0.2) : Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(selected ? Color.accentColor : Color.gray.opacity(0.2)))
    }

    static func adjust(time: String, delta: Int) -> String {
        let parts = time.split(separator: ":").map { Int($0) ?? 0 }
        if parts.count == 3 {
            var secs = parts[0]*3600 + parts[1]*60 + parts[2]
            secs = max(0, secs + delta)
            let h = secs / 3600
            let m = (secs % 3600) / 60
            let s = secs % 60
            return String(format: "%02d:%02d:%02d", h, m, s)
        }
        return time
    }

    func durationText(start: String, end: String) -> String {
        let s = SubtitleEditorViewModel().timeToSeconds(start)
        let e = SubtitleEditorViewModel().timeToSeconds(end)
        let d = e - s
        if d >= 0 { return "时长: \(d)秒" }
        return "时长: 错误"
    }

    func durationColor(start: String, end: String) -> Color {
        let s = SubtitleEditorViewModel().timeToSeconds(start)
        let e = SubtitleEditorViewModel().timeToSeconds(end)
        return (e - s) >= 0 ? .blue : .red
    }
}

struct SubtitleRowView_Previews: PreviewProvider {
    static var previews: some View {
        SubtitleRowView(index: 0, item: .constant(SubtitleItem()), selected: false)
            .frame(width: 900)
            .environmentObject(SubtitleEditorViewModel())
    }
}
