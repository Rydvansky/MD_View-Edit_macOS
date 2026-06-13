import AppKit
import QuartzCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var store: DocumentStore
    @AppStorage("appearanceMode") private var appearanceModeRaw = AppearanceMode.system.rawValue
    @AppStorage("showEditorPane") private var showEditorPane = true
    @AppStorage("showPreviewPane") private var showPreviewPane = true
    @AppStorage("showNavigationPane") private var showNavigationPane = false
    @State private var dropIsTargeted = false
    @State private var showingMarkdownHelp = false
    @State private var scrollTarget: MarkdownScrollTarget?

    private var editorText: Binding<String> {
        Binding(
            get: { store.text },
            set: { store.updateText($0) }
        )
    }

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                appearanceModeRaw: $appearanceModeRaw,
                showEditorPane: $showEditorPane,
                showPreviewPane: $showPreviewPane,
                showNavigationPane: $showNavigationPane,
                showingMarkdownHelp: $showingMarkdownHelp
            )

            Divider()

            workspace

            Divider()
            StatusBar()
        }
        .overlay {
            if dropIsTargeted {
                DropOverlay()
            }
        }
        .overlay {
            if store.isEmptyState {
                EmptyStateView()
            }
        }
        .background(AppearanceBridge(mode: appearanceMode))
        .onAppear(perform: ensureVisiblePane)
        .onChange(of: showEditorPane) { _ in ensureVisiblePane() }
        .onChange(of: showPreviewPane) { _ in ensureVisiblePane() }
        .onChange(of: showNavigationPane) { _ in ensureVisiblePane() }
        .onDrop(
            of: [UTType.fileURL.identifier],
            isTargeted: $dropIsTargeted,
            perform: store.handleDrop(providers:)
        )
        .sheet(isPresented: $showingMarkdownHelp) {
            MarkdownHelpView()
                .frame(width: 720, height: 620)
        }
        .alert(item: $store.error) { error in
            Alert(
                title: Text(error.message),
                message: Text(error.recovery ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @ViewBuilder
    private var workspace: some View {
        HSplitView {
            if showNavigationPane {
                NavigationPane { heading in
                    scrollTarget = MarkdownScrollTarget(blockID: heading.id, line: heading.line, source: .navigation)
                }
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 360)
            }

            if showEditorPane {
                EditorPane(
                    text: editorText,
                    fontSize: store.fontSize,
                    scrollTarget: scrollTarget,
                    onLineSelected: syncFromEditor(line:)
                )
                    .frame(minWidth: 360)
            }

            if showPreviewPane {
                PreviewPane(scrollTarget: scrollTarget) { block, fraction in
                    scrollTarget = MarkdownScrollTarget(
                        blockID: block.id,
                        line: block.startLine,
                        endLine: block.endLine,
                        fraction: fraction,
                        source: .preview
                    )
                }
                    .frame(minWidth: 360)
            }
        }
    }

    private func ensureVisiblePane() {
        if !showEditorPane && !showPreviewPane && !showNavigationPane {
            showEditorPane = true
        }
    }

    private func syncFromEditor(line: Int) {
        guard let target = store.scrollTarget(forLine: line) else { return }
        scrollTarget = target
    }
}

private struct EmptyStateView: View {
    @EnvironmentObject private var store: DocumentStore

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 5) {
                Text("No Markdown file open")
                    .font(.title3.weight(.semibold))
                Text("Open a local file or start with the bundled demo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    store.openDemoFile()
                } label: {
                    Label("Open DEMO file", systemImage: "play.rectangle")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    store.openPanel()
                } label: {
                    Label("Open file", systemImage: "folder")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary)
        }
        .shadow(color: .black.opacity(0.10), radius: 18, y: 8)
    }
}

private struct AppearanceBridge: NSViewRepresentable {
    let mode: AppearanceMode

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        applyAppearance(from: view)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        applyAppearance(from: view)
    }

    private func applyAppearance(from view: NSView) {
        DispatchQueue.main.async {
            let appearance = mode.nsAppearance
            NSApp.appearance = appearance
            NSApp.windows.forEach { $0.appearance = appearance }
            view.window?.appearance = appearance
        }
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var store: DocumentStore
    @Binding var appearanceModeRaw: String
    @Binding var showEditorPane: Bool
    @Binding var showPreviewPane: Bool
    @Binding var showNavigationPane: Bool
    @Binding var showingMarkdownHelp: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(store.currentFileName)
                        .font(.headline)
                        .lineLimit(1)

                    if store.isDirty {
                        Text("Edited")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(store.fileURL?.path ?? (store.displayNameOverride == nil ? "Open or drop a local Markdown file" : "Bundled DEMO file"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            Button {
                store.openPanel()
            } label: {
                Label("Open", systemImage: "folder")
            }

            Button {
                store.save()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(!store.canSave)

            HeaderSeparator()

            PaneToggleGroup(
                showEditorPane: $showEditorPane,
                showPreviewPane: $showPreviewPane,
                showNavigationPane: $showNavigationPane
            )

            HeaderSeparator()

            HStack(spacing: 4) {
                Button {
                    store.adjustFont(by: -1)
                } label: {
                    Image(systemName: "textformat.size.smaller")
                }
                .help("Decrease font size")

                Text("\(Int(store.fontSize))")
                    .font(.caption.monospacedDigit())
                    .frame(width: 26)
                    .foregroundStyle(.secondary)

                Button {
                    store.adjustFont(by: 1)
                } label: {
                    Image(systemName: "textformat.size.larger")
                }
                .help("Increase font size")
            }
            .buttonStyle(.bordered)

            HeaderSeparator()

            AppearanceButtonGroup(selection: $appearanceModeRaw)

            HeaderSeparator()

            Button {
                showingMarkdownHelp = true
            } label: {
                Image(systemName: "keyboard.badge.ellipsis")
                    .imageScale(.large)
            }
            .help("Markdown formatting guide")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct PaneToggleGroup: View {
    @Binding var showEditorPane: Bool
    @Binding var showPreviewPane: Bool
    @Binding var showNavigationPane: Bool

    var body: some View {
        HStack(spacing: 4) {
            PaneToggleButton(
                title: "Navigation",
                icon: "list.bullet.indent",
                isOn: showNavigationPane,
                action: { toggle(.navigation) }
            )

            PaneToggleButton(
                title: "Edit",
                icon: "pencil.line",
                isOn: showEditorPane,
                action: { toggle(.editor) }
            )

            PaneToggleButton(
                title: "Preview",
                icon: "doc.richtext",
                isOn: showPreviewPane,
                action: { toggle(.preview) }
            )
        }
    }

    private func toggle(_ pane: PaneKind) {
        var nextEditor = showEditorPane
        var nextPreview = showPreviewPane
        var nextNavigation = showNavigationPane

        switch pane {
        case .editor: nextEditor.toggle()
        case .preview: nextPreview.toggle()
        case .navigation: nextNavigation.toggle()
        }

        guard nextEditor || nextPreview || nextNavigation else { return }

        showEditorPane = nextEditor
        showPreviewPane = nextPreview
        showNavigationPane = nextNavigation
    }

    private enum PaneKind {
        case editor
        case preview
        case navigation
    }
}

private struct PaneToggleButton: View {
    let title: String
    let icon: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(isOn ? Color.accentColor : Color.secondary)
        .help(title)
    }
}

private struct AppearanceButtonGroup: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 4) {
            appearanceButton(mode: .system, icon: "circle.lefthalf.filled")
            appearanceButton(mode: .light, icon: "sun.max")
            appearanceButton(mode: .dark, icon: "moon")
        }
    }

    private func appearanceButton(mode: AppearanceMode, icon: String) -> some View {
        Button {
            selection = mode.rawValue
        } label: {
            Image(systemName: icon)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(selection == mode.rawValue ? Color.accentColor : Color.secondary)
        .help(mode.title)
    }
}

private struct HeaderSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(width: 1, height: 22)
    }
}

private struct EditorPane: View {
    @Binding var text: String
    let fontSize: CGFloat
    let scrollTarget: MarkdownScrollTarget?
    let onLineSelected: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaneTitle(title: "Editor", icon: "pencil.line")
            MarkdownTextView(
                text: $text,
                fontSize: fontSize,
                scrollTarget: scrollTarget,
                onLineSelected: onLineSelected
            )
        }
    }
}

private struct PreviewPane: View {
    @EnvironmentObject private var store: DocumentStore
    let scrollTarget: MarkdownScrollTarget?
    let onBlockSelected: (MarkdownBlock, Double) -> Void
    @State private var previewScrollView: NSScrollView?
    @State private var headingPositions: [String: CGFloat] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                PaneTitle(title: "Preview", icon: "doc.richtext")
                Spacer()
                if store.isRendering {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 12)
                }
            }

            if let notice = store.previewNotice {
                Text(notice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    MarkdownPreview(
                        blocks: store.previewBlocks,
                        fontSize: store.fontSize,
                        referenceLinks: store.referenceLinks,
                        baseURL: store.documentBaseURL
                    )
                        .padding(.horizontal, 22)
                        .padding(.vertical, 18)
                        .background(ScrollViewAccessor(scrollView: $previewScrollView))
                        .background(
                            PreviewClickMonitor(
                                scrollView: $previewScrollView,
                                blocks: store.previewBlocks,
                                blockPositions: headingPositions,
                                contentTopInset: 18,
                                onBlockSelected: onBlockSelected
                            )
                        )
                }
                .onPreferenceChange(HeadingPositionPreferenceKey.self) { positions in
                    headingPositions = positions
                }
                .onChange(of: scrollTarget) { target in
                    guard let target else { return }
                    guard target.source != .preview else { return }
                    if scrollPreview(to: target) {
                        return
                    }
                    withAnimation(.easeInOut(duration: 0.18)) {
                        proxy.scrollTo(target.blockID, anchor: .top)
                    }
                }
            }
        }
    }

    private func scrollPreview(to target: MarkdownScrollTarget) -> Bool {
        guard
            let y = headingPositions[target.blockID],
            let scrollView = previewScrollView
        else {
            return false
        }

        let targetY = max(0, y - 88)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: targetY))
        }
        scrollView.reflectScrolledClipView(scrollView.contentView)
        return true
    }
}

private struct PreviewClickMonitor: NSViewRepresentable {
    @Binding var scrollView: NSScrollView?
    let blocks: [MarkdownBlock]
    let blockPositions: [String: CGFloat]
    let contentTopInset: CGFloat
    let onBlockSelected: (MarkdownBlock, Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.update(
            scrollView: scrollView,
            blocks: blocks,
            blockPositions: blockPositions,
            contentTopInset: contentTopInset,
            onBlockSelected: onBlockSelected
        )
        context.coordinator.installMonitorIfNeeded()
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        context.coordinator.update(
            scrollView: scrollView,
            blocks: blocks,
            blockPositions: blockPositions,
            contentTopInset: contentTopInset,
            onBlockSelected: onBlockSelected
        )
        context.coordinator.installMonitorIfNeeded()
    }

    final class Coordinator {
        private weak var scrollView: NSScrollView?
        private var blocks: [MarkdownBlock] = []
        private var blockPositions: [String: CGFloat] = [:]
        private var contentTopInset: CGFloat = 0
        private var onBlockSelected: ((MarkdownBlock, Double) -> Void)?
        private var monitor: Any?

        deinit {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
        }

        func update(
            scrollView: NSScrollView?,
            blocks: [MarkdownBlock],
            blockPositions: [String: CGFloat],
            contentTopInset: CGFloat,
            onBlockSelected: @escaping (MarkdownBlock, Double) -> Void
        ) {
            self.scrollView = scrollView
            self.blocks = blocks
            self.blockPositions = blockPositions
            self.contentTopInset = contentTopInset
            self.onBlockSelected = onBlockSelected
        }

        func installMonitorIfNeeded() {
            guard monitor == nil else { return }

            monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
                self?.handle(event)
                return event
            }
        }

        private func handle(_ event: NSEvent) {
            guard
                let scrollView,
                let window = scrollView.window,
                event.window === window,
                !blocks.isEmpty
            else {
                return
            }

            let pointInClip = scrollView.contentView.convert(event.locationInWindow, from: nil)
            guard scrollView.contentView.bounds.contains(pointInClip) else { return }

            let documentY = scrollView.contentView.bounds.origin.y + pointInClip.y
            guard let result = blockAndFraction(at: documentY) else { return }

            onBlockSelected?(result.block, result.fraction)
        }

        private func blockAndFraction(at documentY: CGFloat) -> (block: MarkdownBlock, fraction: Double)? {
            // blockPositions are in "previewContent" (LazyVStack) coords.
            // documentY from NSScrollView is offset by the top padding applied to MarkdownPreview.
            let y = documentY - contentTopInset

            let sorted = blocks
                .compactMap { block -> (MarkdownBlock, CGFloat)? in
                    guard let position = blockPositions[block.id] else { return nil }
                    return (block, position)
                }
                .sorted { $0.1 < $1.1 }

            guard !sorted.isEmpty else { return nil }

            var selectedIdx = 0
            for (i, item) in sorted.enumerated() {
                if item.1 <= y + 8 { selectedIdx = i } else { break }
            }

            let (block, blockY) = sorted[selectedIdx]

            let endY: CGFloat
            if selectedIdx + 1 < sorted.count {
                endY = sorted[selectedIdx + 1].1
            } else {
                let docHeight = (scrollView?.documentView?.bounds.height ?? (blockY + contentTopInset + 200)) - contentTopInset
                endY = docHeight
            }

            let blockHeight = max(1, endY - blockY)
            let relativeY = max(0, min(blockHeight, y - blockY))
            let fraction = Double(relativeY / blockHeight)

            return (block, fraction)
        }
    }
}

private struct ScrollViewAccessor: NSViewRepresentable {
    @Binding var scrollView: NSScrollView?

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            scrollView = view.enclosingScrollView
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async {
            scrollView = view.enclosingScrollView
        }
    }
}

private struct NavigationPane: View {
    @EnvironmentObject private var store: DocumentStore
    let onSelect: (MarkdownHeading) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaneTitle(title: "Navigation", icon: "list.bullet.indent")

            if store.headings.isEmpty {
                Text("No headings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(14)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(store.headings) { heading in
                            Button {
                                onSelect(heading)
                            } label: {
                                HStack(spacing: 8) {
                                    Text("H\(heading.level)")
                                        .font(.caption2.monospacedDigit().weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24, alignment: .leading)

                                    Text(heading.text)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.leading, CGFloat(max(0, heading.level - 1)) * 12)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

private struct PaneTitle: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
    }
}

private struct StatusBar: View {
    @EnvironmentObject private var store: DocumentStore

    var body: some View {
        HStack(spacing: 10) {
            if store.isLoading {
                ProgressView()
                    .controlSize(.small)
                Text("Loading")
            } else {
                Text(store.fileSizeDescription.isEmpty ? "Ready" : store.fileSizeDescription)
            }

            Spacer()

            Text("\(store.text.count) characters")
            Text("UTF-8")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }
}

private struct DropOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.tint.opacity(0.12))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.tint, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
            }
            .overlay {
                VStack(spacing: 10) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 42, weight: .semibold))
                    Text("Drop Markdown File")
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(.tint)
            }
            .padding(16)
    }
}
