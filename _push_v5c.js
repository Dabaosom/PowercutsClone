const fs = require('fs');
const { execSync } = require('child_process');
const mcporter = 'C:\\Users\\Administrator\\AppData\\Roaming\\QClaw\\npm-global\\mcporter.cmd';

const scriptContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\build_powercuts_v5.sh', 'utf8');

// write_file accepts content parameter directly
// But content is too long for command line, so we need to use stdin or a file
// Let's try using the --input / --file approach

// Strategy: Write content to a temp file, then use mcporter with file input
const tmpContentPath = 'C:\\Users\\Administrator\\Desktop\\PowercutsClone\\_v5_content_raw.txt';
fs.writeFileSync(tmpContentPath, scriptContent, 'utf8');
console.log(`Content written to temp file: ${scriptContent.length} chars`);

// Try: Use write_file with content from file via process substitution won't work on Windows
// Instead, let's try passing content directly - mcporter might handle long args
// Or we can try the MCP approach via a small HTTP server

// Actually, let's try splitting into multiple write_file calls (append mode doesn't exist)
// So let's try writing in one shot with proper escaping

// Best approach: Use node to spawn mcporter and pipe content via stdin if supported
// Or: Use the content param but escape it for shell

// Let's try a different tactic: write the script in parts using run_command + cat heredoc
// First clear the file
try {
    execSync(`"${mcporter}" call ios-mcp.run_command command="rm -f /var/mobile/build_powercuts_v5.sh; touch /var/mobile/build_powercuts_v5.sh" timeout=10`, { encoding: 'utf8', timeout: 15000 });
    console.log('File reset on device');
} catch(e) { console.log('Reset error:', e.stdout?.trim()?.substring(0,100)); }

// Now use printf with escaped content per chunk
// The key insight: base64 encode each chunk, the b64 string only contains safe chars
const chunkSize = 3000;
const chunks = [];
for (let i = 0; i < scriptContent.length; i += chunkSize) {
    chunks.push(scriptContent.substring(i, i + chunkSize));
}

console.log(`Pushing ${chunks.length} chunks via base64...`);

for (let i = 0; i < chunks.length; i++) {
    const b64 = Buffer.from(chunks[i]).toString('base64');
    // Use printf with base64 decode - safer than echo for special chars
    const cmd = `printf '%s' '${b64}' | base64 -d >> /var/mobile/build_powercuts_v5.sh`;
    
    try {
        const out = execSync(`"${mcporter}" call ios-mcp.run_command command="${cmd}" timeout=15`, { 
            encoding: 'utf8', timeout: 20000, maxBuffer: 512 * 1024 
        });
        if ((i+1) % 2 === 0 || i === chunks.length-1) console.log(`Chunk ${i+1}/${chunks.length} done`);
    } catch(e) {
        const msg = e.stderr?.toString() || e.stdout?.toString() || e.message;
        console.log(`Chunk ${i+1} FAILED: ${msg.substring(0, 150)}`);
    }
}

// Verify
console.log('\nVerifying...');
try {
    const out = execSync(`"${mcporter}" call ios-mcp.run_command command="chmod +x /var/mobile/build_powercuts_v5.sh && wc -c /var/mobile/build_powercuts_v5.sh" timeout=10`, { encoding: 'utf8', timeout: 15000 });
    console.log('RESULT:', out.trim());
} catch(e) {
    console.log('Verify failed:', e.stdout?.toString()?.substring(0,200) || e.message);
}
