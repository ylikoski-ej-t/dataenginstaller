Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
function Update-EnvVar() {
	$ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User");
}

function Get-PythonInstallerUri() {
	$python_uri_to_downloads_page = "https://www.python.org/downloads/windows/";
	$webpage_contents = (invoke-webrequest $python_uri_to_downloads_page).Content;
	$first_link_that_matches = ($webpage_contents | Select-String -Pattern "https://www.python.org/ftp/python/.*?exe").Matches.Value;
	return $first_link_that_matches
}

function Download-Installer {

    param (
        [string] $uri,
        [string] $path,
        [string] $name
    )
    
    $outFile = Join-Path -Path $path -ChildPath $name

    if (!(Test-Path $path)) { New-Item -Path $path -ItemType Directory }
    Invoke-WebRequest -Uri $uri -OutFile $outFile
}

function Execute-Installer($path, $installer_name) {
	Start-Process $path"\"$installer_name -ArgumentList "/passive PrependPath=1 InstallLauncherAllUsers=0" -Wait
}

function Install-Databricks() {
	winget install Databricks.DatabricksCLI --accept-source-agreements ----accept-package-agreements
}

function Install-Poetry() {
	(Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | py -
	
	# Expand %appdata% to extract a full path to Poetry's bin's directory
	$poetry_env_path = [system.environment]::ExpandEnvironmentVariables("%appdata%\Python\Scripts\poetry")
	
	# Update envvar to include Poetry
	[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\Users\WDAGUtilityAccount\AppData\Roaming\Python\Scripts", "User")
}

$temp_directory_for_downloads = "C:\temp\";
$python_installer_uri = Get-PythonInstallerUri;
$python_installer_name = $python_installer_uri.Split("/")[-1]

Download-Installer -uri $python_installer_uri -path $temp_directory_for_downloads -name $python_installer_name;
Execute-Installer -path $temp_directory_for_downloads -installer_name $python_installer_name;

Install-Databricks;

# Environment variables must be updated so that Poetry's install script can be executed by piping to "py -"
Update-EnvVar;

Install-Poetry;

Update-EnvVar;

Write-Host "All three applications should now print their version numbers"

python --version;
databricks --version;
poetry --version;

Write-Host -NoNewline "Press any key to continue..."
$_ = [System.Console]::ReadKey()