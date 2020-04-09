# TRADL

Standalone CLI downloader for the Imperial Library of Trantor written in Nim.

## Getting Started
Grab a copy of trandl from [Releases](https://github.com/faulander/tradl/releases) and unzip it to a directory of your choice.
Open a command prompt in this directory and type "trandl.exe -h".

### Prerequisites

If you are on Windows and get an error about missing DLL, please download OpenSSL for Windows from this resource:
https://slproweb.com/download/Win64OpenSSL-1_1_1f.exe

If you are using chocolatey, you can run 
```
choco install openssl
```

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
trandl.exe -a=100 -d="home/user/test/Downloads" -l=en
```
Downloads the last 100 uploads in english to the specified directory.
```
trandl.exe -l=en -s="shakespeare william"
```
Searches for books from William Shakespeare in english.

```
trandl.exe 
```
Downloads the last 20 uploaded books in english to the current folder. 

## Logging
On Windows logfiles are located in:
```
c:\users\username\.trandl
```

On Linux logfiles are located in:
```
/home/username/.trandl
```

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
