const fs = require('fs');
const path = require('path');
const file = path.join(process.cwd(), 'test/features/home/room_page_test.dart');
let s = fs.readFileSync(file, 'utf8');
s = s.replace("    expect(find.text('침대'), findsWidgets);\n    expect(find.text('책상'), findsWidgets);\n    expect(find.text('의자'), findsWidgets);\n    expect(find.text('러그'), findsWidgets);\n    expect(find.text('창문'), findsWidgets);", "    for (final key in ['default-bed', 'default-desk', 'default-chair', 'default-rug', 'default-window']) {\n      expect(find.byKey(ValueKey(key)), findsOneWidget);\n    }\n    expect(find.text('침대'), findsWidgets);\n    expect(find.text('책상'), findsWidgets);");
fs.writeFileSync(file, s);
