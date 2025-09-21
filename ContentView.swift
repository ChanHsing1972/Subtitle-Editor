//
//  ContentView.swift
//  Subtitle-Editor
//
//  Created by 尘心 on 2025/9/18.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var vm = SubtitleEditorViewModel()
    @State private var showRestoreAlert = false
    @State private var showHelp = false
    @State private var showAbout = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: vm.openFile) { Text("打开") }
                    .keyboardShortcut("o", modifiers: .command)
                Button(action: vm.saveFile) { Text("保存") }
                    .keyboardShortcut("s", modifiers: .command)
                Divider().frame(height: 20)
                Button(action: { vm.addSubtitle() }) { Text("新建字幕") }
                    .keyboardShortcut("n", modifiers: .command)
                Button(action: vm.deleteSelected) { Text("删除") }
                    .keyboardShortcut(.delete, modifiers: [])
                Divider().frame(height: 20)
                Button(action: vm.exportJSON) { Text("导出 JSON") }
                Button(action: vm.exportSRT) { Text("导出 SRT") }
                Button(action: { vm.autoOpenTxt() }) { Text("自动打开目录 .txt") }
                Divider().frame(height: 20)
                Button(action: { vm.moveSelected(up: true) }) { Text("↑ 上移") }
                Button(action: { vm.moveSelected(up: false) }) { Text("↓ 下移") }

                Spacer()

                Text("字幕数量: \(vm.subtitles.count)")
                    .padding(.trailing, 10)
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Main list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8, pinnedViews: []) {
                            ForEach(Array(vm.subtitles.enumerated()), id: \.1.id) { index, _ in
                                SubtitleRowView(index: index, item: $vm.subtitles[index], selected: vm.selectedIDs.contains(vm.subtitles[index].id))
                                    .id(vm.subtitles[index].id)
                                    .environmentObject(vm)
                                    .onTapGesture {
                                        let item = vm.subtitles[index]
                                        vm.toggleSelection(item: item, multiSelect: NSEvent.modifierFlags.contains(.command))
                                    }
                                    .onChange(of: vm.subtitles[index].startTime) { _ in vm.setModified(true) }
                                    .onChange(of: vm.subtitles[index].endTime) { _ in vm.setModified(true) }
                                    .onChange(of: vm.subtitles[index].content) { _ in vm.setModified(true) }
                            }
                        }
                    .padding()
                }
            }

            Divider()

            // Status bar
            HStack {
                Text(vm.statusMessage)
                Spacer()
                Text(vm.modified ? "●未保存" : "●已保存")
                    .foregroundColor(vm.modified ? .red : .green)
            }
            .padding(8)
            .font(.system(size: 14))
        }
        .frame(minWidth: 300, minHeight: 200)
        .onAppear {
            vm.setupAutosave()
            vm.autoOpenTxt()
            if vm.hasAutosave { showRestoreAlert = true }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
