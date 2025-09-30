# utils/decoupage/segmenter.py
from typing import List, Dict, Any
from copy import deepcopy

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
    words = []
    for seg in aligned_segments:
        seg_start = _float(seg.get("start", 0.0))
        seg_end = _float(seg.get("end", seg_start))
        for w in (seg.get("words") or []):
            t = _word_text(w)
            if not t:
                continue
            words.append({
                "text": t,
                "start": _word_start(w, seg_start),
                "end": _word_end(w, seg_end, seg_start),
                "raw": w,
            })
    return words


def split_segment_mid(words_chunk: List[Dict[str, Any]], max_words: int) -> List[Dict[str, Any]]:
    """
    Coupe un chunk (liste de mots) en sous-chunks d'au plus max_words,
    et distribue le temps proportionnellement au nombre de mots.
    """
    if not words_chunk:
        return []
    n = len(words_chunk)
    if n <= max_words:
        return [words_chunk]
    out = []
    i = 0
    while i < n:
        j = min(n, i + max_words)
        out.append(words_chunk[i:j])
        i = j
    return out


def make_segment_from_words(words_chunk: List[Dict[str, Any]]) -> Dict[str, Any]:
    start = words_chunk[0]["start"]
    end = words_chunk[-1]["end"]
    text = " ".join(w["text"] for w in words_chunk).strip()
    return {"start": start, "end": end, "text": text, "words": [w["raw"] for w in words_chunk]}


def allocate_times_proportionally(words_chunk: List[Dict[str, Any]], subchunks: List[List[Dict[str, Any]]]) -> List[Dict[str, Any]]:
    """
    Lorsque on split un segment en N subchunks, répartir la durée du segment
    proportionnellement au nombre de mots de chaque subchunk afin d'avoir timestamps cohérents.
    """
    seg_start = words_chunk[0]["start"]
    seg_end = words_chunk[-1]["end"]
    total_dur = max(1e-6, seg_end - seg_start)
    counts = [len(s) for s in subchunks]
    total = sum(counts) or 1
    acc = 0.0
    out = []
    for c, s in zip(counts, subchunks):
        proportion = c / total
        sub_start = seg_start + acc * total_dur
        acc += proportion
        sub_end = seg_start + acc * total_dur
        # clamp
        if sub_end <= sub_start:
            sub_end = sub_start + 0.05
        # assign times to words in s (we don't change word.start/end but create segment window)
        text = " ".join(w["text"] for w in s).strip()
        out.append({"start": sub_start, "end": sub_end, "text": text, "words": [w["raw"] for w in s]})
    return out


def segment_phrases_punct_based(
    aligned_segments: List[Dict[str, Any]],
    *,
    silence_threshold: float = 0.6,
    min_duration_for_punct_split: float = 1.0,
    max_words_per_segment: int = 16,
    max_segment_duration: float = 8.0,
    punctuation_chars: str = ",.?!;:",
) -> List[Dict[str, Any]]:
    """
    Découpage priorisant ponctuation + silences, fallback coupe au milieu si nécessaire.
    Règle principale:
      - On split d'abord sur silences >= silence_threshold (préserve timestamps).
      - Puis on split sur ponctuation (', . ? ! ; :').
        * On accepte la découpe sur ponctuation si segment.duration >= min_duration_for_punct_split
          ET nombre de mots <= max_words_per_segment.
      - Si un segment (entre ponctuations) est trop long (durée > max_segment_duration or words > max_words_per_segment)
        on le coupe au milieu (en blocs de max_words_per_segment) avec distribution temporelle proportionnelle.
    """
    words = flatten_aligned(aligned_segments)
    if not words:
        return []

    # 1) split on large silences (preserve timestamps here)
    chunks = []
    cur = [words[0]]
    for i in range(len(words)-1):
        cur_w = words[i]
        next_w = words[i+1]
        gap = max(0.0, next_w["start"] - cur_w["end"])
        if gap >= silence_threshold:
            chunks.append(cur)
            cur = [next_w]
        else:
            cur.append(next_w)
    if cur:
        chunks.append(cur)

    # 2) for each chunk, split by punctuation boundaries
    final_segments = []
    for chunk in chunks:
        # detect punctuation indices inside chunk
        punct_idxs = []
        for idx, w in enumerate(chunk):
            txt = w["text"]
            if txt and txt[-1] in punctuation_chars:
                punct_idxs.append(idx)
        # boundaries: start at 0, then each punct_idx -> cut after that index, then end
        boundaries = []
        last = 0
        for p in punct_idxs:
            boundaries.append((last, p))
            last = p + 1
        boundaries.append((last, len(chunk)-1))

        # build preliminary segments according to punctuation
        prelims = []
        for (a,b) in boundaries:
            sub = chunk[a:b+1]
            prelims.append(sub)

        # now decide acceptance or fallback split
        for sub in prelims:
            if not sub:
                continue
            seg_start = sub[0]["start"]
            seg_end = sub[-1]["end"]
            seg_dur = seg_end - seg_start
            n_words = len(sub)

            # If seg is short and few words -> accept even if shorter than min_duration_for_punct_split
            if seg_dur >= min_duration_for_punct_split and n_words <= max_words_per_segment:
                final_segments.append(make_segment_from_words(sub))
                continue

            # If segment is small (duration < min) but also small words -> accept
            if seg_dur < min_duration_for_punct_split and n_words <= max_words_per_segment:
                final_segments.append(make_segment_from_words(sub))
                continue

            # If segment is large (too many words or too long duration) -> split in middle into chunks of max_words_per_segment
            if n_words > max_words_per_segment or seg_dur > max_segment_duration:
                subchunks = split_segment_mid(sub, max_words_per_segment)
                # allocate times proportionally to words inside original sub
                allocated = allocate_times_proportionally(sub, subchunks)
                final_segments.extend(allocated)
                continue

            # default: accept
            final_segments.append(make_segment_from_words(sub))

    # final cleanup: ensure ordering and remove degenerate overlaps
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
                # skip degenerate
                continue
        cleaned.append(seg)

    return cleaned
