# e980-zeKrnl

## About...

Hello,

This is a port of Cyanogen's lge-kernel-gproj for one and only - LG 
Optimus G Pro. It supports all E98x variants, and I don't have a plan 
to support F240x variants for sake of reasons - first of all, I don't 
have that device, second - I don't know anything about it, so far it 
was proven that F240x is different for more than modem.

~~Currently supported Android version is 4.4, which mean all CM11.0 
based ROMs will support it. I myself I'm using it on PAC 4.4.~~

Since 07. september 2015 this kernel supports BOTH KitKat and Lollipop (CM11.0 AND CM12.1) ROMs.
Sources for both versions can be found on their branches:
- **kk-stable**, for CM11.0 and CM11.0 based ROMs
- **lp-stable**, for CM12.1 and CM12.1 based ROMs (note: haven't tested it on CM12.0, but it should work. Try it and tell me)

## Branching and versioning

Since I'm too lazy to write another README for every branch I have:

- **master** branch is used as a starting point. Highly stable, but will not be updated after v1.3
- **kk-stable** and **lp-stable** are main stable branches. Those are the ones you want to build from, and they will be updated.
- **caf/LA.AF.1.1_rb1.18** and **e980-kk-LA.AF** are pure CAF msm8960/apq8064 code, so don't try to do anything with them.
- **lp-testing** and **kk-dev** are main development branches; you may try to build something, but there is no warranty it will work.
- random branches with exp, experimental,danger,whoa etc. in names - don't touch, or kittens will die.

Current STABLE version is tagged as v1.4. Ignore the fact that there is no version 1.2.

## Progress

Current version is **v1.4**.

- [x] CPU Governors
	- [x] Intellidemand
	- [x] Intelliactive
	- [x] DanceDance
	- [x] Wheatley
	- [x] Lionheart
	- [x] SmartassV2
	- [x] Adaptive
	- [x] ondemandPLUS
- [x] Thermal control
	- [x] Thermald
	- [x] Intellithermal
	- [x] Core control
- [x] IO Schedulers
	- [x] SIO
	- [x] VR
	- [x] ZEN
- [x] TCP Congestion Algorhitm
	- [x] cubic
	- [x] reno
	- [x] westwood
	- [x] highspeed
	- [x] hybla
	- [x] htcp
	- [x] vegas
	- [x] veno
	- [x] scalable
	- [x] lp
	- [x] yeah
	- [x] illinois
- [x] CPU input boost
- [x] CPU retain policy (thanks EmmanuelU)
- [ ] Stock (LG) camera driver [reverted, missing file]
- [x] Faux sound
- [x] Fast charge
- [ ] exFAT support [in code, needs more patching]
- [x] Voltage control
- [ ] CPU overclocking
- [ ] GPU overclocking
- [x] Double tap to wake
- [x] Sweep2Wake & Sweep2Sleep
- [ ] Update to newer kernel-3.4 repos [trying to figure out how]
- [x] Support for Lollipop (CM12.x) [in testing] and later Android M [are you kidding me, it isn't even released yet]
- [ ] Additional tweaks and features -> feel free to ask & request
- [x] Ultra-cool semi-automated build script with boot.img and flashable zip generation
