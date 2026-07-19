#!/usr/bin/env python3
"""Convert Lexia_Project_Report.md → DOCX with Mermaid diagrams rendered as PNG."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # docs/
SRC = ROOT / "Lexia_Project_Report.md"
EXPORT = ROOT / "export"
MERMAID_DIR = EXPORT / "_mermaid"
DIAGRAM_DIR = EXPORT / "diagrams"
PREPARED_MD = EXPORT / "Lexia_Project_Report_prepared.md"
OUT_DOCX = EXPORT / "Lexia_Project_Report.docx"
PUPPETEER_CFG = EXPORT / "puppeteer.json"

MERMAID_BLOCK = re.compile(r"```mermaid\s*\n(.*?)```", re.DOTALL | re.IGNORECASE)
PARTICIPANT_AS = re.compile(r"^(\s*participant\s+\w+\s+as\s+)(.+)$", re.IGNORECASE)
SEQ_MESSAGE = re.compile(
    r"^(\s*[A-Za-z0-9_]+(?:-->>|->>|--x|-x)\s*[A-Za-z0-9_]+\s*:\s*)(.+)$"
)
ALT_ELSE = re.compile(r"^(\s*(?:alt|else|opt|loop|par|critical|break)\s+)(.+)$", re.IGNORECASE)


def find_mmdc() -> list[str]:
    # On Windows, invoke npx via cmd shim so CreateProcess can find it.
    if sys.platform.startswith("win"):
        return ["npx.cmd", "--yes", "@mermaid-js/mermaid-cli"]
    return ["npx", "--yes", "@mermaid-js/mermaid-cli"]


def _clean_label(text: str) -> str:
    """Normalize labels so mermaid-cli does not treat ; / arrow as syntax."""
    text = text.strip()
    if len(text) >= 2 and text[0] == text[-1] and text[0] in "\"'":
        text = text[1:-1]
    text = (
        text.replace(";", ",")
        .replace("→", "->")
        .replace("←", "<-")
        .replace("{", "(")
        .replace("}", ")")
        .replace("[", "(")
        .replace("]", ")")
        .replace('"', "'")
    )
    # Always quote message/participant aliases that still look "code-like".
    if re.search(r"[/\\()=<>+#*]", text) or "," in text or " " in text:
        return '"' + text + '"'
    return text

def sanitize_mermaid(source: str) -> str:
    """Make sequence/participant labels safer for mermaid-cli parsers.

    Only rewrite sequenceDiagram message / participant / alt|else|opt labels.
    Flowchart / stateDiagram node IDs containing words like Loop must stay intact.
    """
    lines_out: list[str] = []
    in_sequence = False
    for line in source.splitlines():
        stripped = line.strip().lower()
        if stripped.startswith("sequencediagram"):
            in_sequence = True
            lines_out.append(line)
            continue
        if stripped.startswith(
            ("flowchart", "graph ", "statediagram", "erdiagram", "classdiagram", "gantt", "pie")
        ):
            in_sequence = False
            lines_out.append(line)
            continue

        if in_sequence:
            pm = PARTICIPANT_AS.match(line)
            if pm:
                lines_out.append(pm.group(1) + _clean_label(pm.group(2)))
                continue
            sm = SEQ_MESSAGE.match(line)
            if sm:
                lines_out.append(sm.group(1) + _clean_label(sm.group(2)))
                continue
            ae = ALT_ELSE.match(line)
            if ae:
                rest = ae.group(2).strip()
                if rest and rest.lower() != "end":
                    lines_out.append(ae.group(1) + _clean_label(rest))
                    continue

        lines_out.append(line)
    # Force LF so mermaid-cli does not choke on CR leftovers.
    return "\n".join(lines_out)


def write_puppeteer_config() -> None:
    # Avoid rare sandbox issues on Windows CI/desktop.
    PUPPETEER_CFG.write_text(
        '{\n  "args": ["--no-sandbox", "--disable-setuid-sandbox"]\n}\n',
        encoding="utf-8",
    )


def render_diagram(index: int, source: str) -> Path | None:
    MERMAID_DIR.mkdir(parents=True, exist_ok=True)
    DIAGRAM_DIR.mkdir(parents=True, exist_ok=True)

    sanitized = sanitize_mermaid(source)
    mmd_path = MERMAID_DIR / f"diagram_{index:02d}.mmd"
    png_path = DIAGRAM_DIR / f"diagram_{index:02d}.png"
    mmd_path.write_bytes((sanitized.strip() + "\n").encode("utf-8"))

    cmd = [
        *find_mmdc(),
        "-i",
        str(mmd_path),
        "-o",
        str(png_path),
        "-b",
        "white",
        "-s",
        "2",
        "-p",
        str(PUPPETEER_CFG),
    ]
    print(f"[{index:02d}] Rendering {mmd_path.name} -> {png_path.name}")
    result = subprocess.run(cmd, capture_output=True, text=True, shell=False)
    if result.returncode != 0 or not png_path.exists():
        err = (result.stderr or result.stdout or "").strip()
        print(f"[{index:02d}] WARN render failed: {err[:400]}", file=sys.stderr)
        return None
    return png_path


def prepare_markdown(text: str) -> str:
    blocks = list(MERMAID_BLOCK.finditer(text))
    if not blocks:
        return text

    out: list[str] = []
    last = 0
    failed = 0
    for i, match in enumerate(blocks, start=1):
        out.append(text[last : match.start()])
        png = render_diagram(i, match.group(1))
        if png is not None:
            rel = png.relative_to(EXPORT).as_posix()
            out.append(f"\n\n![So do {i}]({rel})\n\n")
        else:
            failed += 1
            # Keep fenced mermaid as code so content is not lost.
            out.append(
                f"\n\n> **[So do {i}]** (chua render duoc anh — giu nguyen ma Mermaid)\n\n"
                f"```mermaid\n{match.group(1).strip()}\n```\n\n"
            )
        last = match.end()
    out.append(text[last:])
    print(f"Diagrams: {len(blocks)} total, {len(blocks) - failed} OK, {failed} failed")
    return "".join(out)


def run_pandoc() -> None:
    cmd = [
        "pandoc",
        str(PREPARED_MD),
        "-o",
        str(OUT_DOCX),
        "--from",
        "markdown+pipe_tables+grid_tables+fenced_code_blocks+yaml_metadata_block",
        "--resource-path",
        str(EXPORT),
        "--toc",
        "--toc-depth=3",
    ]
    print("Running pandoc...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stdout)
        print(result.stderr, file=sys.stderr)
        raise RuntimeError("pandoc failed")
    print(f"Wrote {OUT_DOCX}")


def main() -> int:
    if not SRC.exists():
        print(f"Missing source: {SRC}", file=sys.stderr)
        return 1

    EXPORT.mkdir(parents=True, exist_ok=True)
    write_puppeteer_config()

    # Clean previous diagram outputs for a deterministic rebuild
    if DIAGRAM_DIR.exists():
        for old in DIAGRAM_DIR.glob("diagram_*.png"):
            old.unlink()
    if MERMAID_DIR.exists():
        for old in MERMAID_DIR.glob("diagram_*.mmd"):
            old.unlink()

    raw = SRC.read_text(encoding="utf-8")
    prepared = prepare_markdown(raw)
    PREPARED_MD.write_text(prepared, encoding="utf-8")
    print(f"Prepared markdown: {PREPARED_MD}")

    run_pandoc()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
