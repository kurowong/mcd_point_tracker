"""Perceptual hash placeholder."""

import hashlib


def phash(data: bytes) -> str:
    """Return a deterministic hash for image data.

    This implementation uses MD5 as a stand-in for a real perceptual hash.
    """
    return hashlib.md5(data).hexdigest()
