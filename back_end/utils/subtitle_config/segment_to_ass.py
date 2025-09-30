# utils/subtitle_ass_utils.py
from pathlib import Path
from typing import List, Dict
import unicodedata
import re
from utils.subtitle_config.subtitle_position import normalize_position

# réutilise helpers que tu as déjà (ou recopie _sanitize_text/_split_text_lines si nécessaire)
_RE_CONTROL = re.compile(r"[\x00-\x1f\x7f-\x9f]")
def _sanitize_text(s: str) -> str:
    if s is None:
        return ""
    s = _RE_CONTROL.sub(" ", s)
    s = unicodedata.normalize("NFC", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

def _format_time_ass(seconds: float) -> str:
    # ASS requires H:MM:SS.cc (centiseconds)
    total_cs = int(round(max(0.0, seconds) * 100))
    h, rem = divmod(total_cs, 3600 * 100)
    m, rem = divmod(rem, 60 * 100)
    s, cs = divmod(rem, 100)
    return f"{h}:{m:02d}:{s:02d}.{cs:02d}"

def _escape_ass_text(s: str) -> str:
    # convert newlines to \N, remove control chars already sanitized
    s = s.replace("\n", "\\N").replace("\r", "")
    # ASS allows commas in text (Text is last field), so keep them
    return s

def segments_to_ass(
    segments: List[Dict],
    output_ass_path: str,
    playresx: int = 3840,
    playresy: int = 2160,
    fontname: str = "Arial",
    fontsize: int = 36,
    font_color_ass: str = "&H00FFFFFF",   # use hex_to_ass_color if you prefer
    outline_color_ass: str = "&H00000000",
    outline_width: int = 2,
    position: str = "top-center",   # <-- nouveau param
    margin_v: int = 30,
    encoding: str = "utf-8",
) -> None:
    """
    Écrit un fichier .ass à partir de segments [{start,end,text}].
    - output_ass_path : chemin à écrire
    - playresx, playresy : résolution de référence (optionnel)
    """
    align_code = normalize_position(position)
    
    header = [
        "[Script Info]",
        "Title: Subs top-center",
        "ScriptType: v4.00+",
        f"PlayResX: {playresx}",
        f"PlayResY: {playresy}",
        "",
        "[V4+ Styles]",
        "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding",
        # use align_code here
        f"Style: Default,{fontname},{int(fontsize)},{font_color_ass},&H000000FF,{outline_color_ass},&H00000000,0,0,0,0,100,100,0,0,1,{int(outline_width)},0,{align_code},10,10,{int(margin_v)},1",
        "",
        "[Events]",
        "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text",
    ]

    lines = list(header)

    for seg in segments:
        start = float(seg.get("start", 0.0))
        end = float(seg.get("end", start + 0.001))
        text = seg.get("text", "") or ""
        text = _sanitize_text(text)
        text = _escape_ass_text(text)
        start_str = _format_time_ass(start)
        end_str = _format_time_ass(end)
        # Dialogue line: Dialogue: 0,0:00:00.00,0:00:01.23,Default,,0,0,0,,Text
        # Margin fields are numeric (left,right,vertical)
        dialogue = f"Dialogue: 0,{start_str},{end_str},Default,,0,0,0,,{text}"
        lines.append(dialogue)

    out_path = Path(output_ass_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_text = "\n".join(lines)
    out_path.write_text(out_text, encoding=encoding)
