. "$PSScriptRoot\utils\Get-Certificate.ps1"

function Protect-Cdoc {
	<#
	.SYNOPSIS
	Protects a CDOC using a certificate resolved by ID.

	.DESCRIPTION
	Resolves an 11-digit certificate `ID` using `Get-Certificate`, then
	invokes the bundled `utils\cdoc-tool.exe` with the resolved certificate
	(`--rcpt`), input (`--in`) and output (`--out`) paths to perform the
	actual protection operation. Validates parameters and ensures output
	directory exists. Throws on failure.

	.PARAMETER InputFile
	Path to the input file to protect (use in file mode).

	.PARAMETER InputString
	Input content as a string. Use this parameter or pipe string content to the function.

	.PARAMETER Out
	Path where the protected file will be written.

	.PARAMETER KeepTemp
	Switch to keep the temporary input file created when using `-InputString`.



	.PARAMETER ID
	11-digit certificate identifier. The function will call `Get-Certificate -ID <ID>` to
	resolve and download the certificate, then pass the certificate file to
	`cdoc-tool.exe` as `--rcpt`.

	.EXAMPLE
	Protect-Cdoc -In C:\data\file.cdoc -Out C:\out\file.cdoc -ID 12345678901
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true, ParameterSetName='File')]
		[ValidateNotNullOrEmpty()]
		[string]
		$InputFile,

		[Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ParameterSetName='String')]
		[ValidateNotNullOrEmpty()]
		[string]
		$InputString,

		[Parameter(Mandatory=$false, ParameterSetName='String')]
		[ValidateNotNullOrEmpty()]
		[string]
		$TempFileName,

		[Parameter(Mandatory=$true, Position=1)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Out,

		[Parameter(Mandatory=$true)]
		[ValidatePattern('^\d{11}$')]
		[string]
		$ID,
		[Parameter()]
		[switch]
		$KeepTemp


	)

	begin {
		Write-Verbose "Protect-Cdoc called with InputFile='$InputFile' InputString='${InputString}' Out='$Out' ID='$ID' (ParameterSet=$($PSCmdlet.ParameterSetName))"
	}

	process {
		# Determine input path: either use provided file or write InputString to temp file
		$inPath = $null
		$cleanupInput = $false
		if ($PSCmdlet.ParameterSetName -eq 'File') {
			if (-not (Test-Path -Path $InputFile)) {
				throw "Input path '$InputFile' was not found."
			}
			$inPath = $InputFile
		}
		else {
			# ParameterSet 'String' - write InputString to temp file
			$tempDir = [System.IO.Path]::GetTempPath()
			if ($TempFileName) {
				# If TempFileName looks like a path use it directly, otherwise combine with temp dir
				if ([System.IO.Path]::IsPathRooted($TempFileName) -or $TempFileName.Contains('\') -or $TempFileName.Contains('/')) {
					$tempFile = $TempFileName
				}
				else {
					$tempFile = [System.IO.Path]::Combine($tempDir, $TempFileName)
				}
				$parent = Split-Path -Path $tempFile -Parent
				if ($parent -and -not (Test-Path -LiteralPath $parent)) {
					New-Item -ItemType Directory -Path $parent -Force | Out-Null
				}
			}
			else {
				$tempFile = [System.IO.Path]::Combine($tempDir, "cdoc_input_$([guid]::NewGuid().ToString()).txt")
			}
			Set-Content -Path $tempFile -Value $InputString -Encoding utf8
			$inPath = $tempFile
			# only cleanup the temp input file if user didn't request to keep it
			$cleanupInput = -not $KeepTemp.IsPresent
		}

		$outDir = Split-Path -Path $Out -Parent
		if ($outDir -and -not (Test-Path -Path $outDir)) {
			New-Item -ItemType Directory -Path $outDir -Force | Out-Null
		}

		# Resolve certificate file using helper
		$certPath = Get-Certificate -ID $ID
		if (-not $certPath) {
			throw "Failed to resolve certificate for ID '$ID'."
		}

		# Locate cdoc-tool executable
		$cdocExe = Join-Path -Path $PSScriptRoot -ChildPath 'utils\cdoc-tool.exe'
		if (-not (Test-Path -Path $cdocExe)) {
			throw "cdoc-tool.exe not found at '$cdocExe'."
		}

		# Execute cdoc-tool with required arguments and cleanup downloaded cert if it was saved to temp
		# By default we remove cert and temp input files; pass -KeepTemp to preserve the temp input file.
		$tempPathRoot = [System.IO.Path]::GetTempPath()
		$cleanupCert = ($certPath -and $tempPathRoot -and $certPath.StartsWith($tempPathRoot, [System.StringComparison]::OrdinalIgnoreCase))

		$argList = @('--rcpt', $certPath, '--in', $inPath, '--out', $Out)
		try {
			$proc = Start-Process -FilePath $cdocExe -ArgumentList $argList -NoNewWindow -Wait -PassThru
			if ($proc.ExitCode -ne 0) {
				throw "cdoc-tool.exe failed with exit code $($proc.ExitCode)."
			}
			Write-Verbose "cdoc-tool.exe completed successfully; output at '$Out'"
			# Emit the output file path so callers can pipe the result
			Write-Output $Out
		}
		finally {
			if ($cleanupCert -and (Test-Path -LiteralPath $certPath)) {
				Write-Verbose "Removing temporary certificate file '$certPath'"
				Remove-Item -LiteralPath $certPath -Force -ErrorAction SilentlyContinue
			}
			if ($cleanupInput -and $inPath -and (Test-Path -LiteralPath $inPath)) {
				Write-Verbose "Removing temporary input file '$inPath'"
				Remove-Item -LiteralPath $inPath -Force -ErrorAction SilentlyContinue
			}
		}
	}
}

