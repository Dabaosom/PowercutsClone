$mcporter = "C:\Users\Administrator\AppData\Roaming\QClaw\npm-global\node_modules\mcporter\dist\cli.js"
function Call-iOS($cmd) {
    $escaped = $cmd -replace '"', '\"'
    $result = & node $mcporter call "ios-mcp.run_command" "command=$escaped" 2>$null
    return $result
}

# 1. 检查已安装的工具
Write-Host "=== Check Environment ==="
$r = Call-iOS 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/var/jb/usr/bin:/var/jb/usr/sbin && apt list --installed 2>/dev/null | grep -iE "(theos|clang|git|curl|make|python3|ldid)"'
Write-Host $r

# 2. 检查是否有 Sileo/apt 包管理器
Write-Host "`n=== Package Manager ==="
$r2 = Call-iOS 'which apt-get 2>/dev/null && echo "apt ok" || echo "no apt"'
Write-Host $r2

# 3. 检查网络
Write-Host "`n=== Network ==="
$r3 = Call-iOS 'ping -c 1 -W 2 github.com 2>&1 | head -3'
Write-Host $r3

# 4. 检查磁盘空间
Write-Host "`n=== Disk Space ==="
$r4 = Call-iOS 'df -h / 2>/dev/null || df -h /var/jb 2>/dev/null'
Write-Host $r4
