import SwiftUI

struct Arrow: Shape {
    var arrowHeadHeight: CGFloat = 5

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX, y: arrowHeadHeight))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: arrowHeadHeight))

        return path
    }
}

struct ArrowPreview: View {
    var body: some View {
        Arrow()
            .stroke(Color.black, lineWidth: 1)
            .frame(width: 10, height: 80)
    }
}

#Preview {
    ArrowPreview()
}
