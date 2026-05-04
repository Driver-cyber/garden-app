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
    @State private var showShortcutLearnMore: Bool = false

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
            .sheet(isPresented: $showShortcutLearnMore) {
                ShortcutLearnMoreSheet()
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
                showShortcutLearnMore = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                    Text("Learn more")
                }
                .font(.subheadline)
                .foregroundStyle(Color.sageDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .overlay(
                    Capsule().stroke(Color.sageDeep.opacity(0.45), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

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

private struct ShortcutLearnMoreSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bg.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Quick capture, anywhere")
                            .font(.custom("InstrumentSerif-Regular", size: 30))
                            .italic()
                            .foregroundStyle(Color.ink)

                        Text("Install this Apple Shortcut once and you can drop a note into Garden's Inbox from anywhere on iOS — speak it or type it, no keyboard juggling, no app to open.")
                            .font(.subheadline)
                            .foregroundStyle(Color.ink2)

                        VStack(alignment: .leading, spacing: 14) {
                            Text("Where you'll use it")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Color.ink3)
                                .textCase(.uppercase)

                            useRow(
                                icon: "circle.circle",
                                title: "Action Button",
                                detail: "iPhone 15 Pro and newer — assign the Shortcut and capture from any screen."
                            )
                            useRow(
                                icon: "lock.iphone",
                                title: "Lock Screen",
                                detail: "Add Shortcuts to your Lock Screen as a tap-to-run accessory."
                            )
                            useRow(
                                icon: "square.grid.2x2",
                                title: "Home Screen",
                                detail: "Pin the Shortcut as an icon — tap to open the speak/type menu."
                            )
                            useRow(
                                icon: "mic",
                                title: "Siri",
                                detail: "“Hey Siri, Quick capture in Garden.”"
                            )
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.shield")
                                    .foregroundStyle(Color.sageDeep)
                                Text("Just an Apple Shortcut")
                                    .font(.headline)
                                    .foregroundStyle(Color.ink)
                            }

                            Text("This is a small open automation I built and shared. It runs locally on your device — no servers, no analytics, no third parties. You can open the Shortcut in Apple's Shortcuts app and read every step. Nothing leaves your phone.")
                                .font(.footnote)
                                .foregroundStyle(Color.ink2)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.sageTint.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("About the Shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.sageDeep)
                }
            }
        }
    }

    private func useRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.sageDeep)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Color.ink2)
            }
        }
    }
}

#Preview {
    SettingsView()
}
