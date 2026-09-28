#!/bin/bash
# GoToMoney brand gate for the `gotomoney` branch. Run after every `git merge upstream/main`.
#   bin/check-brand.sh <report-dir>   -> exit 0 if the rendered PDF is on-brand
#   bin/check-brand.sh --self-test    -> proves the gate passes a branded render AND fails an unbranded one
set -u
MAX_JEV=6   # attribution only: methods lede, methods heading, model ids, credit line
check() {
  local pdf="$1/report.pdf" txt fail=0
  [ -f "$pdf" ] || { echo "$pdf:0: missing report.pdf"; return 1; }
  txt=$(pdftotext "$pdf" - 2>/dev/null)
  local n; n=$(grep -ci '\bjev\b' <<<"$txt" || true)
  [ "${n:-0}" -le "$MAX_JEV" ] || { echo "$pdf:0: 'Jev' appears $n times (max $MAX_JEV): brand layer lost"; fail=1; }
  for s in "AI SEARCH READINESS CHECK" "Being readable is not the same as being cited" "hello@gotomoney.io"; do
    grep -qi -- "$s" <<<"$txt" || { echo "$pdf:0: missing brand string: $s"; fail=1; }
  done
  grep -q 'JEV-[0-9]' <<<"$txt" && { echo "$pdf:0: action ids still JEV-###"; fail=1; }
  grep -qi 'd45bb6' "$1/report.html" 2>/dev/null && { echo "$1/report.html:0: upstream magenta #d45bb6 present"; fail=1; }
  return $fail
}
if [ "${1:-}" = "--self-test" ]; then
  here=$(cd "$(dirname "$0")/.." && pwd); tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  src="${2:-$here/jev-seo-reports/gate-primion.io}"
  mkdir -p "$tmp/good" "$tmp/bad"; cp "$src/report.pdf" "$src/report.html" "$tmp/good/"
  check "$tmp/good" >/dev/null || { echo "self-test FAIL: branded render rejected"; check "$tmp/good"; exit 1; }
  # unbranded: a PDF whose text is the upstream wording
  printf 'Jev SEO audit\nJev judged\nJev judged\nJev judged\nJev judged\nJev judged\nJev judged\nJev judged\nJEV-001\n' > "$tmp/bad/t.txt"
  cupsfilter "$tmp/bad/t.txt" > "$tmp/bad/report.pdf" 2>/dev/null || python3 -c "
from weasyprint import HTML; HTML(string='<p>'+open('$tmp/bad/t.txt').read().replace(chr(10),'<br>')+'</p>').write_pdf('$tmp/bad/report.pdf')"
  check "$tmp/bad" | sed "s/^/  [expected] /"; [ ${PIPESTATUS[0]} -eq 0 ] && { echo "self-test FAIL: unbranded render accepted"; exit 1; }
  echo "self-test OK: passes branded, fails unbranded"; exit 0
fi
check "${1:?usage: check-brand.sh <report-dir> | --self-test}" && echo "brand: OK"
