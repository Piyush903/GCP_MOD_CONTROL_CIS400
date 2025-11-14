import os
import re
import requests

# === CONFIGURATION ===
BASE_DIR = "/home/piyushnijhawan/Desktop/steampipe-mod-gcp-compliance/cis_v400"
SECTION_FILES = [f"section_{i}.pp" for i in range(1, 9)]
API_URL = (
    "https://hub.powerpipe.io/_next/data/FWYujAHFxTpSfmxybbYRO/"
    "mods/turbot/steampipe-mod-gcp-compliance/queries/{query}.json"
    "?org=turbot&name=steampipe-mod-gcp-compliance&query={query}"
)

CONTROL_BLOCK_RE = re.compile(
    r'(control\s+"[^"]+"\s*{[^}]*?query\s*=\s*query\.(\w+)[^}]*})', re.DOTALL
)

def fetch_query_sql(query_name):
    """Fetch SQL query text from Powerpipe API."""
    url = API_URL.format(query=query_name)
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            data = response.json()
            return data.get("pageProps", {}).get("query", {}).get("sql")
        else:
            print(f"⚠️  Skipped {query_name}: HTTP {response.status_code}")
    except Exception as e:
        print(f"❌  Error fetching {query_name}: {e}")
    return None


def inject_sql_to_control_block(block_text, sql):
    """
    Insert SQL as 'query_source' after 'query =' line using double quotes.
    Multiline SQL will be flattened into one line with escaped quotes.
    """
    if not sql:
        return block_text

    # Flatten SQL into a single line, escape double quotes and backslashes
    flattened_sql = " ".join(sql.splitlines())
    flattened_sql = flattened_sql.replace("\\", "\\\\").replace('"', '\\"').strip()

    def replacement(match):
        return f'{match.group(1)}\n\n  query_source  = "{flattened_sql}"'

    return re.sub(r'(query\s*=\s*query\.\w+)', replacement, block_text, count=1)


def process_file(file_path):
    """Process a single .pp file and inject SQL queries."""
    print(f"🔍 Processing {file_path}")
    with open(file_path, "r") as f:
        content = f.read()

    new_content = content
    matches = CONTROL_BLOCK_RE.findall(content)

    for full_block, query_name in matches:
        print(f"➡️  Found query: {query_name}")
        sql = fetch_query_sql(query_name)
        if sql:
            updated_block = inject_sql_to_control_block(full_block, sql)
            new_content = new_content.replace(full_block, updated_block)
        else:
            print(f"⚠️  No SQL found for {query_name}")

    # Backup and overwrite
    backup_path = file_path + ".bak"
    os.rename(file_path, backup_path)
    with open(file_path, "w") as f:
        f.write(new_content)

    print(f"✅ Updated {file_path} (backup saved as {backup_path})\n")


if __name__ == "__main__":
    for filename in SECTION_FILES:
        file_path = os.path.join(BASE_DIR, filename)
        if os.path.exists(file_path):
            process_file(file_path)
        else:
            print(f"⚠️  File not found: {file_path}")
