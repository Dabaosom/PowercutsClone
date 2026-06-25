const fs = require('fs');
const { execSync, spawn } = require('child_process');
const mcporter = 'C:\\Users\\Administrator\\AppData\\Roaming\\QClaw\\npm-global\\mcporter.cmd';

const scriptContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\build_powercuts_v5.sh', 'utf8');
console.log(`Content size: ${scriptContent.length} chars`);

// Use write_file tool which accepts content as a named parameter
// We'll call it via spawn to avoid command line length limits and escaping issues
// mcporter call ios-mcp.write_file path="/var/mobile/build_powercuts_v5.sh" content="..."

// Since content is 14KB, we need to pass it carefully
// Let's try using --input-json or writing to mcporter's stdin

// Approach: Write a JSON args file and pipe it
const argsJson = JSON.stringify({
    path: "/var/mobile/build_powercuts_v5.sh",
    content: scriptContent
});

const argsFile = 'C:\\Users\\Administrator\\Desktop\\PowercutsClone\\_write_args.json';
fs.writeFileSync(argsFile, argsJson, 'utf8');
console.log(`Args JSON: ${argsJson.length} chars written to ${argsFile}`);

// Try: mcporter call with json input from file
try {
    // Use stdin approach: echo the JSON and pipe to mcporter... but that won't work either
    // Let's just try direct call - Node.js handles long args better than shell
    const result = execSync(`"${mcporter}" call ios-mcp.write_file path="/var/mobile/build_powercuts_v5.sh" content="${scriptContent.replace(/"/g, '\\"')}" timeout=30`, {
        encoding: 'utf8',
        timeout: 60000,
        maxBuffer: 1024 * 1024,
        stdio: ['pipe', 'pipe', 'pipe']
    });
    console.log('SUCCESS:', result.trim());
} catch(e) {
    console.log('Direct call failed:', e.stdout?.toString()?.substring(0,300) || e.message);
    
    // Fallback: Try using spawn with args array to avoid shell escaping
    console.log('\nTrying spawn approach...');
    try {
        const proc = spawn(mcporter, [
            'call', 'ios-mcp.write_file',
            `path=/var/mobile/build_powercuts_v5.sh`,
            `content=${scriptContent}`
        ], {
            timeout: 60000,
            stdio: ['pipe', 'pipe', 'pipe']
        });
        
        let stdout = '', stderr = '';
        proc.stdout.on('data', d => stdout += d.toString());
        proc.stderr.on('data', d => stderr += d.toString());
        
        proc.on('close', (code) => {
            console.log(`Spawn exit code: ${code}`);
            console.log('STDOUT:', stdout.substring(0, 500));
            if (stderr) console.log('STDERR:', stderr.substring(0, 300));
        });
        
        proc.on('error', (err) => {
            console.log('Spawn error:', err.message);
        });
        
        // Wait for completion
        setTimeout(() => {
            console.log('\nTimeout reached, checking result...');
            try {
                const verify = execSync(`"${mcporter}" call ios-mcp.run_command command="chmod +x /var/mobile/build_powercuts_v5.sh && wc -c /var/mobile/build_powercuts_v5.sh" timeout=10`, { encoding: 'utf8', timeout: 15000 });
                console.log('Verify:', verify.trim());
            } catch(e2) {
                console.log('Verify error:', e2.stdout?.toString()?.substring(0,200));
            }
        }, 45000);
        
    } catch(e2) {
        console.log('Spawn failed:', e2.message);
    }
}
