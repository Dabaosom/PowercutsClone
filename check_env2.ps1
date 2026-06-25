$mcporter = "C:\Users\Administrator\AppData\Roaming\QClaw\npm-global\node_modules\mcporter\dist\cli.js"
function Call-iOS($cmd) {
    $escaped = $cmd -replace '"', '\"'
    & node $mcporter call "ios-mcp.run_command" "command=$escaped" 2>$null
}

# 检查已安装的包
Write-Host "=== Installed Packages ==="
Call-iOS 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/var/jb/usr/bin:/var/jb/usr/sbin && apt list --installed 2>/dev/null | grep -iE "(theos|clang|git|curl|make|python3|ldid|sdk)"'

Write-Host "`n=== Available Theos ==="
Call-iOS 'ls -la /var/theos 2>/dev/null || ls -la /opt/theos 2>/dev/null || echo "no theos dir"'
