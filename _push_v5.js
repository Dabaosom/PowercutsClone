const fs = require('fs');
const { execSync } = require('child_process');
const mcporter = 'C:\\Users\\Administrator\\AppData\\Roaming\\QClaw\\npm-global\\mcporter.cmd';

const content = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\build_powercuts_v5.sh', 'utf8');
const b64 = Buffer.from(content).toString('base64');

// Split into chunks to avoid command length issues
const chunkSize = 8000;
const chunks = [];
for (let i = 0; i < b64.length; i += chunkSize) {
    chunks.push(b64.substring(i, i + chunkSize));
}

console.log(`Total b64 length: ${b64.length}, chunks: ${chunks.length}`);

// Write each chunk
for (let i = 0; i < chunks.length; i++) {
    const cmd = `echo '${chunks[i]}' >> /var/mobile/_v5_b64.txt`;
    console.log(`Pushing chunk ${i+1}/${chunks.length} (${chunks[i].length} chars)...`);
    try {
        const out = execSync(`"${mcporter}" call ios-mcp.run_command command="${cmd.replace(/"/g, '\\"')}" timeout=15`, { encoding: 'utf8', stdio: ['pipe','pipe','pipe'], timeout: 20000 });
        console.log(`Chunk ${i+1}: ${out.trim().substring(0, 100)}`);
    } catch(e) {
        console.log(`Chunk ${i+1} error: ${e.stdout ? e.stdout.trim().substring(0,200) : e.message}`);
    }
}

// Now decode and assemble
const decodeCmd = `cat /var/mobile/_v5_b64.txt | tr -d '\\n' | base64 -d > /var/mobile/build_powercuts_v5.sh && chmod +x /var/mobile/build_powercuts_v5.sh && rm /var/mobile/_v5_b64.txt && echo DONE_SIZE=$(wc -c < /var/mobile/build_powercuts_v5.sh)`;
console.log('\\nDecoding...');
try {
    const out = execSync(`"${mcporter}" call ios-mcp.run_command command="${decodeCmd.replace(/"/g, '\\"')}" timeout=15`, { encoding: 'utf8', stdio: ['pipe','pipe','pipe'], timeout: 20000 });
    console.log('Result:', out.trim());
} catch(e) {
    console.log('Decode error:', e.stdout ? e.stdout.trim().substring(0,200) : e.message);
}
