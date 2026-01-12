# Changelog

## 0.1.1 — 2026-01-12

- Changed: `Protect-Cdoc` now returns the absolute path of the protected output file (uses `[System.IO.Path]::GetFullPath`).
- Changed: When `-Out` contains only a filename (no directory), `Protect-Cdoc` writes the protected file into the system temporary directory and returns the full path.
- Changed: Verbose messaging updated to indicate when `-Out` was rewritten to the temp directory.
- Updated: `README.md` to document the new behaviors and include an example writing to the temp directory.

Files modified:

- `npu-cdoc-encrypt.psm1` — compute and emit absolute output path; write to temp when `-Out` is filename-only.
- `README.md` — document behavior and add example.

Example usage (writes to temp when `-Out` is filename-only):

```powershell
Get-Content 'C:\data\input.txt' -Raw | Protect-Cdoc -Out 'output.cdoc' -ID 12345678901
# => prints full path, e.g. C:\Users\<user>\AppData\Local\Temp\output.cdoc
```
