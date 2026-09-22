//
//  TetrisEngine.swift
//  AppleApp
//
//  俄罗斯方块核心逻辑：纯 Swift + Combine，不依赖 SwiftUI，
//  便于单独理解与测试。棋盘为 10 x 20 可见行，上方还有 2 行隐藏行。
//

import Combine
import Foundation

// MARK: - 基础类型

enum TetrominoType: Int, CaseIterable, Hashable {
    case i, o, t, s, z, j, l
}

struct TetrisPoint: Hashable {
    var x: Int
    var y: Int
}

/// 一个方块：类型 + 旋转状态 + 在棋盘上的左上角基准坐标。
struct TetrisPiece {
    var type: TetrominoType
    var rotation: Int
    var x: Int
    var y: Int

    /// 当前状态下四个格子相对棋盘原点的坐标。
    var cells: [TetrisPoint] {
        Self.shape(for: type, rotation: rotation).map {
            TetrisPoint(x: x + $0.x, y: y + $0.y)
        }
    }

    /// 各类型方块的旋转形态（偏移量，包围盒为 4x4）。
    static func shape(for type: TetrominoType, rotation: Int) -> [TetrisPoint] {
        guard let variants = shapes[type] else { return [] }
        return variants[rotation % variants.count]
    }

    private static let shapes: [TetrominoType: [[TetrisPoint]]] = [
        .i: [
            [TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1), TetrisPoint(x: 3, y: 1)],
            [TetrisPoint(x: 2, y: 0), TetrisPoint(x: 2, y: 1), TetrisPoint(x: 2, y: 2), TetrisPoint(x: 2, y: 3)],
            [TetrisPoint(x: 0, y: 2), TetrisPoint(x: 1, y: 2), TetrisPoint(x: 2, y: 2), TetrisPoint(x: 3, y: 2)],
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 1, y: 2), TetrisPoint(x: 1, y: 3)],
        ],
        .o: [
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 2, y: 0), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1)],
        ],
        .t: [
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1)],
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1), TetrisPoint(x: 1, y: 2)],
            [TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1), TetrisPoint(x: 1, y: 2)],
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 1, y: 2)],
        ],
        .s: [
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 2, y: 0), TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1)],
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1), TetrisPoint(x: 2, y: 2)],
            [TetrisPoint(x: 0, y: 2), TetrisPoint(x: 1, y: 2), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1)],
            [TetrisPoint(x: 0, y: 0), TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 1, y: 2)],
        ],
        .z: [
            [TetrisPoint(x: 0, y: 0), TetrisPoint(x: 1, y: 0), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1)],
            [TetrisPoint(x: 2, y: 0), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1), TetrisPoint(x: 1, y: 2)],
            [TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 1, y: 2), TetrisPoint(x: 2, y: 2)],
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 0, y: 2)],
        ],
        .j: [
            [TetrisPoint(x: 0, y: 0), TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1)],
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 2, y: 0), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 1, y: 2)],
            [TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1), TetrisPoint(x: 2, y: 2)],
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 0, y: 2), TetrisPoint(x: 1, y: 2)],
        ],
        .l: [
            [TetrisPoint(x: 2, y: 0), TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1)],
            [TetrisPoint(x: 1, y: 0), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 1, y: 2), TetrisPoint(x: 2, y: 2)],
            [TetrisPoint(x: 0, y: 1), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 2, y: 1), TetrisPoint(x: 0, y: 2)],
            [TetrisPoint(x: 0, y: 0), TetrisPoint(x: 1, y: 0), TetrisPoint(x: 1, y: 1), TetrisPoint(x: 1, y: 2)],
        ],
    ]
}

// MARK: - 游戏引擎

final class TetrisEngine: ObservableObject {

    // MARK: 常量

    static let boardWidth = 10
    static let totalHeight = 22
    static let hiddenRows = 2
    static let visibleHeight = totalHeight - hiddenRows

    // MARK: 状态

    @Published private(set) var grid: [[TetrominoType?]]
    @Published private(set) var current: TetrisPiece
    @Published private(set) var next: TetrominoType
    @Published private(set) var hold: TetrominoType?
    @Published private(set) var score = 0
    @Published private(set) var lines = 0
    @Published private(set) var level = 1
    @Published private(set) var gameOver = false

    private(set) var canHold = true

    private var bag: [TetrominoType] = []
    private var dropAccumulator: TimeInterval = 0

    // MARK: 初始化

    init() {
        grid = Array(repeating: Array(repeating: nil, count: Self.boardWidth), count: Self.totalHeight)
        current = TetrisPiece(type: .i, rotation: 0, x: 3, y: 0)
        next = .i
        hold = nil
        reset()
    }

    /// 开始（或重新开始）一局。
    func reset() {
        grid = Array(repeating: Array(repeating: nil, count: Self.boardWidth), count: Self.totalHeight)
        bag = []
        score = 0
        lines = 0
        level = 1
        gameOver = false
        hold = nil
        canHold = true
        dropAccumulator = 0
        current = TetrisPiece(type: draw(), rotation: 0, x: 3, y: 0)
        next = draw()
        objectWillChange.send()
    }

    // MARK: 操作

    @discardableResult
    func moveLeft() -> Bool {
        move(dx: -1, dy: 0)
    }

    @discardableResult
    func moveRight() -> Bool {
        move(dx: 1, dy: 0)
    }

    func rotateClockwise() {
        rotate(direction: 1)
    }

    func rotateCounterClockwise() {
        rotate(direction: -1)
    }

    /// 软降一格；到底后固定。
    func softDrop() {
        guard !gameOver else { return }
        if move(dx: 0, dy: 1) {
            score += 1
            objectWillChange.send()
        } else {
            lockCurrent()
        }
    }

    /// 硬降：直接落底并固定。
    func hardDrop() {
        guard !gameOver else { return }
        var distance = 0
        while move(dx: 0, dy: 1) {
            distance += 1
        }
        if distance > 0 {
            score += distance * 2
            objectWillChange.send()
        }
        lockCurrent()
    }

    /// 暂存当前方块（每落一个方块只能使用一次）。
    func holdCurrent() {
        guard !gameOver, canHold else { return }
        canHold = false
        if let held = hold {
            hold = current.type
            current = TetrisPiece(type: held, rotation: 0, x: 3, y: 0)
            if collides(current) {
                gameOver = true
            }
        } else {
            hold = current.type
            spawn()
        }
        objectWillChange.send()
    }

    /// 每帧推进重力（elapsed 为秒）。
    func advance(elapsed: TimeInterval) {
        guard !gameOver else { return }
        dropAccumulator += elapsed
        while dropAccumulator >= gravityInterval {
            dropAccumulator -= gravityInterval
            if !stepDown() { break }
        }
    }

    /// 当前方块落底后的"幽灵"投影，用于界面预览。
    var ghost: TetrisPiece {
        var piece = current
        while true {
            var candidate = piece
            candidate.y += 1
            if collides(candidate) { break }
            piece = candidate
        }
        return piece
    }

    /// 随等级提高而加快的下落间隔（秒）。
    var gravityInterval: TimeInterval {
        max(0.08, 0.8 * pow(0.85, Double(level - 1)))
    }

    // MARK: 内部实现

    @discardableResult
    private func move(dx: Int, dy: Int) -> Bool {
        guard !gameOver else { return false }
        var moved = current
        moved.x += dx
        moved.y += dy
        guard !collides(moved) else { return false }
        current = moved
        objectWillChange.send()
        return true
    }

    @discardableResult
    private func rotate(direction: Int) -> Bool {
        guard !gameOver else { return false }
        var rotated = current
        rotated.rotation = (current.rotation + direction + 4) % 4
        // 简单的踢墙：水平方向依次尝试 0 / -1 / +1 / -2 / +2。
        for dx in [0, -1, 1, -2, 2] {
            var candidate = rotated
            candidate.x += dx
            if !collides(candidate) {
                current = candidate
                objectWillChange.send()
                return true
            }
        }
        // 地板踢：向上抬一格再试。
        var lifted = rotated
        lifted.y -= 1
        if !collides(lifted) {
            current = lifted
            objectWillChange.send()
            return true
        }
        return false
    }

    /// 重力下落一格，不计软降加分；到底后固定。
    private func stepDown() -> Bool {
        if move(dx: 0, dy: 1) { return true }
        lockCurrent()
        return false
    }

    private func lockCurrent() {
        for cell in current.cells {
            guard cell.x >= 0, cell.x < Self.boardWidth,
                  cell.y >= 0, cell.y < Self.totalHeight else { continue }
            grid[cell.y][cell.x] = current.type
        }
        clearCompletedLines()
        spawn()
        objectWillChange.send()
    }

    private func clearCompletedLines() {
        var cleared = 0
        var row = Self.totalHeight - 1
        while row >= 0 {
            if grid[row].allSatisfy({ $0 != nil }) {
                grid.remove(at: row)
                grid.insert(Array(repeating: nil, count: Self.boardWidth), at: 0)
                cleared += 1
            } else {
                row -= 1
            }
        }
        guard cleared > 0 else { return }
        let baseScores = [0, 40, 100, 300, 1200]
        score += baseScores[min(cleared, 4)] * level
        lines += cleared
        level = lines / 10 + 1
    }

    private func spawn() {
        current = TetrisPiece(type: next, rotation: 0, x: 3, y: 0)
        next = draw()
        canHold = true
        dropAccumulator = 0
        if collides(current) {
            gameOver = true
        }
    }

    private func collides(_ piece: TetrisPiece) -> Bool {
        for cell in piece.cells {
            if cell.x < 0 || cell.x >= Self.boardWidth { return true }
            if cell.y < 0 || cell.y >= Self.totalHeight { return true }
            if grid[cell.y][cell.x] != nil { return true }
        }
        return false
    }

    /// 7-bag 随机器：洗牌后逐个取出，取完再洗。
    private func draw() -> TetrominoType {
        if bag.isEmpty {
            bag = TetrominoType.allCases.shuffled()
        }
        return bag.removeLast()
    }
}
