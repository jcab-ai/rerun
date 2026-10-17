import RerunCore
import SwiftUI

// The physical props on a moment's evidence board, one style per evidence
// kind: boarding pass, receipt, ticket stub, polaroid, voice memo.

/// The main prop for a moment, at full size.
struct EvidenceProp: View {
    let moment: Moment
    let person: Person?
    let player: PlayerProfile

    var body: some View {
        if let evidence = moment.evidence {
            switch evidence.kind {
            case .boardingPass: BoardingPassProp(evidence: evidence, moment: moment, player: player)
            case .receipt: ReceiptProp(evidence: evidence, moment: moment)
            case .ticketStub: TicketStubProp(evidence: evidence, moment: moment, color: person?.color ?? .sun)
            case .polaroid: PolaroidPhoto(caption: evidence[.caption] ?? moment.photoCaption ?? moment.title.lowercased(), color: person?.color ?? .coral, size: 210)
            case .voiceMemo: VoiceMemoProp(evidence: evidence, moment: moment, person: person)
            }
        }
    }
}

// MARK: Boarding pass

struct BoardingPassProp: View {
    let evidence: Evidence
    let moment: Moment
    let player: PlayerProfile
    var width: CGFloat = 340

    private func value(_ field: EvidenceField, _ fallback: String) -> String { evidence[field] ?? fallback }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text(value(.carrier, "RERUN AIR"))
                    Spacer()
                    Text("BOARDING PASS")
                }
                .textStyle(Tokens.TextStyle(.mono(bold: false), 10, tracking: 1.5))
                .foregroundStyle(Color.white)
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
                .background(Tokens.Palette.blue)

                VStack(alignment: .leading, spacing: 10) {
                    labelled("PASSENGER", value(.passenger, player.name.uppercased()), size: 13)
                    HStack(spacing: 10) {
                        Text(value(.from, "HOM")).font(Tokens.Typeface.fredoka(.bold).font(size: 36))
                        ZStack {
                            LineShape().stroke(Tokens.Palette.ink, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                            Text("✈").font(.system(size: 14)).padding(.horizontal, 4).background(Color.white)
                        }
                        .frame(height: 16)
                        Text(value(.to, "AWY")).font(Tokens.Typeface.fredoka(.bold).font(size: 36))
                    }
                    .foregroundStyle(Tokens.Palette.ink)
                    HStack(alignment: .top, spacing: 4) {
                        labelled("FLIGHT", value(.flight, "RR 001"))
                        labelled("DATE", value(.date, DateFormatter.rerun("ddMMM").string(from: moment.date).uppercased()))
                        labelled("GATE", value(.gate, "—"))
                        labelled("BOARD", value(.boarding, DateFormatter.rerun("HH:mm").string(from: moment.date)))
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.trailing, 74)
        }
        .frame(width: width)
        // The stub is an overlay so it matches the pass's height instead of stretching it.
        .overlay(alignment: .trailing) {
            VStack {
                labelled("SEAT", value(.seat, "1A"), size: 16, alignment: .center)
                Spacer(minLength: 6)
                Barcode().frame(width: 50, height: 70)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .frame(width: 74)
            .overlay(alignment: .leading) { Perforation(color: Tokens.Palette.perforation) }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topLeading) {
            if let stamp = evidence[.stamp] {
                RubberStamp(stamp).offset(x: 120, y: 62)
            }
        }
        .overlay(alignment: .top) { PushPin().offset(y: -12) }
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.3), blur: 18, y: 12))
    }

    private func labelled(_ label: String, _ value: String, size: CGFloat = 12, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(label).textStyle(Tokens.TextStyle(.mono(bold: false), size == 13 ? 10 : 9)).foregroundStyle(Tokens.Palette.pencil)
            Text(value).textStyle(Tokens.TextStyle(.mono(bold: true), size)).foregroundStyle(Tokens.Palette.ink)
        }
        .frame(maxWidth: alignment == .leading ? .infinity : nil, alignment: Alignment(horizontal: alignment, vertical: .top))
    }
}

/// The small boarding-pass sticker on the play screen and storyline.
struct MiniBoardingPass: View {
    let evidence: Evidence
    var title: String?
    var width: CGFloat = 260

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text([evidence[.carrier]?.components(separatedBy: " ").first, evidence[.flight], evidence[.gate].map { "GATE \($0)" }].compactMap { $0 }.joined(separator: " · "))
                    .textStyle(Tokens.TextStyle(.mono(bold: false), title == nil ? 9 : 8, tracking: 1))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Tokens.Palette.blue)
                Text("\(evidence[.from] ?? "HOM") → \(evidence[.to] ?? "AWY")")
                    .font(Tokens.Typeface.fredoka(.bold).font(size: title == nil ? 30 : 24))
                    .foregroundStyle(Tokens.Palette.ink)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                if let title {
                    Text(title)
                        .textStyle(Tokens.TextStyle(.fredoka(.semibold), 14, lineHeight: 1.1))
                        .foregroundStyle(Tokens.Palette.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("BOARDING \(evidence[.boarding] ?? "--:--") · SEAT \(evidence[.seat] ?? "--")")
                        .textStyle(Tokens.TextStyle(.mono(bold: false), 9))
                        .foregroundStyle(Tokens.Palette.pencil)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                }
            }
            .padding(.trailing, title == nil ? 34 : 30)
        }
        .frame(width: width)
        .overlay(alignment: .trailing) {
            Barcode()
                .padding(.vertical, 10)
                .padding(.horizontal, 7)
                .frame(width: title == nil ? 34 : 30)
                .overlay(alignment: .leading) { Perforation(color: Tokens.Palette.perforation) }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .top) { PushPin(size: title == nil ? 22 : 20).offset(y: -10) }
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.28), blur: 16, y: 10))
    }
}

// MARK: Receipt

struct ReceiptProp: View {
    let evidence: Evidence
    let moment: Moment
    var width: CGFloat = 240

    var body: some View {
        ReceiptPaper(width: width, fontSize: 11, lineHeight: 1.7, padding: EdgeInsets(top: 16, leading: 16, bottom: 28, trailing: 16), teeth: 12) {
            Text(evidence[.merchant] ?? moment.location?.uppercased() ?? "RECEIPT").fontWeight(.bold).multilineTextAlignment(.center).frame(maxWidth: .infinity)
            if let location = moment.location, evidence[.merchant] != nil {
                Text(location).foregroundStyle(Tokens.Palette.pencil).font(Tokens.Typeface.mono(bold: false).font(size: 9)).frame(maxWidth: .infinity)
            }
            DashedRule().padding(.vertical, 6)
            ForEach(Array(evidence.items.enumerated()), id: \.offset) { _, item in
                ReceiptLine(item.label, item.amount)
            }
            if let total = evidence[.total] {
                DashedRule().padding(.vertical, 6)
                ReceiptLine("TOTAL", total, bold: true)
            }
            Text(evidence[.date] ?? DateFormatter.rerun("MM/dd/yy · h:mm a").string(from: moment.date))
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
            Text("THANK YOU · COME AGAIN")
                .font(Tokens.Typeface.mono(bold: false).font(size: 8))
                .foregroundStyle(Tokens.Palette.pencil)
                .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .topTrailing) {
            if let stamp = evidence[.stamp] {
                RubberStamp(stamp, color: Tokens.Palette.leaf, size: 22, tilt: 12).offset(x: 18, y: 26)
            }
        }
        .overlay(alignment: .topLeading) { PaperClip().rotationEffect(.degrees(-8)).offset(x: 18, y: -16) }
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.28), blur: 18, y: 10))
    }
}

// MARK: Ticket stub

struct TicketStubProp: View {
    let evidence: Evidence
    let moment: Moment
    var color: PersonColor = .sun
    var width: CGFloat = 320

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ADMIT ONE").textStyle(Tokens.TextStyle(.mono(bold: false), 10, tracking: 1.5))
                Text(evidence[.event] ?? moment.title)
                    .textStyle(Tokens.TextStyle(.fredoka(.bold), 26, lineHeight: 1.05))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text([evidence[.section].map { "SEC \($0)" }, evidence[.row].map { "ROW \($0)" }, evidence[.date] ?? DateFormatter.rerun("MM/dd/yy").string(from: moment.date)].compactMap { $0 }.joined(separator: " · "))
                    .textStyle(Tokens.TextStyle(.mono(bold: false), 10))
            }
            .foregroundStyle(color.onFill)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            ZStack {
                Tokens.Palette.coral
                Text("Nº \(String(format: "%04d", moment.id.unicodeScalars.reduce(0) { ($0 * 31 + Int($1.value)) % 10_000 }))")
                    .textStyle(Tokens.TextStyle(.mono(bold: true), 10, tracking: 1))
                    .foregroundStyle(Color.white)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 54)
            .overlay(alignment: .leading) { Perforation(color: Tokens.Palette.ink) }
        }
        .frame(width: width, height: 124)
        .background(color.fill)
        .clipShape(TicketShape())
        .overlay(alignment: .top) { PushPin().offset(x: -30, y: -10) }
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.26), blur: 18, y: 10))
    }

    /// A rounded ticket with semicircle notches at the perforation.
    struct TicketShape: Shape {
        func path(in rect: CGRect) -> Path {
            let notchX = rect.maxX - 54
            var notches = Path()
            notches.addEllipse(in: CGRect(x: notchX - 9, y: rect.minY - 9, width: 18, height: 18))
            notches.addEllipse(in: CGRect(x: notchX - 9, y: rect.maxY - 9, width: 18, height: 18))
            return Path(roundedRect: rect, cornerRadius: 10).subtracting(notches)
        }
    }
}

// MARK: Voice memo

struct VoiceMemoProp: View {
    let evidence: Evidence
    let moment: Moment
    let person: Person?

    private static let bars: [CGFloat] = [8, 14, 22, 12, 30, 18, 26, 10, 34, 20, 14, 28, 16, 8, 22, 30, 12, 18, 26, 14, 10, 20, 8, 16]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🎤 VOICE MEMO").textStyle(Tokens.TextStyle(.mono(bold: false), 10, tracking: 1.5))
                Spacer()
                Text(evidence[.duration] ?? "0:30").textStyle(Tokens.TextStyle(.mono(bold: true), 11))
            }
            .foregroundStyle(Tokens.Palette.pencil)
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(person?.color.fill ?? Tokens.Palette.blue))
                HStack(alignment: .center, spacing: 3) {
                    ForEach(Array(Self.bars.enumerated()), id: \.offset) { index, height in
                        Capsule()
                            .fill((person?.color.fill ?? Tokens.Palette.blue).opacity(index < 9 ? 1 : 0.35))
                            .frame(width: 3, height: height)
                    }
                }
                .frame(height: 36)
            }
            Text(evidence[.caption] ?? "\(person?.displayName ?? "them") — \(DateFormatter.rerun("MMM d").string(from: moment.date))")
                .font(Tokens.Typeface.caveat(bold: false).font(size: 19))
                .foregroundStyle(Tokens.Palette.ink)
        }
        .padding(16)
        .frame(width: 300)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(alignment: .top) { PushPin().offset(y: -12) }
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.28), blur: 18, y: 10))
    }
}

// MARK: Photos & quotes

/// A polaroid with a gradient "photo" in a person's colors and a caption.
struct PolaroidPhoto: View {
    var caption: String
    var color: PersonColor
    var size: CGFloat = 138

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [Tokens.Palette.sun, color.fill], startPoint: UnitPoint(x: 0.2, y: 0), endPoint: UnitPoint(x: 0.8, y: 1))
                .overlay(alignment: .topTrailing) {
                    Circle().fill(Color.white.opacity(0.35)).frame(width: size * 0.22).offset(x: -size * 0.12, y: size * 0.1)
                }
                .frame(width: size, height: size * 0.8)
            Text(caption)
                .font(Tokens.Typeface.caveat(bold: false).font(size: 17))
                .foregroundStyle(Tokens.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(height: 26)
        }
        .padding(.horizontal, 6)
        .padding(.top, 6)
        .background(Color.white)
        .shadow(Tokens.Shadow(Tokens.Palette.ink.opacity(0.25), blur: 16, y: 8))
    }
}

// MARK: The board

/// The kraft-paper evidence board on the left of the moment card.
struct EvidenceBoard: View {
    let moment: Moment
    let person: Person?
    let player: PlayerProfile

    private var mainOffset: (x: CGFloat, y: CGFloat, tilt: Double) {
        switch moment.evidence?.kind {
        case .receipt: (90, 50, -5)
        case .voiceMemo: (40, 90, -4)
        case .ticketStub: (30, 80, -6)
        case .polaroid: (90, 50, -5)
        default: (30, 70, -6)
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            KraftPaper(period: 6, fibre: Color(.sRGB, red: 120 / 255, green: 90 / 255, blue: 50 / 255, opacity: 0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            CoffeeRing().frame(width: 110, height: 110).offset(x: 260, y: 430)

            if moment.evidence != nil {
                EvidenceProp(moment: moment, person: person, player: player)
                    .rotationEffect(.degrees(mainOffset.tilt))
                    .offset(x: mainOffset.x, y: mainOffset.y)
                Text("exhibit A")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 18))
                    .foregroundStyle(Tokens.Palette.pencil)
                    .rotationEffect(.degrees(-8))
                    .offset(x: 26, y: 26)
            }

            if let caption = moment.photoCaption {
                PolaroidPhoto(caption: caption, color: person?.color ?? .coral, size: moment.evidence == nil ? 200 : 138)
                    .rotationEffect(.degrees(5))
                    .offset(x: moment.evidence == nil ? 70 : 46, y: moment.evidence == nil ? 70 : 320)
                Tape(Tokens.Palette.tapeBlue, width: 60, height: 20, angle: -10)
                    .offset(x: moment.evidence == nil ? 200 : 150, y: moment.evidence == nil ? 60 : 310)
            }

            if let quote = moment.quote {
                BubbleSticker(quote, fontSize: 14, tilt: -4)
                    .frame(width: 170, alignment: .leading)
                    .offset(x: moment.photoCaption == nil && moment.evidence == nil ? 110 : 200, y: moment.photoCaption == nil && moment.evidence == nil ? 160 : 360)
            }

            if moment.evidenceCount == 0 {
                Text("no props yet —\njust the texts.")
                    .font(Tokens.Typeface.caveat(bold: false).font(size: 26))
                    .foregroundStyle(Tokens.Palette.pencil)
                    .rotationEffect(.degrees(-4))
                    .offset(x: 80, y: 200)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("EVIDENCE · \(moment.evidenceCount) ITEM\(moment.evidenceCount == 1 ? "" : "S")")
                Text(moment.evidenceSource ?? "from \(moment.messageCount) real texts")
            }
            .textStyle(Tokens.Typography.monoCaption.withLineHeight(1.6))
            .foregroundStyle(Tokens.Palette.pencilDark)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.leading, 24)
            .padding(.bottom, 22)
        }
    }
}
