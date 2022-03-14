# SitumWayfinding develompent

## Enable localizations in apps 
In order to see the localizations of the module WayFinding in the app, you must configure localization for the languages
that you need to support. To do that in your app go to Project (click on root folder in project navigator) 
-> Info -> Localizations, and click in the `+` icon to add the language you want to support.

## Localization treatment
A bundle is used to store string localization files of SitumWayfinding library. Because of this when you translate a
string in the library you must make reference to library bundle.  
Use `NSLocalizedString("key", bundle: SitumMapsLibrary.bundle, comment: "")` to reference library bundle.

To make localization easy [BartyCrouch](https://github.com/Flinesoft/BartyCrouch) is used. You need to install it first
before use https://github.com/Flinesoft/BartyCrouch#installation. There is a file `.bartycrouch.toml` in the root 
directory of the project with configuration for this library. It is configured to only localize files under 
`SitumWayfinding/` folder. (If we need to change this in the future the documentation about this file is in 
https://github.com/Flinesoft/BartyCrouch#configuration)

Cheatsheet:
```bash
bartycrouch update # search for all NSLocalizedString in project and update Localizable.strings accordingly
bartycrouch lint # check the content of Localizable.strings for empty values and duplicates
```

A useful script to set in `.git/hooks/pre-commit` is the following:
```bash
#!/bin/sh
/usr/local/bin/bartycrouch update
/usr/local/bin/bartycrouch lint -w # -w fails on warning to avoid commit 
```

## Documentation
The documentation is made with [jazzy](https://github.com/realm/jazzy). In order to build documentation execute
the following from the root of the project:
```bash
./scripts/generate_appledoc.sh
```
