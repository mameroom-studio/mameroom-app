const fs = require('fs');
const path = require('path');
const file = path.join(process.cwd(), 'test/features/home/room_page_test.dart');
let s = fs.readFileSync(file, 'utf8');
s = s.replace('List<Override> _overrides(MyRoomState room) {', 'List<Object> _overrides(MyRoomState room) {');
s = s.replace(/\\\$\{size\.width\}/g, '${size.width}');
s = s.replace(/\\\$\{size\.height\}/g, '${size.height}');
fs.writeFileSync(file, s);
