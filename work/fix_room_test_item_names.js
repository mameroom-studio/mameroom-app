const fs = require('fs');
const path = require('path');
const file = path.join(process.cwd(), 'test/features/home/room_page_test.dart');
let s = fs.readFileSync(file, 'utf8');
s = s.replace(/      expect\(find\.text\('[^']+'\), findsWidgets\);\r?\n      expect\(find\.text\('[^']+'\), findsWidgets\);\r?\n      expect\(find\.text\('[^']+'\), findsWidgets\);\r?\n      expect\(find\.text\('[^']+'\), findsWidgets\);\r?\n      expect\(find\.text\('[^']+'\), findsWidgets\);/, `      for (final key in [\n        'default-bed',\n        'default-desk',\n        'default-chair',\n        'default-rug',\n        'default-window',\n      ]) {\n        expect(find.byKey(ValueKey(key)), findsOneWidget);\n      }`);
fs.writeFileSync(file, s);
