import SwiftUI

struct MarkdownHelpView: View {
    @Environment(\.dismiss) private var dismiss

    private let basics: [MarkdownTip] = [
        MarkdownTip(markdown: "# Heading 1", result: "Largest heading"),
        MarkdownTip(markdown: "## Heading 2", result: "Section heading"),
        MarkdownTip(markdown: "### Heading 3", result: "Smaller heading"),
        MarkdownTip(markdown: "**bold**", result: "Bold text"),
        MarkdownTip(markdown: "*italic*", result: "Italic text"),
        MarkdownTip(markdown: "`code`", result: "Inline code"),
        MarkdownTip(markdown: "[title](https://example.com)", result: "Link"),
        MarkdownTip(markdown: "> quote", result: "Block quote")
    ]

    private let structure: [MarkdownTip] = [
        MarkdownTip(markdown: "- item", result: "Bulleted list"),
        MarkdownTip(markdown: "1. item", result: "Numbered list"),
        MarkdownTip(markdown: "- [ ] task", result: "Open task"),
        MarkdownTip(markdown: "- [x] task", result: "Done task"),
        MarkdownTip(markdown: "---", result: "Divider"),
        MarkdownTip(markdown: "```swift\nlet app = \"native\"\n```", result: "Code block")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "keyboard.badge.ellipsis")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Markdown Formatting")
                        .font(.title2.weight(.bold))
                    Text("Quick patterns for clean local notes.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .help("Close")
            }
            .padding(22)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    TipSection(title: "Text", tips: basics)
                    TipSection(title: "Structure", tips: structure)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("App Hotkeys")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], spacing: 10) {
                            HotkeyRow(keys: "Command O", action: "Open file")
                            HotkeyRow(keys: "Command S", action: "Save")
                            HotkeyRow(keys: "Command +", action: "Bigger text")
                            HotkeyRow(keys: "Command -", action: "Smaller text")
                        }
                    }
                }
                .padding(22)
            }
        }
    }
}

private struct TipSection: View {
    let title: String
    let tips: [MarkdownTip]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 270), spacing: 10)], spacing: 10) {
                ForEach(tips) { tip in
                    TipCard(tip: tip)
                }
            }
        }
    }
}

private struct TipCard: View {
    let tip: MarkdownTip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tip.markdown)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))

            Text(tip.result)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary)
        }
    }
}

private struct HotkeyRow: View {
    let keys: String
    let action: String

    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            Spacer()
            Text(action)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary)
        }
    }
}

private struct MarkdownTip: Identifiable {
    let id = UUID()
    let markdown: String
    let result: String
}
