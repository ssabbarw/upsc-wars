"""
preview.py
Generate a local draft and open it in a tiny HTML app.

    python preview.py --questions 6
    python preview.py --date 2026-08-16 --questions 6
    python preview.py --serve-only

Does not write Firestore, send email, or push FCM.
"""

import argparse
import os
import sys
import threading
import webbrowser
from datetime import date
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PREVIEW = ROOT / "preview"
os.chdir(ROOT)
sys.path.insert(0, str(ROOT))

from pipeline import run  # noqa: E402
from config.settings import QUESTIONS_MIN, QUESTIONS_MAX  # noqa: E402


def serve(port: int):
    PREVIEW.mkdir(parents=True, exist_ok=True)

    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(PREVIEW), **kwargs)

        def log_message(self, fmt, *args):
            print("preview:", fmt % args)

    httpd = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    url = f"http://127.0.0.1:{port}/"
    print(f"Preview server → {url}")
    threading.Timer(0.6, lambda: webbrowser.open(url)).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")


def main():
    parser = argparse.ArgumentParser(description="Local Daily CA generate + HTML preview")
    parser.add_argument("--date", default=None, help="YYYY-MM-DD (default: today)")
    parser.add_argument(
        "--questions",
        type=int,
        default=6,
        help="How many MCQs (default 6 = cheap: 1 harvest + 2 generate calls)",
    )
    parser.add_argument(
        "--serve-only",
        action="store_true",
        help="Skip generation; open the last preview/latest.json",
    )
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()

    if not QUESTIONS_MIN <= args.questions <= QUESTIONS_MAX:
        print(f"--questions must be {QUESTIONS_MIN}-{QUESTIONS_MAX}")
        sys.exit(1)

    if args.date:
        try:
            target = date.fromisoformat(args.date)
        except ValueError:
            print("Invalid --date. Use YYYY-MM-DD.")
            sys.exit(1)
    else:
        target = date.today()

    if target.weekday() == 6:
        print("Sunday has no CA pack. Pass --date for a Monday–Saturday.")
        sys.exit(1)

    if not args.serve_only:
        print(f"Generating {args.questions} questions for {target.isoformat()} (local, no Firestore)...")
        run(target, questions_target=args.questions, local=True)
        if not (PREVIEW / "latest.json").exists():
            print("Generation finished but preview/latest.json was not written.")
            sys.exit(1)

    if not (PREVIEW / "index.html").exists():
        print("Missing preview/index.html")
        sys.exit(1)

    serve(args.port)


if __name__ == "__main__":
    main()
