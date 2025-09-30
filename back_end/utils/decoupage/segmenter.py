# utils/segmenter.py
from typing import List, Dict, Any, Tuple
from copy import deepcopy
import logging
import math

logger = logging.getLogger("segmenter")
logger.setLevel(logging.INFO)


def _float(x):
    try:
        return float(x)
    except Exception:
        return 0.0


def _word_text(w):
    return (w.get("word") or w.get("text") or "").strip()


def _word_start(w, seg_start=None):
    return _float(w.get("start") if w.get("start") is not None else (seg_start if seg_start is not None else 0.0))


def _word_end(w, seg_end=None, seg_start=None):
    if w.get("end") is not None:
        return _float(w.get("end"))
    s = w.get("start")
    if s is not None:
        return _float(s) + 0.05
    return _float(seg_end if seg_end is not None else (seg_start if seg_start is not None else 0.0))


def flatten_aligned(aligned_segments: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Flatten aligned_segments -> list of words with start,end,text and origin segment idx.
    """
    out = []
    for seg_idx, seg in enumerate(aligned_segments):
        seg_start = _float(seg.get("start", 0.0))
        seg_end = _float(seg.get("end", seg_start))
        words = seg.get("words") or []
        for w in words:
            t = _word_text(w)
            if not t:
                continue
            out.append({
                "text": t,
                "start": _word_start(w, seg_start),
                "end": _word_end(w, seg_end, seg_start),
                "orig_segment": seg_idx,
                "raw": w,
            })
    return out


def split_on_silences(words: List[Dict[str, Any]], silence_threshold: float) -> List[List[Dict[str, Any]]]:
    """
    Split list of words into chunks where gaps > silence_threshold.
    """
    if not words:
        return []
    chunks = []
    cur = [words[0]]
    for i in range(len(words) - 1):
        cur_w = words[i]
        next_w = words[i + 1]
        gap = max(0.0, next_w["start"] - cur_w["end"])
        if gap >= silence_threshold:
            chunks.append(cur)
            cur = [next_w]
        else:
            cur.append(next_w)
    if cur:
        chunks.append(cur)
    return chunks


def _ends_with_strong_punct(s: str) -> bool:
    return bool(s) and s[-1] in ('.', '!', '?', '…')


def _ends_with_soft_punct(s: str) -> bool:
    return bool(s) and any(s.endswith(p) for p in (',', ';', ':'))


def split_chunk_to_phrases(
    chunk: List[Dict[str, Any]],
    min_words: int,
    max_words: int,
    max_chars: int,
    max_duration: float,
    debug: bool = False
) -> List[Dict[str, Any]]:
    """
    Convert a chunk (no big silences inside) into phrase segments.
    """
    phrases = []
    cur = []
    for i, w in enumerate(chunk):
        cur.append(w)
        # metrics
        gstart = cur[0]["start"]
        gend = cur[-1]["end"]
        duration = gend - gstart
        text = " ".join(x["text"] for x in cur).strip()
        char_len = len(text)
        n_words = len(cur)

        # gap to next
        next_gap = None
        if i + 1 < len(chunk):
            next_gap = max(0.0, chunk[i + 1]["start"] - w["end"])

        should_close = False
        reason = None

        # 1) prefer closing at strong punctuation
        if _ends_with_strong_punct(cur[-1]["text"]) and n_words >= min_words:
            should_close = True
            reason = "strong_punct"

        # 2) if next gap is significant (but under silence_threshold because chunk is from split_on_silences)
        if not should_close and next_gap is not None and next_gap > (max(0.18, 0.25 * (max_duration/8.0))):
            # small pause inside chunk -> good place to stop if we have at least min_words
            if n_words >= min_words:
                should_close = True
                reason = "intra_chunk_gap"

        # 3) if exceeding char/word/duration limits -> try to split smartly inside cur
        if not should_close and (char_len >= max_chars or n_words >= max_words or duration >= max_duration):
            # find last strong punct in cur
            found = False
            for j in range(len(cur) - 1, -1, -1):
                if _ends_with_strong_punct(cur[j]["text"]) and (j + 1) >= min_words:
                    seg = cur[: j + 1]
                    phrases.append(_make_phrase(seg))
                    cur = cur[j + 1 :]
                    found = True
                    reason = "split_at_strong_in_long"
                    break
            if found:
                continue

            # last soft punct
            for j in range(len(cur) - 1, -1, -1):
                if _ends_with_soft_punct(cur[j]["text"]) and (j + 1) >= min_words:
                    seg = cur[: j + 1]
                    phrases.append(_make_phrase(seg))
                    cur = cur[j + 1 :]
                    found = True
                    reason = "split_at_soft_in_long"
                    break
            if found:
                continue

            # fallback to middle split
            cut = max(min_words, len(cur) // 2)
            seg = cur[:cut]
            phrases.append(_make_phrase(seg))
            cur = cur[cut:]
            reason = "mid_split_in_long"
            continue

        # if should_close by punctuation or gap
        if should_close:
            seg = cur[:]
            phrases.append(_make_phrase(seg))
            cur = []
            if debug:
                logger.debug("split reason=%s text=%s", reason, " ".join(x["text"] for x in seg))
            continue

    # flush remaining
    if cur:
        phrases.append(_make_phrase(cur))

    # post-process: merge very short segments with neighbors
    merged = []
    for p in phrases:
        if merged:
            last = merged[-1]
            # if very short duration or too few words, merge if close
            if (p["end"] - p["start"] < 0.8 or len(p["text"].split()) < 2) and p["start"] - last["end"] < 1.5:
                # merge
                last["end"] = p["end"]
                last["text"] = (last["text"] + " " + p["text"]).strip()
                if last.get("words") is not None and p.get("words") is not None:
                    last["words"].extend(p["words"])
                continue
        merged.append(p)
    return merged


def _make_phrase(word_list: List[Dict[str, Any]]) -> Dict[str, Any]:
    start = word_list[0]["start"]
    end = word_list[-1]["end"]
    text = " ".join(w["text"] for w in word_list).strip()
    return {"start": start, "end": end, "text": text, "words": [w["raw"] for w in word_list]}


def segment_phrases(
    aligned_segments: List[Dict[str, Any]],
    *,
    silence_threshold: float = 0.6,
    min_words: int = 2,
    max_words: int = 14,
    max_chars: int = 80,
    max_duration: float = 8.0,
    debug: bool = False
) -> List[Dict[str, Any]]:
    """
    Main entry: given whisperx-aligned segments (word-level), return phrase segments.
    Steps:
      1) flatten words
      2) split on large silence gaps
      3) within each chunk split into phrases using punctuation/limits
      4) final cleanup (remove overlap)
    """
    words = flatten_aligned(aligned_segments)
    if not words:
        return []

    # Step 1: split on silences
    chunks = split_on_silences(words, silence_threshold=silence_threshold)

    # Step 2: split each chunk to phrases
    output = []
    for chunk in chunks:
        phrases = split_chunk_to_phrases(
            chunk,
            min_words=min_words,
            max_words=max_words,
            max_chars=max_chars,
            max_duration=max_duration,
            debug=debug
        )
        output.extend(phrases)

    # final cleanup: ensure ordering & no overlap
    out_sorted = sorted(output, key=lambda x: float(x["start"]))
    cleaned = []
    for seg in out_sorted:
        if not cleaned:
            cleaned.append(seg)
            continue
        prev = cleaned[-1]
        if seg["start"] <= prev["end"]:
            # move start slightly after prev end to avoid overlap (small epsilon)
            seg["start"] = prev["end"] + 0.001
            if seg["start"] >= seg["end"]:
                # skip degenerate
                continue
        cleaned.append(seg)

    return cleaned
