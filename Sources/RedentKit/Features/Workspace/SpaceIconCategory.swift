import Foundation

/// The Space icon catalog, shelved by what a Space is for, so the composer can
/// offer a lot of symbols without turning the picker into a wall.
///
/// A symbol may sit on more than one shelf; `SpaceIdentity.pickerIcons` is
/// the de-duplicated union.
public enum SpaceIconCategory: String, CaseIterable, Sendable {
    case developer
    case work
    case personal
    case creative
    case learning
    case play
    case health
    case travel
    case money

    public var icons: [String] {
        switch self {
        case .developer: [
            "chevron.left.forwardslash.chevron.right", "terminal.fill", "apple.terminal.fill", "curlybraces",
            "swift", "server.rack", "cpu.fill", "ladybug.fill", "hammer.fill", "wrench.and.screwdriver.fill",
            "gearshape.2.fill", "externaldrive.fill", "network", "cloud.fill", "keyboard.fill", "laptopcomputer",
            "desktopcomputer", "macwindow", "cube.fill", "shippingbox.fill", "point.3.connected.trianglepath.dotted",
            "antenna.radiowaves.left.and.right", "lock.shield.fill", "function", "number", "qrcode", "wifi"
        ]
        case .work: [
            "briefcase.fill", "building.2.fill", "calendar", "chart.bar.fill", "chart.line.uptrend.xyaxis",
            "doc.text.fill", "folder.fill", "tray.full.fill", "envelope.fill", "paperclip", "person.2.fill",
            "person.3.fill", "list.bullet.clipboard.fill", "checkmark.seal.fill", "signature", "clock.fill",
            "phone.fill", "target", "flag.fill", "lightbulb.fill", "megaphone.fill", "bell.fill", "at"
        ]
        case .personal: [
            "heart.fill", "house.fill", "person.fill", "figure.2.and.child.holdinghands", "pawprint.fill",
            "cup.and.saucer.fill", "fork.knife", "gift.fill", "birthday.cake.fill", "sun.max.fill", "moon.fill",
            "star.fill", "sparkles", "face.smiling.fill", "hand.wave.fill", "bubble.left.and.bubble.right.fill",
            "hand.thumbsup.fill", "key.fill", "cart.fill", "bag.fill", "tshirt.fill"
        ]
        case .creative: [
            "paintbrush.fill", "paintpalette.fill", "pencil.and.outline", "scribble.variable", "wand.and.stars",
            "camera.fill", "camera.aperture", "photo.fill", "film.fill", "video.fill", "music.note", "guitars.fill",
            "pianokeys", "mic.fill", "headphones", "theatermasks.fill"
        ]
        case .learning: [
            "book.fill", "books.vertical.fill", "text.book.closed.fill", "character.book.closed.fill",
            "graduationcap.fill", "studentdesk", "brain.fill", "atom", "flask.fill", "testtube.2",
            "globe.americas.fill", "newspaper.fill", "magnifyingglass", "puzzlepiece.fill", "lightbulb.fill"
        ]
        case .play: [
            "gamecontroller.fill", "dice.fill", "trophy.fill", "flag.checkered", "sportscourt.fill", "soccerball",
            "basketball.fill", "bicycle", "popcorn.fill", "tv.fill", "play.rectangle.fill", "flame.fill", "bolt.fill"
        ]
        case .health: [
            "stethoscope", "cross.case.fill", "heart.text.square.fill", "pills.fill", "figure.run", "figure.yoga",
            "figure.hiking", "dumbbell.fill", "carrot.fill", "bed.double.fill", "moon.stars.fill",
            "brain.head.profile", "drop.fill"
        ]
        case .travel: [
            "airplane", "car.fill", "tram.fill", "ferry.fill", "sailboat.fill", "map.fill", "mappin.and.ellipse",
            "globe", "globe.europe.africa.fill", "suitcase.fill", "tent.fill", "mountain.2.fill",
            "beach.umbrella.fill", "binoculars.fill", "leaf.fill", "tree.fill", "snowflake", "cloud.sun.fill"
        ]
        case .money: [
            "dollarsign.circle.fill", "eurosign.circle.fill", "bitcoinsign.circle.fill", "creditcard.fill",
            "banknote.fill", "wallet.pass.fill", "building.columns.fill", "chart.pie.fill", "percent", "tag.fill"
        ]
        }
    }
}
