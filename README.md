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

Basic `Protect-Cdoc` usage:

```powershell
Protect-Cdoc -InputFile C:\data\input.cdoc -Out C:\data\output.cdoc -ID 12345678901

Or pass input via pipeline/string:

```powershell
Get-Content C:\data\input.cdoc -Raw | Protect-Cdoc -Out C:\data\output.cdoc -ID 12345678901
```
```

Notes:
- `-ID` must be an 11-digit numeric identifier (validated by the function).
- `Protect-Cdoc` resolves the certificate by calling `Get-Certificate -ID <ID>` and
	then invokes `utils\cdoc-tool.exe --rcpt <certFile> --in <input> --out <output>`.
- `cdoc-tool.exe` is used to perform the actual CDOC protection/encryption; it must be
	present in the module `utils/` directory.
- On failure `Get-Certificate` exits with code 1 and `Protect-Cdoc` will throw an error.
By default `Protect-Cdoc` removes temporary input and downloaded certificate files after successful processing. Use `-KeepTemp` to preserve the temporary input file.

## Get-Certificate helper
`Get-Certificate -ID <11-digit> [-Out <path|directory>]` will:
- Lookup the certificate (LDAP) for the given ID,
- Save the certificate bytes to a file named `cert_<ID>.cer` in the user's temp folder (or to `-Out` if provided),
- Return the full path to the saved certificate on success, or exit with code 1 on failure.

Example:

```powershell
# Save to default temp folder
$certPath = Get-Certificate -ID 12345678901

# Save to a specific directory
$certPath = Get-Certificate -ID 12345678901 -Out C:\certs

# Save to a specific file path
$certPath = Get-Certificate -ID 12345678901 -Out C:\certs\mycert.cer
```

## Next steps
- Add unit tests and usage examples (help comments) for both functions.
- Optional: cleanup downloaded certificate files after use or provide a `-KeepCert` switch.

## Notes about manifest
`npu-cdoc-encrypt.psd1` has been updated to include files under `utils/` in `FileList`.

## Contributing
Open an issue or submit a PR with suggested changes. If you paste certificate-resolution or encryption code, I can integrate it into the module.
