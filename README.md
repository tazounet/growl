# growl
Lastest code from code.google.com/p/growl with
- Build on XCode 6
- Update to 10.8 target
- Use ARC
- Add GraphicCardMonitor plugin (using code from gfxCardStatus)
- Add AudioMonitor plugin (output/input/jack notification)

# build
$ cd Release

$ VERSION=x.x.x rake setup

$ VERSION=x.x.x rake build:growl

$ HWG_VERSION=x.x.x rake build:hardwaregrowler

