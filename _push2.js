const fs = require('fs');
const { execSync } = require('child_process');
const mcporter = 'C:\\Users\\Administrator\\AppData\\Roaming\\QClaw\\npm-global\\mcporter.cmd';

// Read the script file
const scriptContent = fs.readFileSync('C:\\Users\\Administrator\\Desktop\\PowercutsClone\\build_powercuts_v4.sh', 'utf8');

// Convert to base64
const b64 = Buffer.from(scriptContent).toString('base64');
console.log(`Script: ${scriptContent.length} chars, Base64: ${b64.length} chars`);

// Strategy: Write the base64 content to iPhone using write_file, then run_command to decode it
// But base64 is ~9KB - still large for command line. Let's split into chunks.

// Actually, let's try a different approach: use run_command with a heredoc-like approach
// Or better: write the file in chunks via multiple write_file calls... no that overwrites.

// Best approach: Write base64 to a temp file on iPhone, then decode
// The base64 string needs to be passed as the 'content' parameter

// Since mcporter key=value syntax should handle it, let's try directly
// First, let's test if we can pass ~9KB of base64 as a parameter
try {
  // Use double quotes for content - base64 is safe ASCII
  const cmd = `"${mcporter}" call ios-mcp.write_file path=/var/mobile/build_v4_b64.txt content="${b64}"`;
  console.log('Calling mcporter...');
  const result = execSync(cmd, { encoding: 'utf8', timeout: 30000 });
  console.log('Write result:', result);
  
  // Now decode on device
  const decodeCmd = `"${mcporter}" call ios-mcp.run_command command="base64 -d /var/mobile/build_v4_b64.txt > /var/mobile/build_powercuts_v4.sh && chmod +x /var/mobile/build_powercuts_v4.sh && echo DONE_\$(wc -c < /var/mobile/build_powercuts_v4.sh)"`;
  const decodeResult = execSync(decodeCmd, { encoding: 'utf8', timeout: 15000 });
  console.log('Decode result:', decodeResult);
} catch(e) {
  console.log('Error:', e.stderr?.toString() || e.message);
  console.log('stdout:', e.stdout?.toString() || '(none)');
}
