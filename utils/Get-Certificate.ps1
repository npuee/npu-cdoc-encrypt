function _get-esteid-certificate {
    param(
        [string]$ID
    )
    # Set some global parameters
    $EstIDLdapURL = "esteid.ldap.sk.ee"
    $EstIDLdapPort = 636
    $EstIDLdapDN = "dc=ESTEID,c=EE"
    $NationalIDDN = "*ou=Authentication,o=Identity card of Estonian citizen,dc=ESTEID,c=EE"

    Write-Verbose "Get-Certificate called with ID='$ID'"
        # Define LDAP connection
        $ldapdn = 'LDAP://' + $EstIDLdapURL + ":" + $EstIDLdapPort + "/" + $EstIDLdapDN
        $auth = [System.DirectoryServices.AuthenticationTypes]::Anonymous
        $ldap = New-Object System.DirectoryServices.DirectoryEntry($ldapdn, $null, $null, $auth)

        # LDAP Searcher
        $ds = New-Object System.DirectoryServices.DirectorySearcher($ldap)
        $IDCodeFilter = "(serialNumber=PNOEE-$ID)"
        $ds.Filter = $IDCodeFilter
        [void]$ds.PropertiesToLoad.Add("usercertificate;binary")

        $SearchResults = $ds.FindAll()

        $certBytes = $null
        foreach ($result in $SearchResults) {
            if ($result.Path -like $NationalIDDN) {
                if ($result.Properties['usercertificate;binary'].Count -gt 0) {
                    $value = $result.Properties['usercertificate;binary'][0]
                    if ($value -is [byte[]]) {
                        $certBytes = $value
                    }
                    else {
                        try {
                            $certBytes = [System.Convert]::FromBase64String($value)
                        } catch {
                            $certBytes = [System.Text.Encoding]::Default.GetBytes($value.ToString())
                        }
                    }
                    break
                }
            }
        }
        return $certBytes
}

function _get-thales-certificate {
    param(
        [string]$ID
    )
    # Set some global parameters
    $ThalesLdapURL = "ldap-test.eidpki.ee"
    $ThalesLdapPort = 636
    $ThalesLdapDN = "dc=ESTEID,c=EE,dc=eidpki,dc=ee"
    $NationalIDDN = "*ou=Authentication,o=IdentityCardEstonianCitizen,dc=ESTEID,c=EE,dc=eidpki,dc=ee"

    Write-Verbose "Get-Certificate called with ID='$ID'"
        # Define LDAP connection
    $ldapdn = 'LDAP://' + $ThalesLdapURL + ":" + $ThalesLdapPort + "/" + $ThalesLdapDN
    $auth = [System.DirectoryServices.AuthenticationTypes]::Anonymous
    $ldap = New-Object System.DirectoryServices.DirectoryEntry($ldapdn, $null, $null, $auth)

    # LDAP Searcher
    $ds = New-Object System.DirectoryServices.DirectorySearcher($ldap)
    $IDCodeFilter = "(serialNumber=PNOEE-$ID)"
    $ds.Filter = $IDCodeFilter
    [void]$ds.PropertiesToLoad.Add("usercertificate;binary")

    $SearchResults = $ds.FindAll()
        $certBytes = $null
        foreach ($result in $SearchResults) {
            if ($result.Path -like $NationalIDDN) {
                if ($result.Properties['usercertificate;binary'].Count -gt 0) {
                    $value = $result.Properties['usercertificate;binary'][0]
                    if ($value -is [byte[]]) {
                        $certBytes = $value
                    }
                    else {
                        try {
                            $certBytes = [System.Convert]::FromBase64String($value)
                        } catch {
                            $certBytes = [System.Text.Encoding]::Default.GetBytes($value.ToString())
                        }
                    }
                    break
                }
            }
        }
        return $certBytes
}

function Get-Certificate {
    <#
    .SYNOPSIS
    Downloads a certificate identified by `ID` to a temporary location.

    .DESCRIPTION
    Resolves an 11-digit `ID` and writes the certificate bytes to a
    temporary file, returning the full path. On failure the function
    will write an error and exit with code 1.

    .PARAMETER ID
    11-digit numeric certificate identifier.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidatePattern('^\d{11}$')]
        [string]
        $ID,

        [Parameter(Mandatory=$false, Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Out
    )
        Write-Verbose "Downloading certificate from esteid.ldap.sk.ee for ID '$ID'"
        $certBytes = _get-esteid-certificate -ID $ID
        if (-not $certBytes) {
            Write-Verbose "Could not retrieve certificate for ID '$ID'"
            Write-Verbose "Tryeing to get from Thales LDAP server as fallback"
            $certBytes = _get-thales-certificate -ID $ID
        }
        if (-not $certBytes) {
            Write-Error "Could not retrieve certificate for ID '$ID'"
            exit 1
        }

        # Determine target path: use provided -Out or user's temp folder
        $tempDir = [System.IO.Path]::GetTempPath()
        $fileName = "cert_$ID.cer"
        if ($Out) {
            if (Test-Path -LiteralPath $Out -PathType Container) {
                $tempPath = [System.IO.Path]::Combine((Resolve-Path -LiteralPath $Out).ProviderPath, $fileName)
            }
            else {
                $tempPath = $Out
            }
            $parent = Split-Path -Path $tempPath -Parent
            if ($parent -and -not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }
        }
        else {
            $tempPath = [System.IO.Path]::Combine($tempDir, $fileName)
        }

        [System.IO.File]::WriteAllBytes($tempPath, $certBytes)
        Write-Verbose "Wrote certificate to $tempPath"
        return $tempPath
    }
