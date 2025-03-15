# Page Downloader

The PowerShell scripts provided in this repo make use of Chrome and [Monolith](https://github.com/Y2Z/monolith) as CLI tools. 

They are used to both crawl a site for all URLs within its host domain, piped into a file, and then use that file to download each page into a single self-contained `.html` file.

## Tools

The following are used by the scripts, and need to be installed / set up for the scripts to work. 

1. Download and install Monolith: https://github.com/Y2Z/monolith
    - I recommend using winget: `winget install --id=Y2Z.Monolith -e`
2. Download and install Chrome if you don't currently use it.
    - Find the path to Chrome.exe on your machine, it should look something like: `C:\Users\[user]\AppData\Local\Google\Chrome\Application`
    - Add this to the Path variable in Windows, guide: https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/

With Monolith and Chrome installed, you should have access to their executables via command line.

You can test both by trying them out in PowerShell:
- `monolith --version` -> This will print the version of the Monolith CLI.
- `chrome` -> This will open a chrome window if it's working.

## Running Manually

If you're downloading a static page that doesn't have any dynamically loading content (content that loads after the initial webpage loads), you can use Monolith by itself:

`monolith http://eternal-city.wikidot.com/missile-weapons-bows -o missile-weapons-bows.html`

If you're after a page that has dynamic content, you'll have to first open a headless Chrome window and pipe that content into Monolith:

`chrome --headless --window-size=1920,1080 --run-all-compositor-stages-before-draw --virtual-time-budget=9000 --incognito --dump-dom http://eternal-city.wikidot.com/rank-bonus-calculator | monolith - -I -b http://eternal-city.wikidot.com/rank-bonus-calculator -o rank-bonus-calculator.html`

## Host-Url-Crawler.ps1 Notes

1. Takes a hostname parameter (`-HostUrl`) ie: "http://eternal-city.wikidot.com".
2. Crawls web pages within the domain, extracting links from each page and follows them if they're on the same domain.
3. Stores all the URLs to a text file named using the host domain name.
4. Usage: `.\host-url-crawler.ps1 -HostUrl "http://eternal-city.wikidot.com" -MaxPages 500`

**Important Note:** The script currently doesn't remove URLs with file extensions, and that may not do what you want when run through `downloader.ps1`. You may have to filter things out of the file first to get only what you're after. 

## Downloader.ps1 Notes

1. Manually create or generate (`host-url-crawler.ps1`) a text file in the same folder as `downloader.ps1` containing URLs (one per line).
2. Run the script by passing the URL list file as a parameter: `.\downloader.ps1 -UrlListFile urls.txt`
3. You can optionally specify the location of the base directory with the `BaseOutputDir` parameter. It defaults to `.\downloads`.
4. Files will be downloaded into folders using each URL's hostname.
