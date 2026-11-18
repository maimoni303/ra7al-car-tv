import SwiftUI

struct CastView: View {
    @EnvironmentObject var car: CarState
    @EnvironmentObject var mirror: MirrorReceiver

    /// 1 = connect, 2 = open on car screen, 3 = start mirroring, 4 = done
    private var currentStep: Int {
        if !car.connected { return 1 }
        if !car.videoWindowAvailable { return 2 }
        if !mirror.active { return 3 }
        return 4
    }

    private var title: String {
        if mirror.active && car.connected { return L10n.t("cast.mirroringTitle") }
        return L10n.t(car.connected ? "cast.connectedTitle" : "cast.notConnectedTitle")
    }

    private var subtitle: String {
        if mirror.active && car.connected { return L10n.t("cast.mirroringBody") }
        if car.connected && !car.videoWindowAvailable { return L10n.t("cast.openOnCarBody") }
        return L10n.t(car.connected ? "cast.connectedBody" : "cast.notConnectedBody")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    devices.padding(.top, 20)

                    VStack(spacing: 12) {
                        Text(title).font(.system(size: 30, weight: .bold)).multilineTextAlignment(.center)
                        Text(subtitle).font(.system(size: 18)).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        statusPill.padding(.top, 6)
                    }
                    .padding(.horizontal)

                    stepsCard

                    Button { MirrorReceiver.showBroadcastPicker() } label: {
                        Label(L10n.t(mirror.active ? "cast.manage" : "cast.start"),
                              systemImage: "rectangle.on.rectangle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 62)
                            .background(Brand.accent, in: Capsule())
                            .shadow(color: Brand.accent.opacity(0.35), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 4)

                    Label(L10n.t("cast.parked"), systemImage: "parkingsign.circle")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L10n.t("tab.cast"))
        }
    }

    private var devices: some View {
        HStack(spacing: 34) {
            deviceTile(icon: "iphone", label: "iPhone", active: true)
            Image(systemName: "arrow.forward").font(.system(size: 28, weight: .medium))
                .foregroundStyle(car.connected ? Brand.accent : Color.secondary)
            deviceTile(icon: "car.fill", label: L10n.t("cast.carScreen"), active: car.connected)
        }
    }

    private func deviceTile(icon: String, label: String, active: Bool) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 50))
                .foregroundStyle(active ? (icon == "car.fill" ? Brand.accent : Color.primary) : Color(.systemGray3))
                .frame(width: 112, height: 112)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 30))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
            Text(label).foregroundStyle(active ? .secondary : .tertiary)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 10) {
            Circle().fill(car.connected ? Brand.accent : Color.gray).frame(width: 12, height: 12)
            Text(L10n.t(car.connected ? (mirror.active ? "cast.live" : "cast.connected") : "cast.notConnected"))
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(car.connected ? Brand.accent : Color.secondary)
        }
        .padding(.horizontal, 18).padding(.vertical, 10)
        .background(car.connected ? Brand.accent.opacity(0.14) : Color(.systemGray5), in: Capsule())
    }

    private var stepsCard: some View {
        VStack(spacing: 0) {
            stepRow(1, icon: "cable.connector", title: "cast.step1", body: "cast.step1Body")
            Divider().padding(.leading, 76)
            stepRow(2, icon: "car", title: "cast.step2", body: "cast.step2Body")
            Divider().padding(.leading, 76)
            stepRow(3, icon: "rectangle.on.rectangle", title: "cast.step3", body: "cast.step3Body")
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 26))
    }

    private func stepRow(_ n: Int, icon: String, title: String, body: String) -> some View {
        let isCurrent = n == currentStep
        let isDone = n < currentStep
        return HStack(spacing: 16) {
            ZStack {
                if isCurrent {
                    Circle().fill(Brand.accent.opacity(0.08)).frame(width: 60, height: 60)
                    Circle().stroke(Brand.accent, lineWidth: 3).frame(width: 46, height: 46)
                    Image(systemName: icon).foregroundStyle(Brand.accent).font(.system(size: 18, weight: .semibold))
                } else if isDone {
                    Circle().fill(Brand.accent).frame(width: 44, height: 44)
                    Image(systemName: "checkmark").foregroundStyle(.white).font(.headline)
                } else {
                    Circle().fill(Color(.systemGray5)).frame(width: 44, height: 44)
                    Text("\(n)").font(.headline).foregroundStyle(.secondary)
                }
            }
            .frame(width: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t(title)).font(.system(size: 19, weight: isCurrent ? .semibold : .regular))
                    .foregroundStyle(isCurrent || isDone ? .primary : .secondary)
                Text(L10n.t(body)).font(.system(size: 15)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 16)
    }
}
