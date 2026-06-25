const fs = require('fs');
const { execSync } = require('child_process');
const mcporter = 'C:\\Users\\Administrator\\AppData\\Roaming\\QClaw\\npm-global\\mcporter.cmd';

const scriptContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\build_powercuts_v4.sh', 'utf8');
const b64 = Buffer.from(scriptContent).toString('base64');

// Split base64 into 2KB chunks
const CHUNK_SIZE = 2000;
const chunks = [];
for (let i = 0; i < b64.length; i += CHUNK_SIZE) {
  chunks.push(b64.substring(i, i + CHUNK_SIZE));
}
console.log(`Total b64: ${b64.length}, chunks: ${chunks.length}`);

function mcCall(toolAndArgs) {
  const cmd = `"${mcporter}" call ${toolAndArgs}`;
  // console.log(`CMD: ${cmd.substring(0, 120)}...`);
  try {
    return execSync(cmd, { encoding: 'utf8', timeout: 30000 });
  } catch(e) {
    const err = e.stderr?.toString() || e.message;
    console.log(`ERR: ${err.substring(0, 200)}`);
    throw e;
  }
}

try {
  // Step 1: Write each chunk as a separate file
  for (let i = 0; i < chunks.length; i++) {
    console.log(`Writing chunk ${i+1}/${chunks.length} (${chunks[i].length} chars)...`);
    mcCall(`ios-mcp.write_file path=/var/mobile/b64_chunk_${i}.txt content="${chunks[i]}"`);
  }
  
  // Step 2: Concatenate and decode on device
  console.log('Concatenating and decoding...');
  const chunkFiles = chunks.map((_, i) => `/var/mobile/b64_chunk_${i}.txt`).join(' ');
  const concatCmd = `cat ${chunkFiles} > /var/mobile/b64_full.txt && base64 -d /var/mobile/b64_full.txt > /var/mobile/build_powercuts_v4.sh && chmod +x /var/mobile/build_powercuts_v4.sh && rm -f /var/mobile/b64_chunk_*.txt /var/mobile/b64_full.txt && echo "DONE_\$(wc -c < /var/mobile/build_powercuts_v4.sh)"`;
  
  const result = mcCall(`ios-mcp.run_command command="${concatCmd}"`);
  console.log('Final result:', result);
} catch(e) {
  process.exit(1);
}
