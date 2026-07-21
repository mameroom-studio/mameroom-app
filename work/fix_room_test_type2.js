const fs = require('fs');
const path = require('path');
const file = path.join(process.cwd(), 'test/features/home/room_page_test.dart');
let s = fs.readFileSync(file, 'utf8');
s = s.replace('List<Object> _overrides(MyRoomState room) {', '_overrides(MyRoomState room) {');
fs.writeFileSync(file, s);
