import os
import httpclient
import strutils
import rss
import argparse
import logging

const homeDir = getHomeDir()

var logger = newConsoleLogger(fmtStr="[$datetime] - $levelname - ")
var fileLog = newFileLogger(joinPath(homedir, ".tradl", "errors.log"), levelThreshold=lvlError, fmtStr="[$datetime] - $levelname - ")
var rollingLog = newRollingFileLogger(joinPath(homedir, ".tradl", "rolling.log"), fmtStr="[$datetime] - $levelname - ")
addHandler(logger)
addHandler(fileLog)
addHandler(rollingLog)

var books: seq[string] 
discard existsOrCreateDir(joinPath(homedir, ".tradl"))
if not existsFile(joinPath(homedir, ".tradl", "downloads.txt")):
  writeFile(joinPath(homedir, ".tradl", "downloads.txt"), "")
let downloads = joinPath(homedir, ".tradl", "downloads.txt")
for line in downloads.lines:
  books.add(line)

var p = newParser("tradl"):
  help("trandl means 'The Imperial Library of Trantor Downloader.")

  option("-l", "--language", help="Specify the books language, like -l='en'")
  option("-a", "--amount", help="Specify the amount of books to search, like -a=100")
  option("-d", "--dir", help="Specify the download directory, like -d='/home/user/Downloads'")

var opts = p.parse()

if opts.language == "":
  info("No language parameter provided, using 'en'.")
  opts.language = "en"
if opts.amount == "":
  info("No amount parameter provided, using default of 20.")
  opts.amount = "20"
if opts.dir == "":
  info("No amount parameter provided, using default of 20.")
  opts.dir = getCurrentDir()

let baseUrl = "https://trantor.is/search/?num=" & opts.amount & "&amp;q=lang%3A" & opts.language & "&amp;fmt=rss"
try:
  let feed = getRSS(baseUrl)
  for item in feed.items:
    if item.enclosure.url notin books:
      var filename = item.title & ".epub"
      filename = filename.strip(chars={'\x00', '\"', '*', '/', ':', '<', '>', '?', '\\', '^', '|'})
      info("Downloading " & item.title)
      try:
        # echo item.enclosure.url
        var client = newHttpClient()
        let bookcontent = client.getContent(item.enclosure.url)
        try:
          writefile(joinpath(opts.dir, filename), bookcontent)
          books.add(item.enclosure.url)
        except IOError:
          log(lvlError,"Error writing file " & filename)
      except HttpRequestError:
        log(lvlError,"Error downloading " & item.title)

  let f = open(joinPath(homedir, ".tradl", "downloads.txt"), fmWrite)
  for book in books:
    f.writeLine(book)
  f.close()
except:
  log(lvlFatal, "Source couldn't be parsed. Error:", getCurrentExceptionMsg())
