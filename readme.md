# TRADL

Standalone CLI downloader for the Imperial Library of Trantor written in Nim.

![Alt text](/res/help.png?raw=true "The help function")
![Alt text](/res/searching_with_language_and_path.png?raw=true "The search function")


## Getting Started
Grab a copy of trandl from [Releases](https://github.com/faulander/tradl/releases) and unzip it to a directory of your choice.
Open a command prompt in this directory and type "tradl.exe -h" (on windows) or "./tradl -h" (on linux).

## Changelog
- v0.3.0: Switched to SQLite as database instead of the textfiles.
- v0.3.0: Fixed a bug which occured in search-mode when only one result returned.
- v0.2.4: Fixed a bug which made tradl download ebooks several times.
- v0.2.3: Code changed to reflect the changes done on the library.
- v0.2.0: Introduced search-mode.
- v0.1.0: Initial release.

## Usage
```
-h shows the help page
-a amount of files to download
-d download directory
-l language
-s search
```

### Examples
```
tradl.exe -a=100 -d="home/user/test/Downloads" -l=en
```
Downloads the last 100 uploads in english to the specified directory.
```
tradl.exe -l=en -s="shakespeare william"
```
Searches for books from William Shakespeare in english.

```
tradl.exe 
```
Downloads the last 20 uploaded books in english to the current folder. 

## Logging
On Windows logfiles are located in:
```
c:\users\username\.tradl
```

On Linux logfiles are located in:
```
/home/username/.tradl
```

## License

This project is licensed under the [MIT License](license.md).
