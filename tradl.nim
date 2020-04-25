##################################################################################################
# IMPORTS
##################################################################################################
import os
import httpclient
import strutils
import rss
import argparse
import logging
import tables
import terminal
import db_sqlite

##################################################################################################
# GLOBAL VARIABLES
##################################################################################################
let homeDir = getHomeDir()
var filename, title: string
var possible_downloads: seq[Table[string, string]] = @[]

##################################################################################################
# PROCEDURES
##################################################################################################
proc initDB(): DbConn = 
  try:
    var conn = open(joinPath(homedir, ".tradl", "tradl_downloads.db"), "","","")
    result = conn
  except:
    quit(QuitFailure)

proc createTables(db:DbConn) =
  db.exec(sql"""CREATE TABLE IF NOT EXISTS downloads (
              id   INTEGER PRIMARY KEY AUTOINCREMENT,
              url  TEXT NOT NULL
          )""")

proc convertToDB(db:DbConn) =
  if existsFile(joinPath(homedir, ".tradl", "downloads.txt")):
    echo "Trying to convert old downloads.txt ..."
    let downloads = joinPath(homedir, ".tradl", "downloads.txt")
    try:
      for line in downloads.lines:
        db.exec(sql"INSERT INTO downloads (url) VALUES (?)", line)
    except:
      log(lvlFatal, "Old download textfile couldn't be parsed. Error:", getCurrentExceptionMsg())
      quit("Old download textfile couldn't be parsed.")
    try:
      removeFile(joinPath(homedir, ".tradl", "downloads.txt"))
    except OSError:
      log(lvlFatal, "Old download textfile couldn't be deleted, please do it manually. Error:", getCurrentExceptionMsg())
      quit("Old download textfile couldn't be deleted. Please delete manually.")

proc initFS() =
  discard existsOrCreateDir(joinPath(homedir, ".tradl"))

proc downloaded*(db:DbConn, url:string): bool = 
  let tmp = db.getValue(sql"SELECT url from downloads where url=?", url)
  if tmp == "": 
    result = false 
  else:
    result = true

proc dl(db:DbConn, url: string)

##################################################################################################
# ARGUMENT PARSING
##################################################################################################
var p = newParser("tradl"):
  help("tradl means 'The Imperial Library of Trantor Downloader.")
  option("-l", "--language", help="Specify the ebooks language, like -l='en'")
  option("-a", "--amount", help="Specify the amount of ebooks to search, like -a=100")
  option("-d", "--dir", help="Specify the download directory, like -d='/home/user/Downloads'")
  option("-s", "--search", help="Search for ebooks, like -d='Stephen King'")

var opts = p.parse()

proc dl(db:DbConn, url: string) =
  info("Trying '" & filename & "' from '" & url & "'.")
  try:
    var client = newHttpClient()
    var bookcontent = client.getContent(url)
    writefile(joinpath(opts.dir, filename), bookcontent)
    db.exec(sql"INSERT INTO downloads (url) VALUES (?)", url)
    info("Downloaded '" & filename & "' to '" & opts.dir & "'.")
  except HttpRequestError:
    error("'", getCurrentExceptionMsg(), "' on '", filename, "' from '", url, "'.")
  except IOError:
    error("'", getCurrentExceptionMsg(), "' on writing '", filename, "' to '", opts.dir, "'.")
  except:
    error("raised: ", getCurrentExceptionMsg())
##################################################################################################
# INIT
##################################################################################################
var db = initDB()
db.createTables()
db.convertToDB()
initFS()
var logger = newConsoleLogger(fmtStr="[$datetime] - $levelname - ")
var fileLog = newFileLogger(joinPath(homedir, ".tradl", "error.log"), levelThreshold=lvlError, fmtStr="[$datetime] - $levelname - ")
var rollingLog = newRollingFileLogger(joinPath(homedir, ".tradl", "rolling.log"), maxLines=1000, fmtStr="[$datetime] - $levelname - ")
addHandler(fileLog)
addHandler(rollingLog)
addHandler(logger)


##################################################################################################
# NOT SEARCH
##################################################################################################
if opts.help == false and opts.search == "":
  if opts.language == "":
    info("No language parameter provided, using 'en'.")
    opts.language = "en"
  if opts.amount == "":
    info("No amount parameter provided, using default of 20.")
    opts.amount = "20"
  if opts.dir == "":
    info("No save directory provided, using current directory.")
    opts.dir = getCurrentDir()
  let baseUrl = "https://trantor.is/search/?num=" & opts.amount & "&amp;q=lang%3A" & opts.language & "&amp;fmt=rss"
  var tmpRSSClient = newHttpClient()
  var tmpRSS = tmpRSSClient.getContent(baseUrl)
  #tmpRSS = replace(tmpRSS, "&", "&amp;")
  var feed = parseRSS(tmpRSS)
  for item in feed.items:
    var tryUrl = item.enclosure.url
    if not downloaded(db, tryUrl):
      title = item.author & " - " & item.title
      filename = title & ".epub"
      filename = multiReplace(filename, [("\"", "_"), ("?", ""), (":", ""), ("*", ""), ("<", ""), (">", ""), ("|", ""), ("^", "")])
      dl(db, tryUrl)

if opts.search != "":
  var searchstring = replace(opts.search, " ", "+")
  if opts.language == "":
    writeStyled("No language parameter provided, using ", style = {styleDim})
    writeStyled("en.", style = {styleDim, styleItalic})
    opts.language = "en"
  if opts.dir == "":
    writeStyled("\nNo save directory provided, using current directory.", style = {styleDim})
    opts.dir = getCurrentDir()

  writeStyled("\nIf your wanted book isn't displayed, be more specific in your searchterm.", style = {styleDim})
  stdout.write("\nSearching for ")
  setForegroundColor(fgWhite)
  writeStyled opts.search 
  var baseURL = "https://trantor.is/search/?q=lang%3A" & opts.language & "+'" & searchstring & "'&fmt=rss&num=10"
  setForegroundColor(fgRed)
  #log(lvlInfo, baseURL)
  try:
    var tmpRSSClient = newHttpClient()
    var tmpRSS = tmpRSSClient.getContent(baseUrl)
    tmpRSS = replace(tmpRSS, "&", "&amp;")
    var feed = parseRSS(tmpRSS)
    if feed.items.len == 0:
      writeStyled "\n\nNo Results\n" 
    else:
      writeStyled "\n\nResults:\n" 
    resetAttributes()
    for item in feed.items:
      var tryUrl = item.enclosure.url
      if not downloaded(db, tryUrl):
        title = item.author & " - " & item.title
        filename = title & ".epub"
        filename = multiReplace(filename, [("?", ""), (":", ""), ("*", ""), ("<", ""), (">", ""), ("|", ""), ("^", "")])
        var downloadURL = item.enclosure.url
        var Download = to_table({"url": downloadURL, "filename": filename, "title": title})
        possible_downloads.add(Download)
    for i in 0 .. len(possible_downloads)-1:
      setForegroundColor(fgYellow)
      writeStyled intToStr(i)
      resetAttributes() 
      stdout.writeLine " - ", possible_downloads[i]["title"]
    if (len(possible_downloads)-1) >= 0:
      write(stdout, "\nWhich book do you want to download ", "(0-", len(possible_downloads)-1,  ") -> ")
      var input = readLine(stdin)
      var choice = possible_downloads[parseInt(input)]
      filename = choice["filename"]
      title = choice["title"]
      dl(db, choice["url"])
  except:
    log(lvlFatal, "Source couldn't be parsed. Error:", getCurrentExceptionMsg())
