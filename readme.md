
## Host-Url-Crawler.ps1 Notes

1. Takes a hostname parameter ie: "http://eternal-city.wikidot.com"
2. Crawls web pages within the domain, extracting links from each page and follows them if they're on the same domain.
3. Stores all the URLs to a text file.
4. Usage: `.\host-url-crawler.ps1 -HostUrl "http://eternal-city.wikidot.com" -MaxPages 500`

## Downloader.ps1 Notes

1. Create a text file with your URLs in the same folder as the downloader.ps1 script, one per line (e.g., urls.txt)
2. Run the script by passing the URL list file as a parameter: `.\downloader.ps1 -UrlListFile urls.txt`
3. You can optionally specify the location of the base directory with the `BaseOutputDir` parameter. It defaults to `.\downloads`.
4. Files will be downloaded into folders using each URL's hostname.
