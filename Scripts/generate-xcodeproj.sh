swift package generate-xcodeproj -Xcc -I/usr/local/include -Xlinker -L/usr/local/lib/ -Xswiftc -I/usr/local/include
sed -i '' -E "s/(path = 'Sources\/)([^\']+)(')/path = 'Modules\/\2\/Sources\/\2'/" Zewo.xcodeproj/project.pbxproj
sed -i '' -E "s/(path = 'Tests\/)([^\']+)(Tests')/path = 'Modules\/\2\/Tests\/\2Tests'/" Zewo.xcodeproj/project.pbxproj
