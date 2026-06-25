const fs = require('fs');
const { execSync } = require('child_process');
const mcporter = 'C:\\Users\\Administrator\\AppData\\Roaming\\QClaw\\npm-global\\mcporter.cmd';

// Read the script content
const scriptContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\build_powercuts_v5.sh', 'utf8');

// Strategy: Use write_file tool with the raw content
// write_file takes content as parameter, so we pass it via a temp file approach
// Actually, let's try passing content directly via --input-json or similar

// Try: use echo with heredoc-like approach via bash -c on the device
// First, let's try writing in smaller pieces using append mode

// Split content into ~4000 char chunks for safe shell passing
const chunkSize = 4000;
const chunks = [];
for (let i = 0; i < scriptContent.length; i += chunkSize) {
    chunks.push(scriptContent.substring(i, i + chunkSize));
}

console.log(`Total content: ${scriptContent.length} chars, ${chunks.length} chunks`);

// Clear any existing file first
try {
    execSync(`"${mcporter}" call ios-mcp.run_command command="rm -f /var/mobile/build_powercuts_v5.sh" timeout=10`, { encoding: 'utf8', timeout: 15000 });
    console.log('Cleared existing file');
} catch(e) { /* ignore */ }

// Write each chunk using printf to avoid echo issues with special chars
for (let i = 0; i < chunks.length; i++) {
    const chunk = chunks[i];
    // Escape for shell: single quotes within content will break, so use base64 per chunk
    const chunkB64 = Buffer.from(chunk).toString('base64');
    
    const cmd = `echo '${chunkB64}' | base64 -d >> /var/mobile/build_powercuts_v5.sh`;
    console.log(`Writing chunk ${i+1}/${chunks.length} (${chunk.length} chars, b64=${chunkB64.length})...`);
    
    try {
        const out = execSync(`"${mcporter}" call ios-mcp.run_command command="${cmd.replace(/"/g, '')}" timeout=15`, { 
            encoding: 'utf8', stdio: ['pipe','pipe','pipe'], timeout: 20000,
            maxBuffer: 1024 * 1024
        });
        console.log(`  -> ${out.trim().substring(0, 80)}`);
    } catch(e) {
        const errMsg = e.stdout ? e.stdout.trim().substring(0, 200) : e.message;
        console.log(`  ERROR: ${errMsg}`);
        // Don't abort, try next chunk
    }
}

// Verify
console.log('\nVerifying...');
try {
    const out = execSync(`"${mcporter}" call ios-mcp.run_command command="chmod +x /var/mobile/build_powercuts_v5.sh && wc -c /var/mobile/build_powercuts_v5.sh" timeout=10`, { encoding: 'utf8', timeout: 15000 });
    console.log('Result:', out.trim());
} catch(e) {
    console.log('Verify error:', e.stdout ? e.stdout.trim().substring(0,200) : e.message);
}
