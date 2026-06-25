const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const mcporter = 'C:\\Users\\Administrator\\AppData\\Roaming\\QClaw\\npm-global\\mcporter.cmd';
const scriptPath = 'C:\\Users\\Administrator\\Desktop\\PowercutsClone\\build_powercuts_v4.sh';

// Read the script
const content = fs.readFileSync(scriptPath, 'utf8');

// Build JSON args - escape for shell
const argsObj = {
  path: '/var/mobile/build_powercuts_v4.sh',
  content: content
};

// Write args to a temp file in a safe location (no spaces, no special chars)
const argsFile = 'C:/_mcp_args.json';
fs.writeFileSync(argsFile, JSON.stringify(argsObj));

console.log(`Script size: ${content.length} bytes`);
console.log(`Args file: ${argsFile}`);
console.log(`Args preview: ${JSON.stringify(argsObj).substring(0, 100)}...`);

// Try calling via mcporter with function syntax - pass JSON as env var to avoid shell escaping
try {
  // Use environment variable to pass the complex payload
  const result = execSync(
    `"${mcporter}" call ios-mcp.write_file path=/var/mobile/build_powercuts_v4.sh --input-json "${argsFile}"`,
    {
      encoding: 'utf8',
      timeout: 30000,
      stdio: ['pipe', 'pipe', 'pipe']
    }
  );
  console.log('Result:', result);
} catch(e) {
  console.log('Error:', e.stderr?.toString() || e.message);
  
  // Fallback: try with the args directly embedded using a different approach
  console.log('\nTrying alternative approach...');
  try {
    const result2 = execSync(
      `node -e "const m=require('child_process').execSync; const a=${JSON.stringify(JSON.stringify(argsObj))}; console.log(m(\\"${mcporter.replace(/\\/g,'/')} call ios-mcp.write_file --args '+a,{encoding:'utf8',timeout:30000}).toString())"`,
      { encoding: 'utf8', timeout: 30000, stdio: ['pipe', 'pipe', 'pipe'] }
    );
    console.log('Result2:', result2);
  } catch(e2) {
    console.log('Error2:', e2.stderr?.toString() || e2.message);
  }
}
