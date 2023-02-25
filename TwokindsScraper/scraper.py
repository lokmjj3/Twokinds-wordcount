from bs4 import BeautifulSoup
import requests

comicPage = 1
output_path = "Output.txt"
validPage = True

pagesWithNoTranscript = []

charsToReplace = (("â\x80¦", "..."), ("â\x80\x99", "'"), ("â\x80\x98", "'"),
                  ("â\x80\x94", "-"), ("â\x80\x93","-"), ("â\x80\x92", "-"),
                  ("â\x80\x9c", '"'), ("â\x80\x9d", '"'), ("Ã\xa0", "à"),
                  ("Ã©", "é"), ("Â½", "1/2"))

with open(output_path, 'w') as f:
    f.write("")

while (validPage == True):
# while (comicPage <= 1188): #used for debugging purposes
    noBody = False
    twokindsPage = requests.get(f"https://twokinds.keenspot.com/comic/{comicPage}/")
    twokindsHTML = BeautifulSoup(twokindsPage.text, "html.parser")
    transcript = twokindsHTML.find("div", {"class":"transcript-content"})

    validPage = True if(twokindsHTML.find("article", {"class": "comic"})) else False

    transcriptString = ""

    try:
        children = transcript.findChildren(recursive=False)
    except:
        noBody = True

    if(noBody == False):
        for child in children:
            lineTxt = child.text.replace(child.text[0:child.text.find(":")+1], "")
            transcriptString += f"{lineTxt}\n"

        for replaceThings in charsToReplace:
            transcriptString = transcriptString.replace(replaceThings[0], replaceThings[1])
    
        if ("Page transcript provided by" in transcriptString):
            transcriptString = transcriptString.replace(transcriptString[transcriptString.find("Page transcript provided by"): transcriptString.find("\n", transcriptString.find("Page transcript provided by"))], "\n\n")
        if ("(" in transcriptString and ")" in transcriptString):
            transcriptString = transcriptString.replace(transcriptString[transcriptString.find("("):transcriptString.find(")")+1], "")

        if(transcriptString.lower().find(" pending") > -1 or transcriptString.replace("\n", "") == ""):
            pagesWithNoTranscript.append(comicPage)
            transcriptString = ""

    with open(output_path, 'a') as f:
        f.write(f"\n\n{comicPage}\n\n{transcriptString}")
    print(f"done page {comicPage}")
    comicPage += 1


for page in pagesWithNoTranscript:
    with open("OCRdOutput.txt", 'r') as f:
        save_lines = []
        save_line = False
        for line in f:
            if str(page - 12) in line:
                break
            if save_line:
                save_lines.append(line.strip())
            if str(page - 13) in line:
                save_line = True
        OCRdTranscript = "\n".join(save_lines)

    with open("Output.txt", 'r+') as f:
        fileContent = f.read()
        pageIndex = fileContent.find(str(page))
        f.seek(pageIndex + len(str(page)))
        contentAfter = f.read()
        f.seek(pageIndex + len(str(page)))
        f.write(f"\n\n{OCRdTranscript}{contentAfter}")
