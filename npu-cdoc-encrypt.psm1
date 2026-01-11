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
		# Cache commonly used paths
		$scriptUtils = Join-Path -Path $PSScriptRoot -ChildPath 'utils'
		$cdocExe = Join-Path -Path $scriptUtils -ChildPath 'cdoc-tool.exe'
		$tempPathRoot = [System.IO.Path]::GetTempPath()
		if (-not (Test-Path -LiteralPath $cdocExe)) {
			throw "cdoc-tool.exe not found at '$cdocExe'."
		}
	}

	process {
		# Determine input path: either use provided file or write InputString to a safe temp file
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
			if ($TempFileName) {
				if ([System.IO.Path]::IsPathRooted($TempFileName) -or $TempFileName.Contains('\') -or $TempFileName.Contains('/')) {
					$tempFile = $TempFileName
				}
				else {
					$tempFile = [System.IO.Path]::Combine($tempPathRoot, $TempFileName)
				}
				$parent = Split-Path -Path $tempFile -Parent
				if ($parent -and -not (Test-Path -LiteralPath $parent)) {
					New-Item -ItemType Directory -Path $parent -Force | Out-Null
				}
			}
			else {
				# Create an atomic temp file and give it a .txt extension
				$tmp = [System.IO.Path]::GetTempFileName()
				$tempFile = [System.IO.Path]::ChangeExtension($tmp, '.txt')
				try { Move-Item -LiteralPath $tmp -Destination $tempFile -Force } catch { }
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

		# Resolve certificate file using helper with structured error handling
		try {
			$certPath = Get-Certificate -ID $ID
		}
		catch {
			throw "Failed to resolve certificate for ID '$ID': $($_.Exception.Message)"
		}
		if (-not $certPath) {
			throw "Failed to resolve certificate for ID '$ID'."
		}

		# Execute cdoc-tool directly and check exit code
		$argList = @('--rcpt', $certPath, '--in', $inPath, '--out', $Out)
		try {
			& $cdocExe @argList
			if ($LASTEXITCODE -ne 0) {
				throw "cdoc-tool.exe failed with exit code $LASTEXITCODE."
			}
			Write-Verbose "cdoc-tool.exe completed successfully; output at '$Out'"
			# Emit the output file path so callers can pipe the result
			Write-Output $Out
		}
		finally {
			$cleanupCert = ($certPath -and $tempPathRoot -and $certPath.StartsWith($tempPathRoot, [System.StringComparison]::OrdinalIgnoreCase))
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

