#!/usr/bin/env python3
"""Gera as trilhas (loops) em assets/audio/musica/*.ogg por síntese: lira dedilhada, cordas, tambores de moldura e metais graves.
Uso: python3 tools/gerar_musica.py [nome ...]   (sem argumentos gera todas)"""
import sys, subprocess, os
import numpy as np
from scipy.signal import butter, lfilter, fftconvolve

SR = 32000
MODOS = {
    "dorico": [0, 2, 3, 5, 7, 9, 10], "frigio": [0, 1, 3, 5, 7, 8, 10], "menor_harm": [0, 2, 3, 5, 7, 8, 11],
    "mixolidio": [0, 2, 4, 5, 7, 9, 10], "menor": [0, 2, 3, 5, 7, 8, 10],
}

def hz(m): return 440.0 * 2 ** ((m - 69) / 12.0)

def lp(x, fc, ordem=2):
    b, a = butter(ordem, min(fc, SR * 0.45) / (SR / 2))
    return lfilter(b, a, x)

def bp(x, f0, f1):
    b, a = butter(2, [f0 / (SR / 2), min(f1, SR * 0.45) / (SR / 2)], btype="band")
    return lfilter(b, a, x)

def env_ar(n, atq, rel):
    e = np.ones(n)
    a = int(atq * SR); r = int(rel * SR)
    if a > 0: e[:a] = np.linspace(0, 1, a) ** 1.5
    if r > 0: e[-r:] *= np.linspace(1, 0, r)
    return e

def lira(f, dur=1.6, vel=1.0):
    t = np.arange(int(dur * SR)) / SR
    x = np.zeros_like(t)
    for k, (amp, dec) in enumerate([(1.0, 2.2), (0.55, 3.2), (0.32, 4.5), (0.2, 6.0), (0.12, 8.0), (0.07, 10.0)], 1):
        x += amp * np.sin(2 * np.pi * f * k * (1 + 0.0004 * k * k) * t) * np.exp(-dec * t)
    x *= np.minimum(1.0, t / 0.004)
    return x * vel * 0.5

def corda(f, dur, vel=1.0):
    n = int(dur * SR); t = np.arange(n) / SR
    x = np.zeros(n)
    for c in (-7, 0, 6):
        fr = f * 2 ** (c / 1200.0)
        x += 2 * ((fr * t) % 1.0) - 1
    x = lp(x / 3.0, 1500 + 0.0 * f, 2)
    return x * env_ar(n, 0.9, 1.2) * vel * 0.35

def metal(f, dur, vel=1.0):
    n = int(dur * SR); t = np.arange(n) / SR
    x = np.zeros(n)
    for c in (-5, 5):
        fr = f * 2 ** (c / 1200.0)
        x += 2 * ((fr * t) % 1.0) - 1
    x = lp(x / 2.0, 700 + f * 2.0, 2)
    return x * env_ar(n, 0.18, 0.5) * vel * 0.5

def bumbo(grave=True, vel=1.0):
    n = int(0.7 * SR); t = np.arange(n) / SR
    f = (55 if grave else 95) * (1 + 1.2 * np.exp(-t * 30))
    fase = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(fase) * np.exp(-t * (5 if grave else 9))
    ruido = lp(np.random.randn(n), 900) * np.exp(-t * 40) * 0.5
    return (x + ruido) * vel * 0.9

def tak(vel=1.0):
    n = int(0.12 * SR); t = np.arange(n) / SR
    return bp(np.random.randn(n), 1800, 5200) * np.exp(-t * 45) * vel * 0.5

def caixa(vel=1.0):
    n = int(0.2 * SR); t = np.arange(n) / SR
    return (bp(np.random.randn(n), 900, 6000) * np.exp(-t * 22) + np.sin(2 * np.pi * 190 * t) * np.exp(-t * 30) * 0.4) * vel * 0.55

def reverb(x, seg=2.2, mix=0.28, seed=1):
    r = np.random.RandomState(seed)
    n = int(seg * SR)
    ir = r.randn(n) * np.exp(-np.arange(n) / SR * 3.2)
    ir = lp(ir, 3500)
    ir /= np.sqrt(np.sum(ir ** 2))
    return x * (1 - mix) + fftconvolve(x, ir)[:len(x)] * mix * 1.6

def colocar(buf, snd, pos):
    i = int(pos * SR)
    if i >= len(buf): return
    fim = min(len(buf), i + len(snd))
    buf[i:fim] += snd[:fim - i]

TRILHAS = {
    "menu":     dict(bpm=66, raiz=50, modo="dorico", prog=[1,1,7,7,6,6,5,5,1,1,4,4,7,7,5,5], arp=[0,2,1,2,0,2,1,3], melodia=0.35, pad=0.8, drum="leve", metais=False, seed=11),
    "gestao":   dict(bpm=84, raiz=55, modo="dorico", prog=[1,1,4,4,7,7,1,1,1,1,4,4,5,5,1,1], arp=[0,1,2,1,0,1,2,1], melodia=0.5, pad=0.5, drum="tak", metais=False, seed=12),
    "pompeia":  dict(bpm=100, raiz=57, modo="mixolidio", prog=[1,1,7,7,4,4,1,1,1,1,7,7,4,4,5,5], arp=[0,2,1,2,0,2,1,2], melodia=0.55, pad=0.4, drum="medio", metais=False, seed=13),
    "capua":    dict(bpm=108, raiz=52, modo="frigio", prog=[1,1,2,2,1,1,7,7,1,1,2,2,6,6,5,5], arp=[0,1,2,1,2,1,0,1], melodia=0.5, pad=0.5, drum="medio", metais=False, seed=14),
    "coliseu":  dict(bpm=120, raiz=50, modo="menor_harm", prog=[1,1,6,6,5,5,1,1,1,1,6,6,5,5,1,1], arp=[0,1,2,1,0,1,2,3], melodia=0.35, pad=0.5, drum="pesado", metais=True, seed=15),
    "poco":     dict(bpm=78, raiz=46, modo="frigio", prog=[1,1,1,1,2,2,1,1,1,1,7,7,2,2,1,1], arp=[0,2,0,2,1,0,2,1], melodia=0.2, pad=0.9, drum="sombrio", metais=True, seed=16),
    "campanha": dict(bpm=92, raiz=53, modo="dorico", prog=[1,1,4,4,1,1,5,5,1,1,4,4,7,7,1,1], arp=[0,1,2,1,0,2,1,2], melodia=0.45, pad=0.6, drum="marcha", metais=True, seed=17),
}

def acorde(modo, grau, raiz, oit=0):
    esc = MODOS[modo]
    out = []
    for k in (0, 2, 4, 6):
        d = grau - 1 + k
        out.append(raiz + esc[d % 7] + 12 * (d // 7) + 12 * oit)
    return out

def nota_escala(modo, raiz, d):
    esc = MODOS[modo]
    return raiz + esc[d % 7] + 12 * (d // 7)

def gerar(nome, p):
    rng = np.random.RandomState(p["seed"]); np.random.seed(p["seed"])
    bpm = p["bpm"]; q = 60.0 / bpm; compasso = 4 * q
    bars = len(p["prog"]); L = bars * compasso
    cauda = 3.0
    buf = np.zeros(int((L + cauda) * SR))
    pos_d = 0  # posição da melodia (grau)
    for b, grau in enumerate(p["prog"]):
        t0 = b * compasso
        ac = acorde(p["modo"], grau, p["raiz"])
        # pad / cordas
        if p["pad"] > 0:
            for m in ac[:3]:
                colocar(buf, corda(hz(m), compasso + 0.6, p["pad"]), t0)
            colocar(buf, corda(hz(ac[0] - 12), compasso + 0.6, p["pad"] * 0.8), t0)
        if p["metais"] and b % 2 == 0:
            vel = 0.8 if p["drum"] != "sombrio" else 0.55
            for m in (ac[0] - 12, ac[0]):
                colocar(buf, metal(hz(m), compasso * 2 + 0.3, vel), t0)
        # arpejo de lira em colcheias (2 por tempo)
        for s in range(8):
            idx = p["arp"][s]
            m = ac[idx % 4] + 12 * (idx // 4) + 12
            acento = 1.0 if s % 4 == 0 else 0.7
            colocar(buf, lira(hz(m), 1.6, 0.55 * acento), t0 + s * q / 2)
        # melodia esparsa (passo aleatório na escala)
        for s in range(8):
            if rng.rand() < p["melodia"] * (1.0 if s % 2 == 0 else 0.5):
                pos_d = int(np.clip(pos_d + rng.choice([-2, -1, -1, 1, 1, 2]), 2, 12))
                m = nota_escala(p["modo"], p["raiz"], pos_d) + 12
                colocar(buf, lira(hz(m), 2.2, 0.85), t0 + s * q / 2)
        # percussão
        d = p["drum"]
        for s in range(16):
            tt = t0 + s * q / 4
            if d == "leve":
                if s == 0: colocar(buf, bumbo(True, 0.6), tt)
                if s == 8: colocar(buf, bumbo(False, 0.35), tt)
            elif d == "tak":
                if s in (0, 8): colocar(buf, bumbo(False, 0.5), tt)
                if s in (4, 12): colocar(buf, tak(0.6), tt)
            elif d == "medio":
                if s in (0, 6, 8): colocar(buf, bumbo(False, 0.8), tt)
                if s in (4, 12): colocar(buf, tak(0.9), tt)
                if s % 2 == 0: colocar(buf, tak(0.25), tt)
            elif d == "pesado":
                if s in (0, 8, 10): colocar(buf, bumbo(True, 1.0), tt)
                if s in (4, 12): colocar(buf, caixa(0.8), tt)
                if s % 4 == 2: colocar(buf, tak(0.4), tt)
            elif d == "sombrio":
                if s == 0 and b % 2 == 0: colocar(buf, bumbo(True, 0.9), tt)
                if s == 10 and b % 4 == 1: colocar(buf, bumbo(True, 0.6), tt)
                if s == 6 and b % 4 == 3: colocar(buf, tak(0.5), tt)
            elif d == "marcha":
                if s in (0, 8): colocar(buf, bumbo(True, 0.8), tt)
                if s in (4, 12): colocar(buf, caixa(0.7), tt)
                if s in (14,): colocar(buf, caixa(0.4), tt)
    buf = reverb(buf, 2.4 if p["drum"] != "sombrio" else 3.2, 0.3, p["seed"])
    ex = len(buf) - int(L * SR)
    saida = buf[: int(L * SR)].copy()
    saida[: min(ex, len(saida))] += buf[int(L * SR): int(L * SR) + min(ex, len(saida))]
    # estéreo: pequena diferença entre canais
    atraso = int(0.012 * SR)
    esq = saida
    dir_ = np.roll(saida, atraso) * 0.96
    st = np.stack([esq, dir_], axis=1)
    st = st / (np.max(np.abs(st)) + 1e-9) * 0.82
    return st

def salvar(nome, st):
    pcm = (st * 32767).astype("<i2").tobytes()
    destino = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "musica", nome + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-", "-c:a", "libvorbis", "-q:a", "3", destino], input=pcm, check=True)

if __name__ == "__main__":
    alvo = sys.argv[1:] or list(TRILHAS)
    for n in alvo:
        print("gerando", n, flush=True)
        salvar(n, gerar(n, TRILHAS[n]))
