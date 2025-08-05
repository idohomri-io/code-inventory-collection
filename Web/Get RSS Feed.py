#!/usr/bin/env python3
"""
rss_reader.py

Synopsis:
    Fetch and parse an RSS/Atom feed from a specified URL and display its entries.

Description:
    This script retrieves the content of an RSS or Atom feed given its URL,
    parses it, and prints out the titles, links, and summaries of each entry.
    It handles HTTP errors and malformed feeds gracefully, exiting with an
    appropriate error message on failure.

Use Cases:
    1. Automate monitoring of blog or news updates in your terminal.
    2. Integrate into larger Python automation workflows to fetch the latest
       entries before processing them further.
    3. Run periodically via cron to build a local archive or trigger downstream
       notifications.

Examples:
    $ python rss_reader.py https://example.com/feed.xml
    $ python rss_reader.py https://example.com/feed.xml -n 5

Copyright:
    Ido homri (ido@idohomri.io)
    https://inventory.idohomri.io
"""

import argparse
import sys
import requests
import feedparser


def fetch_rss_feed(url):
    """
    Fetch the RSS/Atom feed from the specified URL.

    :param url: URL of the RSS or Atom feed.
    :type url: str
    :return: Parsed feed object.
    :rtype: feedparser.FeedParserDict
    :raises RuntimeError: On HTTP errors or parse failures.
    """
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
    except requests.RequestException as e:
        raise RuntimeError(f"Error fetching RSS feed: {e}")

    feed = feedparser.parse(response.content)
    if feed.bozo:
        # bozo_exception holds the underlying parse error
        raise RuntimeError(f"Error parsing RSS feed: {feed.bozo_exception}")
    return feed


def display_feed_entries(feed, limit=None):
    """
    Display entries from the parsed feed.

    :param feed: FeedParserDict returned by feedparser.
    :param limit: Maximum number of entries to display (None for all).
    :type limit: int or None
    """
    entries = feed.entries
    if not entries:
        print("No entries found in RSS feed.")
        return

    count = min(len(entries), limit) if limit is not None else len(entries)
    for idx, entry in enumerate(entries[:count], start=1):
        print(f"{idx}. {entry.title}")
        print(f"   Link: {entry.link}")
        if hasattr(entry, "summary"):
            print(f"   Summary: {entry.summary}")
        print()


def parse_args():
    """
    Parse command-line arguments.

    :return: Namespace with 'url' and optional 'number'.
    """
    parser = argparse.ArgumentParser(
        description="Fetch and display RSS/Atom feed entries from a given URL."
    )
    parser.add_argument(
        "url", help="The URL of the RSS or Atom feed to fetch."
    )
    parser.add_argument(
        "-n", "--number",
        type=int,
        default=None,
        help="Maximum number of entries to display (default: all)."
    )
    return parser.parse_args()


def main():
    """
    Main entry point: parse arguments, fetch the feed, and display entries.
    """
    args = parse_args()

    try:
        feed = fetch_rss_feed(args.url)
    except RuntimeError as err:
        print(err, file=sys.stderr)
        sys.exit(1)

    display_feed_entries(feed, args.number)


if __name__ == "__main__":
    main()
