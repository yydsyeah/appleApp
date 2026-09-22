//
//  TetrisGameView.swift
//  AppleApp
//
//  俄罗斯方块界面：棋盘、计分、操作按钮与手势。
//  兼容 iOS 15（使用 Canvas / Timer.publish 等 iOS 15 API）。
//

import Combine
import SwiftUI

// MARK: - 方块颜色

extension TetrominoType {
    var color: Color {
        switch self {
        case .i: return Color(red: 0.20, green: 0.75, blue: 1.00)
        case .o: return Color(red: 1.00, green: 0.82, blue: 0.16)
        case .t: return Color(red: 0.68, green: 0.34, blue: 0.95)
        case .s: return Color(red: 0.27, green: 0.85, blue: 0.42)
        case .z: return Color(red: 0.93, green: 0.31, blue: 0.36)
        case .j: return Color(red: 0.30, green: 0.53, blue: 0.98)
        case .l: return Color(red: 0.97, green: 0.57, blue: 0.16)
        }
    }
}

// MARK: - 主界面

struct TetrisGameView: View {

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var engine = TetrisEngine()
    @StateObject private var sound = TetrisSoundPlayer()
    @State private var started = false
    @State private var paused = false
    @AppStorage("soundEnabled") private var soundEnabled = true

    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let cell = min(max((geo.size.width - 24) / 10, 8),
                           max((geo.size.height - 280) / 20, 8),
                           36)
            ZStack {
                background

                VStack(spacing: 8) {
                    topBar
                    board
                        .frame(width: cell * 10, height: cell * 20)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                        .gesture(dragGesture)
                        .onTapGesture(perform: tapBoard)
                    controls
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                if !started {
                    startOverlay
                } else if engine.gameOver {
                    gameOverOverlay
                } else if paused {
                    pausedOverlay
                }
            }
        }
        .onReceive(ticker) { _ in
            guard started, !paused, !engine.gameOver else { return }
            engine.advance(elapsed: 0.05)
        }
        .onAppear {
            sound.enabled = soundEnabled
            engine.onEvent = { event in
                sound.play(event)
            }
        }
        .onChange(of: engine.gameOver) { isOver in
            if isOver {
                sound.stopMusic()
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                if started, !paused, !engine.gameOver {
                    sound.resumeMusic()
                }
            } else {
                sound.pauseMusic()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: 背景

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.09, green: 0.10, blue: 0.19),
                Color(red: 0.03, green: 0.05, blue: 0.10),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: 顶部信息栏

    private var topBar: some View {
        VStack(spacing: 4) {
            HStack(spacing: 10) {
                holdBox
                scoreBoard
                nextBox
            }
            HStack {
                Spacer()
                soundToggle
            }
        }
    }

    private var soundToggle: some View {
        Button {
            toggleSound()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                Text(soundEnabled ? "声音开" : "声音关")
            }
            .font(.caption2)
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    private var holdBox: some View {
        VStack(spacing: 3) {
            Text("暂存")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.55))
            PiecePreview(type: engine.hold)
                .frame(width: 56, height: 44)
            Text(engine.canHold ? "可用" : "已用")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var scoreBoard: some View {
        VStack(spacing: 2) {
            StatView(label: "分数", value: "\(engine.score)")
            StatView(label: "行数", value: "\(engine.lines)")
            StatView(label: "等级", value: "\(engine.level)")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
    }

    private var nextBox: some View {
        VStack(spacing: 3) {
            Text("下一个")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.55))
            PiecePreview(type: engine.next)
                .frame(width: 56, height: 44)
            Text("7-bag")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: 棋盘

    private var board: some View {
        Canvas { context, size in
            let cellSize = min(
                size.width / CGFloat(TetrisEngine.boardWidth),
                size.height / CGFloat(TetrisEngine.visibleHeight)
            )
            let boardWidth = cellSize * CGFloat(TetrisEngine.boardWidth)
            let boardHeight = cellSize * CGFloat(TetrisEngine.visibleHeight)
            let originX = (size.width - boardWidth) / 2
            let originY = (size.height - boardHeight) / 2

            let backgroundRect = CGRect(
                x: originX, y: originY,
                width: boardWidth, height: boardHeight
            )
            context.fill(
                Path(roundedRect: backgroundRect, cornerRadius: 2),
                with: .color(Color(white: 0.07))
            )

            func cellRect(x: Int, y: Int) -> CGRect {
                CGRect(
                    x: originX + CGFloat(x) * cellSize,
                    y: originY + CGFloat(y) * cellSize,
                    width: cellSize,
                    height: cellSize
                )
                .insetBy(dx: cellSize * 0.06, dy: cellSize * 0.06)
            }

            // 空格的暗格
            for row in 0..<TetrisEngine.visibleHeight {
                for col in 0..<TetrisEngine.boardWidth {
                    context.fill(
                        Path(roundedRect: cellRect(x: col, y: row), cornerRadius: 2),
                        with: .color(Color.white.opacity(0.05))
                    )
                }
            }

            // 已固定的方块
            for row in 0..<TetrisEngine.visibleHeight {
                let boardRow = row + TetrisEngine.hiddenRows
                for col in 0..<TetrisEngine.boardWidth {
                    if let type = engine.grid[boardRow][col] {
                        context.fill(
                            Path(roundedRect: cellRect(x: col, y: row), cornerRadius: 2),
                            with: .color(type.color)
                        )
                    }
                }
            }

            // 幽灵投影
            if started && !engine.gameOver {
                let ghost = engine.ghost
                for cell in ghost.cells where cell.y >= TetrisEngine.hiddenRows {
                    context.stroke(
                        Path(roundedRect: cellRect(x: cell.x, y: cell.y - TetrisEngine.hiddenRows), cornerRadius: 2),
                        with: .color(ghost.type.color.opacity(0.5)),
                        lineWidth: 1.5
                    )
                }
            }

            // 当前方块
            for cell in engine.current.cells where cell.y >= TetrisEngine.hiddenRows {
                context.fill(
                    Path(roundedRect: cellRect(x: cell.x, y: cell.y - TetrisEngine.hiddenRows), cornerRadius: 2),
                    with: .color(engine.current.type.color)
                )
            }
        }
        .background(Color(white: 0.04))
    }

    // MARK: 操作区

    private var controls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                controlButton(icon: "arrow.2.squarepath", label: "暂存") {
                    engine.holdCurrent()
                }
                controlButton(icon: "arrow.clockwise", label: "旋转") {
                    engine.rotateClockwise()
                }
                controlButton(icon: "arrow.down", label: "软降") {
                    engine.softDrop()
                }
                controlButton(icon: "arrow.down.to.line", label: "落底") {
                    engine.hardDrop()
                }
            }
            HStack(spacing: 8) {
                controlButton(icon: "arrow.left", label: "左移") {
                    _ = engine.moveLeft()
                }
                controlButton(icon: "arrow.right", label: "右移") {
                    _ = engine.moveRight()
                }
                controlButton(icon: "pause.fill", label: "暂停") {
                    togglePause()
                }
                controlButton(icon: "arrow.counterclockwise", label: "重开") {
                    restart()
                }
            }
        }
    }

    private func controlButton(
        icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            guard started, !paused, !engine.gameOver else { return }
            action()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .semibold))
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: 手势

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 18)
            .onEnded { value in
                guard started, !paused, !engine.gameOver else { return }
                let dx = value.translation.width
                let dy = value.translation.height
                if abs(dx) > abs(dy) {
                    if dx > 0 {
                        engine.moveRight()
                    } else {
                        engine.moveLeft()
                    }
                } else if dy > 0 {
                    engine.softDrop()
                } else {
                    engine.hardDrop()
                }
            }
    }

    private func tapBoard() {
        guard started, !paused, !engine.gameOver else { return }
        engine.rotateClockwise()
    }

    private func togglePause() {
        guard started, !engine.gameOver else { return }
        paused.toggle()
        if paused {
            sound.pauseMusic()
        } else {
            sound.resumeMusic()
        }
    }

    private func restart() {
        engine.reset()
        paused = false
        started = true
        sound.startMusic()
    }

    private func toggleSound() {
        soundEnabled.toggle()
        sound.enabled = soundEnabled
        if soundEnabled {
            if started, !paused, !engine.gameOver {
                sound.startMusic()
            }
        } else {
            sound.stopMusic()
        }
    }

    // MARK: 覆盖层

    private var startOverlay: some View {
        ZStack {
            Color.black.opacity(0.74).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("俄罗斯方块")
                    .font(.largeTitle.bold())
                Text("点击屏幕旋转，左右滑动移动\n上滑落底，下滑软降")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                Button {
                    restart()
                } label: {
                    Text("开始游戏")
                        .font(.headline)
                        .padding(.horizontal, 34)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.blue))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                Button {
                    toggleSound()
                } label: {
                    Label(
                        soundEnabled ? "声音：开" : "声音：关",
                        systemImage: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill"
                    )
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.74).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("游戏结束")
                    .font(.largeTitle.bold())
                Text("得分 \(engine.score)")
                    .font(.title3.monospacedDigit())
                Text("消除 \(engine.lines) 行 · 等级 \(engine.level)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Button {
                    restart()
                } label: {
                    Text("再来一局")
                        .font(.headline)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Color.blue))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var pausedOverlay: some View {
        ZStack {
            Color.black.opacity(0.58).ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.white.opacity(0.85))
                Text("已暂停")
                    .font(.title2.bold())
                Button {
                    paused = false
                } label: {
                    Text("继续")
                        .font(.headline)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.blue))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - 小部件

struct StatView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
    }
}

struct PiecePreview: View {
    let type: TetrominoType?

    var body: some View {
        Canvas { context, size in
            guard let type else { return }
            let cells = TetrisPiece.shape(for: type, rotation: 0)
            let minX = cells.map(\.x).min() ?? 0
            let maxX = cells.map(\.x).max() ?? 0
            let minY = cells.map(\.y).min() ?? 0
            let maxY = cells.map(\.y).max() ?? 0
            let width = maxX - minX + 1
            let height = maxY - minY + 1
            let cell = min(
                size.width / CGFloat(max(width, 4)),
                size.height / CGFloat(max(height, 4))
            )
            let offsetX = (size.width - CGFloat(width) * cell) / 2
            let offsetY = (size.height - CGFloat(height) * cell) / 2
            for point in cells {
                let rect = CGRect(
                    x: offsetX + CGFloat(point.x - minX) * cell,
                    y: offsetY + CGFloat(point.y - minY) * cell,
                    width: cell,
                    height: cell
                )
                .insetBy(dx: cell * 0.08, dy: cell * 0.08)
                context.fill(
                    Path(roundedRect: rect, cornerRadius: 2),
                    with: .color(type.color)
                )
            }
        }
    }
}

#Preview {
    TetrisGameView()
}
