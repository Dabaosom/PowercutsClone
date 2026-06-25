$mcporter = "C:\Users\Administrator\AppData\Roaming\QClaw\npm-global\node_modules\mcporter\dist\cli.js"
function Call-iOS($cmd) {
    $escaped = $cmd -replace '"', '\"'
    & node $mcporter call "ios-mcp.run_command" "command=$escaped" 2>$null
}

Write-Host "[1/6] Updating apt..."
Call-iOS 'export DEBIAN_FRONTEND=noninteractive && apt-get update -y 2>&1 | tail -5'

Write-Host "`n[2/6] Installing build tools (make, clang, ldid, git, curl)..."
Call-iOS 'export DEBIAN_FRONTEND=noninteractive && apt-get install -y make clang ldid git curl 2>&1 | tail -10'

Write-Host "`n[3/6] Installing Theos..."
Call-iOS 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/var/jb/usr/bin:/var/jb/usr/sbin && git clone --recursive https://github.com/theos/Theos.git /var/theos 2>&1 | tail -10'

Write-Host "`n[4/6] Verifying Theos..."
Call-iOS 'ls /var/theos/bin/ 2>/dev/null || echo "checking..."'
Call-iOS 'export THEOS=/var/theos && export PATH=$THEOS/bin:$PATH && which nic 2>/dev/null && echo "Theos OK" || echo "Theos FAIL"'
