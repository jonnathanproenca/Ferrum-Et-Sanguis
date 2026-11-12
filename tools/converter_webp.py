"""Godot não anima WebP: converte os WebP animados em folhas de sprites (WebP com alfa) + JSON com a grade e o fps."""
import json, math, sys
from pathlib import Path
from PIL import Image

def converter(origem: Path, nome: str, escala: float = 1.0, passo: int = 1) -> None:
    im = Image.open(origem)
    quadros, dur = [], []
    for i in range(im.n_frames):
        im.seek(i)
        if i % passo:
            continue
        q = im.convert("RGBA")
        if escala != 1.0:
            q = q.resize((max(1, round(q.width * escala)), max(1, round(q.height * escala))), Image.LANCZOS)
        quadros.append(q)
        dur.append(im.info.get("duration", 40) * passo)
    w, h = quadros[0].size
    cols = math.ceil(math.sqrt(len(quadros) * h / w)) or 1
    linhas = math.ceil(len(quadros) / cols)
    folha = Image.new("RGBA", (cols * w, linhas * h), (0, 0, 0, 0))
    for i, q in enumerate(quadros):
        folha.paste(q, ((i % cols) * w, (i // cols) * h))
    folha.save(f"assets/anim/{nome}.webp", "WEBP", quality=86, method=6, alpha_quality=90)
    fps = round(1000 / (sum(dur) / len(dur)), 2)
    json.dump({"w": w, "h": h, "n": len(quadros), "cols": cols, "fps": fps}, open(f"assets/anim/{nome}.json", "w"))
    print(nome, w, h, len(quadros), cols, fps)

if __name__ == "__main__":
    converter(Path("/home/claude/ferrum-et-sanguis/public/assets/enfermaria/medico.webp"), "medico", 1.0, 2)
    converter(Path("/home/claude/ferrum-et-sanguis/public/assets/upgrades/engenheiro.webp"), "engenheiro", 1.0, 3)
    converter(Path("/home/claude/ferrum-et-sanguis/public/assets/mercado/mercador.webp"), "mercador", 1.0, 2)
    converter(Path("/home/claude/ferrum-et-sanguis/public/assets/armeiro/ferreiro.webp"), "ferreiro", 0.6, 2)
    converter(Path("/home/claude/ferrum-et-sanguis/public/assets/armeiro/brasa.webp"), "brasa", 1.0, 2)
