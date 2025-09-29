from pathlib import Path
from typing import List, Dict
import textwrap
import unicodedata
import re

# helper: format time with proper rounding and carry
def _format_time(seconds: float) -> str:
    total_ms = int(round(max(0.0, seconds) * 1000))
    total_sec, ms = divmod(total_ms, 1000)
    h, rem = divmod(total_sec, 3600)
    m, s = divmod(rem, 60)
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"

# helper: sanitize text (remove control chars, normalize spaces)
_RE_CONTROL = re.compile(r"[\x00-\x1f\x7f-\x9f]")
def _sanitize_text(s: str) -> str:
    if s is None:
        return ""
    s = _RE_CONTROL.sub(" ", s)
    s = unicodedata.normalize("NFC", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

def _split_text_lines(text: str, max_chars_per_line: int) -> List[str]:
    if not text:
        return [""]
    if max_chars_per_line is None or max_chars_per_line <= 0:
        return [text]
    lines = textwrap.wrap(text, width=max_chars_per_line, break_long_words=False, replace_whitespace=True)
    if not lines:
        return [text[i:i+max_chars_per_line] for i in range(0, len(text), max_chars_per_line)]
    return lines

def _merge_close_segments(segments: List[Dict], merge_threshold: float) -> List[Dict]:
    if not segments or merge_threshold is None or merge_threshold <= 0:
        return segments

    merged: List[Dict] = []
    cur = None
    for seg in segments:
        if cur is None:
            cur = seg.copy()
            continue
        gap = seg["start"] - cur["end"]
        if gap <= merge_threshold:
            cur["end"] = max(cur["end"], seg["end"])
            cur_text = cur.get("text", "").rstrip()
            add_text = seg.get("text", "").lstrip()
            cur["text"] = (cur_text + " " + add_text).strip()
            if cur.get("words") is not None and seg.get("words") is not None:
                cur["words"] = cur.get("words", []) + seg.get("words", [])
        else:
            merged.append(cur)
            cur = seg.copy()
    if cur is not None:
        merged.append(cur)
    return merged

def segments_to_srt(
    segments: List[Dict],
    output_srt_path: str,
    max_chars_per_line: int = 42,
    merge_threshold: float = 0,
    min_duration: float = 0.04,
    sanitize: bool = True,
    ensure_order: bool = True,
    encoding: str = "utf-8",
) -> None:
    """
    Écrit les segments fournis sous forme de fichier SRT.
    ATTENTION : on considère que 'segments' contient déjà des items {start,end,text}
    produits par ta fonction build_phrase_segments_from_aligned_smart.
    """

    # defensive copy & order
    segs = [dict(s) for s in segments]  # shallow copy
    if ensure_order:
        segs.sort(key=lambda s: float(s.get("start", 0.0)))

    # sanitize texts & clamp start/end
    processed = []
    for s in segs:
        start = float(s.get("start", 0.0))
        end = float(s.get("end", start))
        if end < start:
            end = start + 0.001
        text = s.get("text", "") or ""
        if sanitize:
            text = _sanitize_text(text)
        duration = end - start
        if duration < (min_duration or 0.0):
            # skip too short segments
            continue
        processed.append({"start": start, "end": end, "text": text, "words": s.get("words")})

    # optionally merge close segments to reduce flicker
    if merge_threshold and merge_threshold > 0:
        processed = _merge_close_segments(processed, merge_threshold)

    # build SRT content in memory
    out_lines: List[str] = []
    idx = 1
    for seg in processed:
        start_str = _format_time(seg["start"])
        end_str = _format_time(seg["end"])
        text = seg.get("text", "")
        lines = _split_text_lines(text, max_chars_per_line) if max_chars_per_line and max_chars_per_line > 0 else [text]
        out_lines.append(f"{idx}")
        out_lines.append(f"{start_str} --> {end_str}")
        out_lines.extend(lines)
        out_lines.append("")  # blank line between entries
        idx += 1

    out_path = Path(output_srt_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_text = "\n".join(out_lines)
    out_path.write_text(out_text, encoding=encoding)

    return
