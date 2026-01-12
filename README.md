# npu-cdoc-encrypt

Lightweight PowerShell module to protect CDOC files using a certificate.

## Overview
- Primary command: `Protect-Cdoc` — entrypoint to protect a CDOC file.
- Helper: `Get-Certificate` (in `utils/`) — resolves an 11-digit ID to a certificate file and saves it to disk.

## Files of interest
- Module: npu-cdoc-encrypt.psm1
- Manifest: npu-cdoc-encrypt.psd1
- Helper: utils/Get-Certificate.ps1

## Usage
Import the module (from the module folder):

```powershell
Import-Module .\npu-cdoc-encrypt.psm1
```

# npu-cdoc-encrypt

This PowerShell module provides the `Protect-Cdoc` cmdlet to protect (encrypt) CDOC files using an X.509 certificate resolved by an 11‑digit identifier.

## Synopsis

Protects a CDOC using a certificate identified by an 11‑digit ID and the bundled `cdoc-tool.exe` utility.

## Syntax

```powershell
Protect-Cdoc -InputFile <String> -Out <String> -ID <String>

Protect-Cdoc -InputString <String> -Out <String> -ID <String> [-TempFileName <String>] [-KeepTemp]
```

## Description

`Protect-Cdoc` accepts either a path to an input file (`-InputFile`) or raw content via `-InputString`/pipeline, resolves a recipient certificate by calling `Get-Certificate -ID <ID>`, and invokes `utils\cdoc-tool.exe` with the arguments `--rcpt <certFile> --in <input> --out <output>` to perform protection. If the `-Out` value contains only a filename (no directory), the protected file is written to the system temporary directory. On success the cmdlet writes the absolute path to the created output file to the pipeline. Temporary files (downloaded certificate and temporary input) are removed by default.

## Files of interest

- Module: `npu-cdoc-encrypt.psm1`
- Manifest: `npu-cdoc-encrypt.psd1`
- Helper: `Get-Certificate.psm1`
- Bundled tool: `utils/cdoc-tool.exe` (and supporting DLLs)

## Parameters

- `-InputFile` (String) — Path to an existing CDOC input file. Use this parameter or `-InputString`.
- `-InputString` (String) — Raw input content. When used, a temporary `.txt` input file is created unless the pipeline provides a file.
- `-TempFileName` (String) — Optional name or path for the temporary input file created when using `-InputString`.
- `-Out` (String) — Destination path for the protected output CDOC file. If `-Out` contains only a filename (no directory), the module will write the output into the system temporary directory. Parent directories are created if needed. The cmdlet emits the absolute path to the created output file on success.
- `-ID` (String) — 11‑digit numeric certificate identifier. Validated by the cmdlet (regex `^\d{11}$`).
- `-KeepTemp` (Switch) — Preserve the temporary input file created for `-InputString`.

## Get-Certificate

`Get-Certificate -ID <String> [-Out <String>]` resolves an 11‑digit ID to a certificate, saves it to disk, and returns the full path to the saved certificate file. If `-Out` is provided and is a directory the certificate will be written as `cert_<ID>.cer`; if `-Out` is a file path it is used directly. On failure the helper exits with code `1`.

## Examples

# File mode
```powershell
Import-Module .\npu-cdoc-encrypt.psm1
Protect-Cdoc -InputFile 'C:\data\input.cdoc' -Out 'C:\data\output.cdoc' -ID 12345678901
```

# Pipeline / string mode (creates temporary .txt input)
```powershell
Get-Content 'C:\data\input.txt' -Raw | Protect-Cdoc -Out 'C:\data\output.cdoc' -ID 12345678901
```

# Provide a custom temporary filename and keep it
```powershell
Get-Content 'C:\data\input.txt' -Raw | Protect-Cdoc -Out 'C:\data\output.cdoc' -ID 12345678901 -TempFileName 'C:\temp\myinput.txt' -KeepTemp
```

## Notes

- `-ID` is strictly validated to 11 numeric characters.
- The module depends on `utils\cdoc-tool.exe` to perform the protection. Ensure the `utils/` directory and required DLLs are present.
- Temporary certificate files saved to the system temp directory are removed after `cdoc-tool.exe` completes; use `-KeepTemp` only to preserve the temporary input.

## Contributing

Issues and pull requests are welcome. For integration help (certificate retrieval, additional cmdlets, automated tests), open an issue describing the change.

For more details, see the module manifest (`npu-cdoc-encrypt.psd1`) and implementation (`npu-cdoc-encrypt.psm1`).

## References

- libcdoc — The `cdoc-tool.exe` included with this module is based on the open-eid/libcdoc project (https://github.com/open-eid/libcdoc/) and has been adapted for use here. A fork containing the updated source and compiled binaries is available at https://github.com/npuee/libcdoc.

