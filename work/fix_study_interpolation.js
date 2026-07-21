const fs = require('fs');
const path = require('path');
const file = path.join(process.cwd(), 'lib/features/library/presentation/pages/library_page.dart');
let s = fs.readFileSync(file, 'utf8');
s = s.replace(/'\\\$\{latestMaterial\.memoryPercent\}%  \\u\{00B7\}  \\\$\{latestMaterial\.recentStudyLabel\}'/g, "'${latestMaterial.memoryPercent}%  \\u{00B7}  ${latestMaterial.recentStudyLabel}'");
s = s.replace(/'\\\$\{material\.memoryPercent\}%'/g, "'${material.memoryPercent}%'");
s = s.replace(/'\\\$\{material\.progressPercent\}%'/g, "'${material.progressPercent}%'");
fs.writeFileSync(file, s);
