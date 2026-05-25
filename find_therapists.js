const { chromium } = require('/opt/node22/lib/node_modules/playwright');

const EMDRIA_URL =
  'https://www.emdria.org/directory/?center=40.0480476%2C%20-83.025396&location=Columbus%2C%20OH%2043214%2C%20USA&radius=161000&refinementList%5Bspecialty_area%5D%5B0%5D=Birth%20Trauma%2FPregnancy%20Loss';

(async () => {
  const browser = await chromium.launch({
    executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const context = await browser.newContext({
    userAgent:
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    ignoreHTTPSErrors: true,
  });

  // Intercept Algolia API calls to capture app ID and API key
  let algoliaAppId = null;
  let algoliaApiKey = null;

  const page = await context.newPage();

  page.on('request', (req) => {
    const url = req.url();
    if (url.includes('algolia') || url.includes('algolianet')) {
      const match = url.match(/\/([A-Z0-9]{10})\/indexes/);
      if (match) {
        const headers = req.headers();
        if (headers['x-algolia-application-id']) {
          algoliaAppId = headers['x-algolia-application-id'];
          algoliaApiKey = headers['x-algolia-api-key'];
        }
      }
    }
  });

  console.log('Opening EMDRIA directory...');
  await page.goto(EMDRIA_URL, { waitUntil: 'networkidle', timeout: 60000 });

  // Wait for results to load
  await page.waitForSelector('.ais-Hits-item, .ais-InfiniteHits-item, [class*="Hit"], [class*="hit"]', {
    timeout: 30000,
  }).catch(() => console.log('Could not find hit items selector, continuing...'));

  await page.waitForTimeout(3000);

  // Take a screenshot to see what we're working with
  await page.screenshot({ path: '/home/user/devbox/emdria_page.png', fullPage: false });
  console.log('Screenshot saved.');

  // Check page title and URL
  console.log('Page title:', await page.title());
  console.log('Page URL:', page.url());

  // Look for filter panels
  const filterHTML = await page.evaluate(() => {
    const filters = document.querySelectorAll('[class*="filter"], [class*="Filter"], [class*="facet"], [class*="Facet"], [class*="refinement"], [class*="Refinement"]');
    return Array.from(filters).slice(0, 5).map(el => ({
      className: el.className,
      text: el.textContent.slice(0, 200),
    }));
  });
  console.log('Filter elements found:', JSON.stringify(filterHTML, null, 2));

  // Find all text on page related to gender filtering
  const genderRelated = await page.evaluate(() => {
    const all = document.querySelectorAll('*');
    const results = [];
    for (const el of all) {
      const text = el.textContent;
      if (text && (text.toLowerCase().includes('gender') || text.toLowerCase().includes('male') || text.toLowerCase().includes('female')) && el.children.length === 0) {
        results.push({ tag: el.tagName, className: el.className, text: text.trim().slice(0, 100) });
        if (results.length >= 10) break;
      }
    }
    return results;
  });
  console.log('Gender-related elements:', JSON.stringify(genderRelated, null, 2));

  // Get all currently visible therapist results
  const results = await page.evaluate(() => {
    const items = document.querySelectorAll('.ais-Hits-item, .ais-InfiniteHits-item, [class*="HitItem"], [class*="hit-item"], [class*="directory-result"], [class*="person-card"], [class*="therapist"]');
    return Array.from(items).map(item => ({
      text: item.textContent.trim().slice(0, 500),
      html: item.innerHTML.slice(0, 1000),
    }));
  });
  console.log(`Found ${results.length} result items`);
  if (results.length > 0) {
    console.log('First result sample:', JSON.stringify(results[0], null, 2));
  }

  // Get full page structure
  const pageStructure = await page.evaluate(() => {
    const main = document.querySelector('main') || document.querySelector('#main') || document.body;
    return main.innerHTML.slice(0, 5000);
  });
  console.log('\n--- Page structure (first 5000 chars) ---\n', pageStructure);

  if (algoliaAppId) {
    console.log('\nAlgolia App ID:', algoliaAppId);
    console.log('Algolia API Key:', algoliaApiKey);
  } else {
    console.log('\nAlgolia credentials not captured from requests.');
  }

  await browser.close();
})();
