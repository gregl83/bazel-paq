#!/usr/bin/env python3
import json
import hashlib
import urllib.request
import sys

# repository configuration
REPO_OWNER = "gregl83"
REPO_NAME = "paq"
REPO_TAG = "v1.3.3"
API_URL = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/releases/tags/{REPO_TAG}"

# mapping repository artifacts to bazel keys
PLATFORM_MAPPING = {
    "ubuntu-x64":   {"key": "linux_x64",   "binary": "paq"},
    "ubuntu-x86":   {"key": "linux_x86",     "binary": "paq"},
    "windows-x64":  {"key": "windows_x64", "binary": "paq.exe"},
    "windows-x86":  {"key": "windows_x86",   "binary": "paq.exe"},
    "macos-x64":    {"key": "macos_x64",   "binary": "paq"},
    "macos-x86":    {"key": "macos_x86",     "binary": "paq"},
}

def get_sha256(url, filename):
    """Downloads the file from URL and calculates SHA256."""
    print(f"downloading and hashing {filename}...", file=sys.stderr)
    sha256_hash = hashlib.sha256()
    try:
        with urllib.request.urlopen(url) as response:
            while chunk := response.read(8192):
                sha256_hash.update(chunk)
        return sha256_hash.hexdigest()
    except Exception as e:
        print(f"error downloading {filename}: {e}", file=sys.stderr)
        return "ERROR_CALCULATING_SHA"

def main():
    print(f"fetching latest release from {API_URL}...", file=sys.stderr)
    
    try:
        with urllib.request.urlopen(API_URL) as response:
            data = json.loads(response.read().decode())
    except Exception as e:
        print(f"failed to fetch GitHub release: {e}", file=sys.stderr)
        sys.exit(1)

    tag_name = data.get("tag_name", "unknown")
    assets = data.get("assets", [])
    
    print(f"found release: {tag_name}", file=sys.stderr)

    results = {}
    for asset in assets:
        name = asset["name"].lower()
        url = asset["browser_download_url"]
        
        # find which platform this asset belongs to
        for identifier, info in PLATFORM_MAPPING.items():
            if identifier in name:
                sha = get_sha256(url, asset["name"])
                results[info["key"]] = {
                    "url": url,
                    "sha256": sha,
                    "binary": info["binary"]
                }
                break
    
    # generate the Python/Starlark output
    print(f"\n# generated from release: {tag_name}")
    print("PAQ_ARTIFACTS = {")
    # sort results for consistent ordering
    sorted_keys = sorted(results.keys())
    for key in sorted_keys:
        entry = results[key]
        print(f'    "{key}": {{')
        print(f'        "url": "{entry["url"]}",')
        print(f'        "sha256": "{entry["sha256"]}",')
        print(f'        "binary": "{entry["binary"]}",')
        print("    },")
    print("}")

if __name__ == "__main__":
    main()
