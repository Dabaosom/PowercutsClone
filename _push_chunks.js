const fs = require('fs');
const { execSync } = require('child_process');
const mcporter = 'C:\\Users\\Administrator\\AppData\\Roaming\\QClaw\\npm-global\\mcporter.cmd';

const scriptContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\build_powercuts_v5.sh', 'utf8');

// Split into 2000-byte chunks (safe for write_file)
const CHUNK_SIZE = 2000;
const chunks = [];
for (let i = 0; i < scriptContent.length; i += CHUNK_SIZE) {
    chunks.push(scriptContent.substring(i, i + CHUNK_SIZE));
}

console.log(`Total: ${scriptContent.length} chars, ${chunks.length} chunks (${CHUNK_SIZE} chars each)`);

// Write each chunk to a temp file on the device
for (let i = 0; i < chunks.length; i++) {
    const chunkFile = `/var/mobile/_chunk_${String(i).padStart(3,'0')}.txt`;
    console.log(`Writing chunk ${i+1}/${chunks.length} to ${chunkFile}...`);
    
    try {
        // Use write_file tool with content parameter
        const result = execSync(
            `"${mcporter}" call ios-mcp.write_file path="${chunkFile}" content="${chunks[i].replace(/"/g, '\\"')}" timeout=20`,
            { encoding: 'utf8', timeout: 30000, maxBuffer: 512*1024 }
        );
        console.log(`  -> OK (${(JSON.parse(result) || {}).bytes_written || '?'} bytes)`);
    } catch(e) {
        const errMsg = e.stdout ? e.stdout.toString().substring(0, 150) : e.message.substring(0, 150);
        console.log(`  ERROR: ${errMsg}`);
        // If write_file fails, try run_command with base64
        try {
            const b64 = Buffer.from(chunks[i]).toString('base64');
            const r = execSync(
                `"${mcporter}" call ios-mcp.run_command command="echo '${b64}' | base64 -d > ${chunkFile}" timeout=20`,
                { encoding: 'utf8', timeout: 30000, maxBuffer: 512*1024 }
            );
            console.log(`  -> base64 fallback OK`);
        } catch(e2) {
            console.log(`  base64 fallback FAILED: ${e2.stdout ? e2.stdout.toString().substring(0,100) : e2.message.substring(0,100)}`);
        }
    }
}

// Now create a combine script on the device
console.log('\nCreating combine script...');
const combineScript = `#!/bin/bash
# Combine all chunks into the final script
cat /var/mobile/_chunk_*.txt > /var/mobile/build_powercuts_v5.sh
chmod +x /var/mobile/build_powercuts_v5.sh
rm -f /var/mobile/_chunk_*.txt
echo "Combined! Size: $(wc -c < /var/mobile/build_powercuts_v5.sh) bytes"
ls -la /var/mobile/build_powercuts_v5.sh
`;

try {
    const r = execSync(
        `"${mcporter}" call ios-mcp.write_file path="/var/mobile/_combine.sh" content="${combineScript.replace(/"/g, '\\"')}" timeout=10`,
        { encoding: 'utf8', timeout: 15000 }
    );
    console.log('Combine script written!');
    console.log('\nNow run these commands on your device SSH session:');
    console.log('  bash /var/mobile/_combine.sh');
    console.log('  bash /var/mobile/build_powercuts_v5.sh');
} catch(e) {
    console.log('Failed to write combine script:', e.message.substring(0, 150));
}
