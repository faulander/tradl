import os
import httpclient
import strutils
import rss
import argparse
import logging
import tables

# GLOBAL VARIABLES
let homeDir = getHomeDir()
var books: seq[string] 
var filename, title, downloadURL: string
var possible_downloads: seq[Table[string, string]] = @[]
var feed: RSS


# SETTINGS
discard existsOrCreateDir(joinPath(homedir, ".tradl"))
if not existsFile(joinPath(homedir, ".tradl", "downloads.txt")):
  writeFile(joinPath(homedir, ".tradl", "downloads.txt"), "")
if not existsFile(joinPath(homedir, ".tradl", "error.log")):
  writeFile(joinPath(homedir, ".tradl", "error.log"), "")
if not existsFile(joinPath(homedir, ".tradl", "rolling.log")):
  writeFile(joinPath(homedir, ".tradl", "rolling.log"), "")
let downloads = joinPath(homedir, ".tradl", "downloads.txt")
for line in downloads.lines:
  books.add(line)

# LOGGING
#var logger = newConsoleLogger(fmtStr="[$datetime] - $levelname - ")
var fileLog = newFileLogger(joinPath(homedir, ".tradl", "errors.log"), levelThreshold=lvlError, fmtStr="[$datetime] - $levelname - ")
var rollingLog = newRollingFileLogger(joinPath(homedir, ".tradl", "rolling.log"), maxLines=500, fmtStr="[$datetime] - $levelname - ")
#addHandler(logger)
addHandler(fileLog)
addHandler(rollingLog)


# ARGUMENT PARSING
var p = newParser("tradl"):
  help("trandl means 'The Imperial Library of Trantor Downloader.")

  option("-l", "--language", help="Specify the books language, like -l='en'")
  option("-a", "--amount", help="Specify the amount of books to search, like -a=100")
  option("-d", "--dir", help="Specify the download directory, like -d='/home/user/Downloads'")
  option("-s", "--search", help="Search for books, like -d='Stephen King'")

var opts = p.parse()

proc dl(url: string): bool =
  echo "Downloading '" & filename & "'."
  try:
    # echo item.enclosure.url
    var client = newHttpClient()
    var bookcontent = client.getContent(url)
    try:
      writefile(joinpath(opts.dir, filename), bookcontent)
      books.add(url)
    except IOError:
      log(lvlError,"Error writing file " & filename)
      return false
  except HttpRequestError:
    log(lvlError,"Error downloading " & title)
    return false
  echo "Downloaded '" & filename & "'."
  return true

if opts.help == false and opts.search == "":
  if opts.language == "":
    echo "No language parameter provided, using 'en'."
    opts.language = "en"
  if opts.amount == "":
    echo "No amount parameter provided, using default of 20."
    opts.amount = "20"
  if opts.dir == "":
    echo "No save directory provided, using current directory."
    opts.dir = getCurrentDir()
  let baseUrl = "https://trantor.is/search/?num=" & opts.amount & "&amp;q=lang%3A" & opts.language & "&amp;fmt=rss"
  var tmpRSSClient = newHttpClient()
  var tmpRSS = tmpRSSClient.getContent(baseUrl)
  tmpRSS = replace(tmpRSS, "&", "&amp;")
  var feed = parseRSS(tmpRSS)
  for item in feed.items:
    if item.enclosure.url notin books:
      title = item.title
      filename = title & ".epub"
      filename = multiReplace(filename, [("?", ""), (":", ""), ("*", ""), ("<", ""), (">", ""), ("|", ""), ("^", "")])
      downloadURL = item.enclosure.url
      discard dl(downloadURL)

  let f = open(joinPath(homedir, ".tradl", "downloads.txt"), fmWrite)
  for book in books:
    f.writeLine(book)
  f.close()

if opts.search != "":
  var searchstring = replace(opts.search, " ", "+")
  if opts.language == "":
    echo "No language parameter provided, using 'en'."
    opts.language = "en"
  if opts.dir == "":
    echo "No save directory provided, using current directory."
    opts.dir = getCurrentDir()

  echo "If your wanted book isn't displayed, be more specific in your searchterm."
  echo "Searching for '", opts.search, "'"
  var baseURL = "https://trantor.is/search/?q=lang%3A" & opts.language & "+'" & searchstring & "'&fmt=rss&num=10"
  #log(lvlInfo, baseURL)
  echo "Results:"
  try:
    var tmpRSSClient = newHttpClient()
    var tmpRSS = tmpRSSClient.getContent(baseUrl)
    tmpRSS = replace(tmpRSS, "&", "&amp;")
    var feed = parseRSS(tmpRSS)
    for item in feed.items:
      if item.enclosure.url notin books:
        title = item.title
        filename = title & ".epub"
        filename = multiReplace(filename, [("?", ""), (":", ""), ("*", ""), ("<", ""), (">", ""), ("|", ""), ("^", "")])
        downloadURL = item.enclosure.url
        var Download = to_table({"url": downloadURL, "filename": filename, "title": title})
        possible_downloads.add(Download)
        #discard dl(downloadURL)
    for i in 0 .. len(possible_downloads)-1:
      echo i, " - ", possible_downloads[i]["title"]
    if (len(possible_downloads)-1) > 0:
      write(stdout, "Which book do you want to download ", "(0-", len(possible_downloads)-1,  ") -> ")
      var input = readLine(stdin)
      var choice = possible_downloads[parseInt(input)]
      filename = choice["filename"]
      title = choice["title"]
      discard dl(choice["url"])
      let f = open(joinPath(homedir, ".tradl", "downloads.txt"), fmWrite)
      for book in books:
        f.writeLine(book)
      f.close()
  except:
    log(lvlFatal, "Source couldn't be parsed. Error:", getCurrentExceptionMsg())
