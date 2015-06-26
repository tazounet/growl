# growl
Lastest code from code.google.com/p/growl with
- Build on XCode 6
- Update to 10.8 target
- Use ARC
- Add GraphicCardMonitor plugin (using code from gfxCardStatus)

# build
$ cd Release  
$ VERSION=2.1.3 rake setup
$ VERSION=2.1.3 rake build:growl
$ rake build:hardwaregrowler
