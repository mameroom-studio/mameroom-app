const fs = require('fs');
const path = require('path');
const file = path.join(process.cwd(), 'lib/features/gamification/presentation/pages/room_page.dart');
let s = fs.readFileSync(file, 'utf8');
s = s.replace("key: ValueKey('room-sprite-\\${item.id}'),", "key: ValueKey(item.id),");
s = s.replace("'shelf' => Icons.shelves,", "'shelf' => Icons.library_books_rounded,");
fs.writeFileSync(file, s);
