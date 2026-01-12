# npu-cdoc-encrypt

Lightweight PowerShell module to protect CDOC files using a certificate.

## Overview

- Primary command: `Protect-Cdoc` — entrypoint to protect a CDOC file.
- Helper: `Get-Certificate` resolves an 11-digit ID to a certificate file and saves it to disk.

## Quick start

1. Import the module from the module folder:

```powershell
Import-Module .\npu-cdoc-encrypt\npu-cdoc-encrypt.psm1
```

2. Protect a file (file mode):

```powershell
Protect-Cdoc -InputFile 'C:\data\input.txt' -Out 'C:\data\output.cdoc' -ID 12345678901
```

3. Protect content from the pipeline (string mode):

```powershell
Get-Content 'C:\data\input.txt' -Raw | Protect-Cdoc -Out 'C:\data\output.cdoc' -ID 12345678901
```

When `-Out` contains only a filename (no directory), the cmdlet will write the protected file to the system temporary directory and emit the absolute path to the created file.

## Usage & Commands

### Protect-Cdoc

Protects CDOC content using a recipient certificate resolved by an 11‑digit identifier.

```powershell
Protect-Cdoc -InputFile <String> -Out <String> -ID <String>
Protect-Cdoc -InputString <String> -Out <String> -ID <String> [-TempFileName <String>] [-KeepTemp]
```

Key behavior:

- Accepts either `-InputFile` (file mode) or `-InputString` / pipeline input (string mode).
- Resolves the recipient certificate by calling `Get-Certificate -ID <ID>` and passes the certificate file to `utils\cdoc-tool.exe`.
- If `-Out` is filename-only, output is written to the system temp directory; on success the cmdlet writes the absolute output path to the pipeline.
- Temporary files (downloaded certificate and temporary input) are removed by default unless `-KeepTemp` is used.

### Get-Certificate

Resolves an 11‑digit certificate identifier and saves the certificate to disk, returning the full path to the saved file.

```powershell
Get-Certificate -ID <String> [-Out <String>]
```

If `-Out` is a directory, the certificate is written as `cert_<ID>.cer`; if `-Out` is a file path it is used directly.

### Parameters (Protect-Cdoc)

- `-InputFile` (String): Path to an existing input file. Use this parameter or `-InputString`.
- `-InputString` (String): Raw input content. When used, a temporary `.txt` input file is created unless the pipeline provides a file.
- `-TempFileName` (String): Optional name or path for the temporary input file created when using `-InputString`.
- `-Out` (String): Destination path for the protected output CDOC file. If only a filename is provided the module uses the system temp directory. Parent directories are created automatically when needed.
- `-ID` (String): 11‑digit numeric certificate identifier (validated by regex `^\d{11}$`).
- `-KeepTemp` (Switch): Preserve temporary input file created for `-InputString`.

## Examples

### File mode

```powershell
Protect-Cdoc -InputFile 'C:\data\input.txt' -Out 'C:\data\output.cdoc' -ID 12345678901
```

### Pipeline / string mode (creates temporary .txt input)

```powershell
Get-Content 'C:\data\input.txt' -Raw | Protect-Cdoc -Out 'C:\data\output.cdoc' -ID 12345678901
```

### Write to temp by using filename-only `-Out`

```powershell
Get-Content 'C:\data\input.txt' -Raw | Protect-Cdoc -Out 'output.cdoc' -ID 12345678901
# => writes to system temp directory and prints full path, e.g. C:\Users\<user>\AppData\Local\Temp\output.cdoc
```

## Notes

- `-ID` is strictly validated to 11 numeric characters.
- The module depends on `utils\cdoc-tool.exe` to perform the protection. Ensure the `utils/` directory and required DLLs are present.
- Temporary certificate files saved to the system temp directory are removed after `cdoc-tool.exe` completes; use `-KeepTemp` only to preserve the temporary input.

## Contributing

Issues and pull requests are welcome. For integration help (certificate retrieval, additional cmdlets, automated tests), open an issue describing the change.

For implementation details, see the module manifest and implementation files in the repository.

## References

- libcdoc — The `cdoc-tool.exe` included with this module is based on the open-eid/libcdoc project (https://github.com/open-eid/libcdoc/) and has been adapted for use here. A fork containing the updated source is available at https://github.com/npuee/libcdoc.

## Changelog

See `changelog.md` for recent changes and release history.