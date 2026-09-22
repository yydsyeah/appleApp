#!/usr/bin/env python3
"""生成俄罗斯方块的 8-bit 风格音效与循环背景音乐（16-bit mono WAV）。

用法：python scripts/generate_sounds.py
产物：AppleApp/Sounds/*.wav
"""

import math
import os
import struct
import wave

RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "AppleApp", "Sounds")


def midi_to_hz(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def tone(freq, duration, volume=0.7, kind="square", decay=5.0, sweep=None):
    """生成一个带包络的音符。kind: square / triangle / sine。"""
    count = int(RATE * duration)
    samples = []
    phase = 0.0
    for i in range(count):
        t = i / RATE
        f = freq if sweep is None else freq + (sweep - freq) * (t / duration)
        phase += 2.0 * math.pi * f / RATE
        if kind == "square":
            s = 1.0 if math.sin(phase) >= 0 else -1.0
        elif kind == "triangle":
            s = 2.0 / math.pi * math.asin(math.sin(phase))
        else:
            s = math.sin(phase)
        attack = min(1.0, t / 0.004)
        release = min(1.0, max(0.0, (duration - t) / 0.008))
        env = math.exp(-decay * t / duration)
        samples.append(s * volume * env * attack * release)
    return samples


def silence(duration):
    return [0.0] * int(RATE * duration)


def sequence(items, gap=0.0):
    """items: [(freq, duration), ...]，依次拼接。"""
    out = []
    for freq, duration in items:
        out.extend(tone(freq, duration))
        out.extend(silence(gap))
    return out


def write_wav(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames.extend(struct.pack("<h", int(v * 32767)))
        w.writeframes(bytes(frames))
    print(f"  {name}.wav  {os.path.getsize(path)} bytes")


def main():
    print("生成音效...")
    write_wav("move", tone(520, 0.030, volume=0.5, decay=8))
    write_wav("rotate", tone(300, 0.060, volume=0.5, sweep=620, decay=2.5))
    write_wav("softdrop", tone(240, 0.025, volume=0.45, decay=8))
    write_wav(
        "harddrop",
        tone(500, 0.090, volume=0.55, kind="triangle", sweep=70, decay=4)
        + tone(1400, 0.012, volume=0.2, decay=8),
    )
    write_wav(
        "lock",
        tone(130, 0.060, volume=0.6, kind="triangle", decay=7)
        + tone(900, 0.010, volume=0.2, decay=8),
    )
    write_wav(
        "clear",
        sequence(
            [
                (midi_to_hz(72), 0.050),
                (midi_to_hz(76), 0.050),
                (midi_to_hz(79), 0.050),
                (midi_to_hz(84), 0.100),
            ],
            gap=0.010,
        ),
    )
    write_wav(
        "tetris",
        sequence(
            [
                (midi_to_hz(72), 0.060),
                (midi_to_hz(76), 0.060),
                (midi_to_hz(79), 0.060),
                (midi_to_hz(84), 0.060),
                (midi_to_hz(88), 0.060),
                (midi_to_hz(96), 0.140),
            ],
            gap=0.012,
        ),
    )
    write_wav("levelup", tone(400, 0.140, volume=0.5, sweep=900, decay=2))
    write_wav(
        "gameover",
        sequence(
            [
                (midi_to_hz(76), 0.090),
                (midi_to_hz(73), 0.090),
                (midi_to_hz(69), 0.090),
                (midi_to_hz(65), 0.090),
                (midi_to_hz(57), 0.200),
            ],
            gap=0.020,
        ),
    )
    write_wav(
        "hold",
        sequence(
            [(midi_to_hz(71), 0.040), (midi_to_hz(74), 0.050)],
            gap=0.005,
        ),
    )

    print("生成背景音乐...")
    eighth = 60.0 / 140.0 / 2.0
    # 8 小节原创旋律，(MIDI 音高, 八分音符数)；-1 表示休止。
    melody = [
        (72, 1), (76, 1), (79, 1), (76, 1), (69, 1), (72, 1), (76, 1), (72, 1),
        (65, 1), (69, 1), (72, 1), (69, 1), (67, 1), (71, 1), (74, 1), (71, 1),
        (72, 1), (76, 1), (79, 2), (81, 2), (79, 1), (76, 1),
        (74, 2), (71, 1), (67, 1), (74, 2), (72, 2),
        (72, 1), (76, 1), (79, 1), (76, 1), (69, 1), (72, 1), (76, 1), (72, 1),
        (65, 1), (69, 1), (72, 1), (69, 1), (67, 1), (71, 1), (74, 1), (71, 1),
        (76, 1), (79, 1), (84, 2), (83, 2), (79, 1), (76, 1),
        (69, 2), (72, 2), (74, 2), (72, 2),
    ]
    # 低音，每 2 个八分音符一个音。
    bass = [
        48, 55, 57, 52, 53, 48, 55, 47,
        48, 55, 57, 52, 53, 55, 48, 55,
        48, 55, 57, 52, 53, 48, 55, 47,
        48, 55, 57, 52, 53, 55, 48, 55,
    ]
    bgm = []
    for midi, beats in melody:
        if midi < 0:
            bgm.extend(silence(eighth * beats))
        else:
            bgm.extend(tone(midi_to_hz(midi), eighth * beats, volume=0.16, decay=1.2))
    for midi in bass:
        bgm.extend(tone(midi_to_hz(midi), eighth * 2, volume=0.20, kind="triangle", decay=1.5))
    # 循环边界做淡入淡出，避免拼接爆音。
    fade = int(RATE * 0.08)
    for i in range(fade):
        gain = i / fade
        bgm[i] *= gain
        bgm[-1 - i] *= gain
    write_wav("bgm", bgm)
    print("完成。")


if __name__ == "__main__":
    main()
