from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
import re

from .upgrade_with_whisperx_utils import transcribe_and_align

PUNCT_END_RE = re.compile(r"[,.?!…]+$")

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
    # fallback: if no end, use start or segment end
    s = w.get("start")
    if s is not None:
        return _float(s) + 0.05
    return _float(seg_end if seg_end is not None else (seg_start if seg_start is not None else 0.0))

def _largest_gap_split_index(words):
    # returns index i to split after words[i] (i in [0, n-2]) selecting largest gap near middle
    n = len(words)
    if n <= 1:
        return None
    gaps = []
    for i in range(n-1):
        e1 = _word_end(words[i])
        s2 = _word_start(words[i+1])
        gaps.append(max(0.0, s2 - e1))
    mid = n // 2
    # search window to prefer split near mid
    window = max(1, n // 4)
    start_idx = max(0, mid - window)
    end_idx = min(n-2, mid + window)
    # select largest gap in window
    best_i = start_idx
    best_gap = gaps[start_idx]
    for i in range(start_idx, end_idx+1):
        if gaps[i] > best_gap:
            best_gap = gaps[i]
            best_i = i
    # but if best_gap is very small (e.g. < 0.08s) we still accept best_i (will be middle-ish)
    return best_i

def _split_long_words_list(words, max_words):
    # split list of words into chunks of <= max_words,
    # attempt to split at natural gap near middle for each chunk
    out = []
    i = 0
    n = len(words)
    while i < n:
        remaining = n - i
        if remaining <= max_words:
            out.append(words[i:n])
            break
        # consider slice of size up to 2*max_words to find a good split
        window_end = min(n, i + 2*max_words)
        block = words[i:window_end]
        split_local = _largest_gap_split_index(block)
        if split_local is None:
            split_at = i + max_words
        else:
            # split_local is index in block, convert to global index
            split_at = i + split_local + 1
            # prevent too small/large splits
            if split_at - i < max_words // 2 or (window_end - split_at) < max_words // 2:
                split_at = i + max_words
        out.append(words[i:split_at])
        i = split_at
    return out


def build_phrase_segments_from_aligned_smart(
    aligned_segments: List[Dict[str, Any]],
    min_words: int = 3,
    max_words: int = 12,
    max_phrase_duration: float = 8.0,
    punctuation_split: bool = True,
) -> List[Dict[str, Any]]:
    phrase_segments: List[Dict[str, Any]] = []
    pending_short = None  # if we need to merge short phrase with next

    for seg in aligned_segments:
        words = seg.get("words")
        seg_start = _float(seg.get("start", 0.0))
        seg_end = _float(seg.get("end", seg_start))
        text_fallback = seg.get("text", "").strip()

        if not words:
            # fallback whole segment as single phrase (will be merged later if too short)
            candidate = {"start": seg_start, "end": seg_end, "words": [{"word": w, "start": seg_start, "end": seg_end} for w in text_fallback.split()]}
            words = candidate["words"]

        # build tentative sentences by punctuation
        cur = []
        for w in words:
            w_text = _word_text(w)
            cur.append(w)
            is_punct_end = bool(punctuation_split and PUNCT_END_RE.search(w_text))
            cur_len = len(cur)
            cur_start = _word_start(cur[0], seg_start)
            cur_end = _word_end(cur[-1], seg_end, seg_start)
            cur_dur = cur_end - cur_start

            # decide to close phrase on punctuation (but check length)
            if is_punct_end:
                if min_words <= cur_len <= max_words and cur_dur <= max_phrase_duration:
                    # accept
                    phrase_words = cur
                    cur = []
                    # append phrase
                    phrase_segments.append({
                        "start": _word_start(phrase_words[0], seg_start),
                        "end": _word_end(phrase_words[-1], seg_end, seg_start),
                        "text": " ".join(_word_text(x) for x in phrase_words).strip()
                    })
                elif cur_len < min_words:
                    # too short -> keep it (merge with next)
                    # leave cur as-is (it will be merged with next punctuation or finalization)
                    pass
                else:
                    # too long -> split into chunks
                    chunks = _split_long_words_list(cur, max_words)
                    for ch in chunks:
                        phrase_segments.append({
                            "start": _word_start(ch[0], seg_start),
                            "end": _word_end(ch[-1], seg_end, seg_start),
                            "text": " ".join(_word_text(x) for x in ch).strip()
                        })
                    cur = []

            else:
                # no punctuation: close if too many words or too long duration
                if cur_len >= max_words or cur_dur >= max_phrase_duration:
                    # split cur into chunks of <= max_words
                    chunks = _split_long_words_list(cur, max_words)
                    for ch in chunks[:-1]:
                        phrase_segments.append({
                            "start": _word_start(ch[0], seg_start),
                            "end": _word_end(ch[-1], seg_end, seg_start),
                            "text": " ".join(_word_text(x) for x in ch).strip()
                        })
                    # keep last chunk as current (it may be short)
                    cur = chunks[-1]

        # end of segment: flush cur (may be short)
        if cur:
            # create phrase object but handle shortness later
            candidate_phrase = {
                "start": _word_start(cur[0], seg_start),
                "end": _word_end(cur[-1], seg_end, seg_start),
                "text": " ".join(_word_text(x) for x in cur).strip()
            }
            # merge with pending_short if exists
            if pending_short:
                # merge previous pending with this
                merged = {
                    "start": pending_short["start"],
                    "end": candidate_phrase["end"],
                    "text": (pending_short["text"] + " " + candidate_phrase["text"]).strip()
                }
                # replace last phrase (it wasn't appended yet) or append
                phrase_segments.append(merged)
                pending_short = None
            else:
                # if candidate is short, mark as pending (to be merged with next)
                if len(cur) < min_words:
                    pending_short = candidate_phrase
                else:
                    phrase_segments.append(candidate_phrase)

    # after all segments processed: if pending_short exists, merge with last phrase if possible
    if pending_short:
        if phrase_segments:
            last = phrase_segments.pop()
            merged = {
                "start": last["start"],
                "end": pending_short["end"],
                "text": (last["text"] + " " + pending_short["text"]).strip()
            }
            phrase_segments.append(merged)
        else:
            # only pending -> keep it
            phrase_segments.append(pending_short)

    # final pass: ensure none > max_words by splitting if necessary
    final_out = []
    for ph in phrase_segments:
        words_list = ph["text"].split()
        if len(words_list) > max_words:
            # naive split by word count (keeps timing approx by proportional division)
            chunks = []
            total = len(words_list)
            # reconstruct per-chunk word lists with approximate durations
            # fallback: split by count
            i = 0
            while i < total:
                chunk_words = words_list[i:i+max_words]
                chunk_text = " ".join(chunk_words)
                # estimate times proportionally from ph start/end
                rel_start = ph["start"] + (i / total) * (ph["end"] - ph["start"])
                rel_end = ph["start"] + ((i + len(chunk_words)) / total) * (ph["end"] - ph["start"])
                final_out.append({"start": _float(rel_start), "end": _float(rel_end), "text": chunk_text})
                i += max_words
        else:
            final_out.append(ph)

    return final_out


def build_phrases(
    audio_clear_path: Path,
    language: str = "en",
    whisper_model: str = "small",
    device: str = "cuda",
    reuse_models: bool = True,
) -> Tuple[List[Dict[str, Any]], str]:
    """
    Wrapper pratique : appelle transcribe_and_align puis reconstruit des segments par phrase précis.
    Retour: (phrase_segments, detected_language)
    """
    aligned_segments, lang = transcribe_and_align(
        audio_clear_path=audio_clear_path,
        language=language,
        whisper_model=whisper_model,
        device=device,
        reuse_models=reuse_models,
    )

    phrase_segments = build_phrase_segments_from_aligned_smart(aligned_segments=aligned_segments,)

    return phrase_segments, lang
