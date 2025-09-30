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
    merge_threshold: float = 0.3,            # moins agressif par défaut
    min_duration: float = 0.04,
    sanitize: bool = True,
    ensure_order: bool = True,
    encoding: str = "utf-8",
    # NOUVEAUX paramètres pour éviter grandes entrées SRT :
    max_segment_duration: float = 6.0,       # durée max (s) d'une entrée SRT
    max_chars_per_segment: int = 80,         # longueur max (caractères) d'un segment avant split
):
    """
    Écrit les segments fournis sous forme de fichier SRT.
    - Si un segment est trop long (durée ou caractères), il est divisé en sous-segments
      temporellement proportionnels (découpage par mots).
    - merge_threshold réduit pour éviter de regrouper trop agressivement (on préfère
      découper proprement).
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

    # optionally merge close segments to reduce flicker (déjà atténué par default)
    if merge_threshold and merge_threshold > 0:
        processed = _merge_close_segments(processed, merge_threshold)

    # ---- NEW: split any segment that is too long (duration or chars) ----
    final_segments: List[Dict] = []

    def split_text_into_n_chunks(text: str, n: int) -> List[str]:
        # breaker: split on whitespace, distribute words evenly (preserve punctuation)
        words = text.split()
        if n <= 1 or len(words) <= 1:
            return [text]
        k = max(1, len(words) // n)
        chunks = []
        i = 0
        while i < len(words):
            chunk = words[i:i+k]
            chunks.append(" ".join(chunk))
            i += k
            # adjust k to distribute remaining words if necessary
            remain = len(words) - i
            remain_slots = n - len(chunks)
            if remain_slots > 0:
                k = max(1, remain // remain_slots)
        # if we produced more chunks than n (rare), merge tail
        if len(chunks) > n:
            merged = chunks[:n-1] + [" ".join(chunks[n-1:])]
            return merged
        return chunks

    for seg in processed:
        start = seg["start"]
        end = seg["end"]
        text = seg["text"].strip()
        dur = end - start
        # compute how many subsegments needed
        n_by_time = int((dur / max_segment_duration) + 0.999) if max_segment_duration > 0 else 1
        n_by_chars = int((len(text) / max_chars_per_segment) + 0.999) if max_chars_per_segment > 0 else 1
        n_sub = max(1, n_by_time, n_by_chars)

        if n_sub == 1:
            final_segments.append(seg)
            continue

        # split text into n_sub chunks by words (keeps punctuation)
        text_chunks = split_text_into_n_chunks(text, n_sub)
        # if split produced fewer/more chunks, adjust n_sub
        n_sub = len(text_chunks)
        # allocate times proportionally by word counts (fairer than equal time when word counts vary)
        words_list = [tc.split() for tc in text_chunks]
        total_words = sum(len(wl) for wl in words_list) or 1
        acc = 0.0
        for i, wl in enumerate(words_list):
            proportion = len(wl) / total_words
            sub_start = start + acc * dur
            acc += proportion
            sub_end = start + acc * dur
            # ensure monotonic and at least min_duration
            if sub_end - sub_start < min_duration:
                sub_end = sub_start + min_duration
            # clamp within original bounds
            if sub_start < start:
                sub_start = start
            if sub_end > end:
                sub_end = end
            chunk_text = " ".join(wl).strip()
            if chunk_text:
                final_segments.append({"start": sub_start, "end": sub_end, "text": chunk_text, "words": None})

    # final cleanup: ensure order & no overlap (small epsilon)
    final_segments.sort(key=lambda x: float(x["start"]))
    cleaned = []
    for seg in final_segments:
        if not cleaned:
            cleaned.append(seg)
            continue
        prev = cleaned[-1]
        if seg["start"] <= prev["end"]:
            seg["start"] = prev["end"] + 0.001
            if seg["start"] >= seg["end"]:
                continue
        cleaned.append(seg)

    # build SRT content in memory
    out_lines: List[str] = []
    idx = 1
    for seg in cleaned:
        start_str = _format_time(seg["start"])
        end_str = _format_time(seg["end"])
        text = seg.get("text", "")
        lines = _split_text_lines(text, max_chars_per_line) if max_chars_per_line and max_chars_per_line > 0 else [text]
        out_lines.append(f"{idx}")
        out_lines.append(f"{start_str} --> {end_str}")
        out_lines.extend(lines)
        out_lines.append("")
        idx += 1

    out_path = Path(output_srt_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_text = "\n".join(out_lines)
    out_path.write_text(out_text, encoding=encoding)
    return
