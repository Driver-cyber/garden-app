import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @Query(sort: \Note.createdAt, order: .reverse) private var allNotes: [Note]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var includeArchived: Bool = true
    @State private var copyConfirm: Bool = false

    private var inboxEnabled: Bool {
        categories.contains { $0.name == "Inbox" }
    }

    private var exportNotes: [Note] {
        includeArchived ? allNotes : allNotes.filter { $0.status == .active }
    }

    private var markdown: String {
        ExportMarkdown.generate(notes: exportNotes, categories: categories)
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        aboutCard
                        quickCaptureCard
                        exportCard
                        philosophyCard
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.sageDeep)
                }
            }
        }
    }

    // MARK: About

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Garden")
                .font(.custom("InstrumentSerif-Regular", size: 32))
                .italic()
                .foregroundStyle(Color.ink)
            Text("A quiet place for notes, one daily checkbox, and a wheat field.")
                .font(.subheadline)
                .foregroundStyle(Color.ink2)
            HStack {
                Text("Version")
                    .font(.caption)
                    .foregroundStyle(Color.ink3)
                Spacer()
                Text(versionString)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.ink2)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.line, lineWidth: 1)
        )
    }

    // MARK: Quick Capture

    private var quickCaptureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick capture")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.ink3)
                    .textCase(.uppercase)
                Spacer()
                if inboxEnabled {
                    Label("Enabled", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.sageDeep)
                        .labelStyle(.titleAndIcon)
                }
            }

            Text(inboxEnabled ? "Inbox is set up" : "Speak or type to Inbox")
                .font(.headline)
                .foregroundStyle(Color.ink)

            Text(inboxEnabled
                 ? "The Garden Inbox Shortcut is installed. Tap the widget Compose button, the lock screen accessory, or assign the Shortcut to your Action Button for the fastest capture."
                 : "The Inbox category is gated behind this Shortcut. Install it once — tap Compose anywhere (widget, lock screen, Action Button) to choose Speak or Type, and notes land silently in your Inbox.")
                .font(.footnote)
                .foregroundStyle(Color.ink2)

            Button {
                InboxGate.enable(in: modelContext)
                if let url = URL(string: "https://www.icloud.com/shortcuts/a7c75ea192d244c8bb7f17ee2fa7d29c") {
                    openURL(url)
                }
            } label: {
                Label(inboxEnabled ? "Reinstall Garden Inbox Shortcut" : "Install Garden Inbox Shortcut",
                      systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.sageDeep)
            .padding(.top, 4)

            Text("Tip: in iOS Settings → Action Button, assign this Shortcut for the fastest capture from anywhere.")
                .font(.caption)
                .foregroundStyle(Color.ink3)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.line, lineWidth: 1)
        )
    }

    // MARK: Export

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.ink3)
                .textCase(.uppercase)

            Text("Export everything")
                .font(.headline)
                .foregroundStyle(Color.ink)

            Text("Download all your notes as a markdown file. A portable copy you own outright — readable by anything, forever.")
                .font(.footnote)
                .foregroundStyle(Color.ink2)

            Toggle(isOn: $includeArchived) {
                Text("Include archived notes")
                    .font(.subheadline)
                    .foregroundStyle(Color.ink)
            }
            .tint(Color.sageDeep)
            .padding(.top, 4)

            HStack {
                Text("\(exportNotes.count) note\(exportNotes.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Color.ink3)
                Spacer()
            }

            HStack(spacing: 10) {
                Button(action: copy) {
                    Label(copyConfirm ? "Copied" : "Copy",
                          systemImage: copyConfirm ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(Color.sageDeep)
                .disabled(exportNotes.isEmpty)

                ShareLink(item: markdown,
                          subject: Text("Garden — full export"),
                          message: Text("")) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.sageDeep)
                .disabled(exportNotes.isEmpty)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.paper)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.line, lineWidth: 1)
        )
    }

    // MARK: Philosophy

    private var philosophyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On storage")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.ink3)
                .textCase(.uppercase)
            Text("Your notes live in three places: this device, your iCloud (synced automatically), and any markdown file you export. No backend, no account, no telemetry.")
                .font(.footnote)
                .foregroundStyle(Color.ink2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.sageTint.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func copy() {
        UIPasteboard.general.string = markdown
        copyConfirm = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copyConfirm = false
        }
    }
}

#Preview {
    SettingsView()
}
