# growl
Lastest code from code.google.com/p/growl with
- Build on XCode 5.0.2
- Add GraphicCardMonitor plugin (using code from gfxCardStatus)

Install XCode 5.0.2 in /Applications/Xcode5.app
$ sudo xcode-select -s /Applications/Xcode5.app/Contents/Developer
$ cd Release  
$ VERSION=2.1.1 rake setup 
$ VERSION=2.1.1 rake build:growl
$ rake build:hardwaregrowler
