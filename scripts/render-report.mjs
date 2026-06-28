#!/usr/bin/env node

import { createHash } from 'node:crypto';
import { createReadStream, existsSync } from 'node:fs';
import { mkdir, readdir, readFile, rm, stat, writeFile } from 'node:fs/promises';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pixelmatch from 'pixelmatch';
import { chromium } from 'playwright-core';
import { PNG } from 'pngjs';

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const baselineDir = path.resolve(rootDir, process.env.RENDER_REPORT_BASELINE_DIR ?? process.env.VISUAL_DIFF_BASELINE ?? 'public');
const candidateDir = path.resolve(rootDir, process.env.RENDER_REPORT_CANDIDATE_DIR ?? process.env.VISUAL_DIFF_CANDIDATE ?? 'public-preview');
const outDir = path.resolve(rootDir, process.env.RENDER_REPORT_DIR ?? process.env.VISUAL_DIFF_OUT ?? 'static/reports/visual-diff-current');
const assetsDir = path.join(outDir, 'assets');
const viewport = {
  width: Number.parseInt(process.env.VISUAL_DIFF_WIDTH ?? '1440', 10),
  height: Number.parseInt(process.env.VISUAL_DIFF_HEIGHT ?? '1200', 10),
};
const threshold = Number.parseFloat(process.env.VISUAL_DIFF_THRESHOLD ?? '0.1');
const excludedHtmlPrefixes = new Set(['reports/visual-diff-current/']);

async function main() {
  await assertDir(baselineDir, 'baseline');
  await assertDir(candidateDir, 'candidate');
  await rm(outDir, { recursive: true, force: true });
  await mkdir(assetsDir, { recursive: true });

  const [baselineServer, candidateServer] = await Promise.all([
    serveStatic(baselineDir),
    serveStatic(candidateDir),
  ]);

  const browser = await launchBrowser();

  try {
    const baselineFiles = (await findHtmlFiles(baselineDir)).filter(shouldCompareHtml);
    const candidateFiles = new Set((await findHtmlFiles(candidateDir)).filter(shouldCompareHtml));
    const commonFiles = baselineFiles.filter((file) => candidateFiles.has(file)).sort();
    const missingInCandidate = baselineFiles.filter((file) => !candidateFiles.has(file)).sort();
    const extraInCandidate = [...candidateFiles].filter((file) => !baselineFiles.includes(file)).sort();

    const rows = [];
    for (const file of commonFiles) {
      const routePath = routeForHtmlFile(file);
      const slug = slugForRoute(routePath);
      const baselinePng = path.join(assetsDir, `${slug}-baseline.png`);
      const candidatePng = path.join(assetsDir, `${slug}-candidate.png`);
      const diffPng = path.join(assetsDir, `${slug}-diff.png`);

      await screenshot(browser, `${baselineServer.origin}${routePath}`, baselinePng);
      await screenshot(browser, `${candidateServer.origin}${routePath}`, candidatePng);

      const comparison = await comparePngs(baselinePng, candidatePng, diffPng);
      rows.push({
        path: routePath,
        source: file,
        status: comparison.diffPixels === 0 ? 'passed' : 'changed',
        ...comparison,
        assets: {
          baseline: path.relative(outDir, baselinePng),
          candidate: path.relative(outDir, candidatePng),
          diff: path.relative(outDir, diffPng),
        },
      });
    }

    const report = {
      generatedAt: new Date().toISOString(),
      baselineDir: path.relative(rootDir, baselineDir),
      candidateDir: path.relative(rootDir, candidateDir),
      viewport,
      threshold,
      summary: {
        compared: rows.length,
        changed: rows.filter((row) => row.status === 'changed').length,
        passed: rows.filter((row) => row.status === 'passed').length,
        missingInCandidate: missingInCandidate.length,
        extraInCandidate: extraInCandidate.length,
      },
      missingInCandidate,
      extraInCandidate,
      results: rows,
    };

    await writeFile(path.join(outDir, 'report.json'), `${JSON.stringify(report, null, 2)}\n`);
    await writeFile(path.join(outDir, 'index.html'), renderHtml(report));

    console.log(`Compared ${report.summary.compared} pages: ${report.summary.changed} changed, ${report.summary.passed} passed.`);
    console.log(`Report written to ${path.relative(rootDir, outDir)}/index.html`);

    if (report.summary.changed > 0 || report.summary.missingInCandidate > 0) {
      process.exitCode = 1;
    }
  } finally {
    await browser.close();
    await Promise.all([baselineServer.close(), candidateServer.close()]);
  }
}

async function assertDir(dir, label) {
  try {
    const stats = await stat(dir);
    if (!stats.isDirectory()) {
      throw new Error(`${label} path is not a directory: ${path.relative(rootDir, dir)}`);
    }
  } catch (error) {
    if (error.code === 'ENOENT') {
      throw new Error(`${label} directory does not exist: ${path.relative(rootDir, dir)}`);
    }
    throw error;
  }
}

async function findHtmlFiles(dir, prefix = '') {
  const entries = await readdir(path.join(dir, prefix), { withFileTypes: true });
  const files = await Promise.all(entries.map(async (entry) => {
    const relativePath = path.join(prefix, entry.name);
    if (entry.isDirectory()) {
      return findHtmlFiles(dir, relativePath);
    }
    return entry.isFile() && entry.name.endsWith('.html') ? [toPosix(relativePath)] : [];
  }));
  return files.flat();
}

function routeForHtmlFile(file) {
  if (file === 'index.html') return '/';
  if (file.endsWith('/index.html')) return `/${file.slice(0, -'index.html'.length)}`;
  return `/${file}`;
}

function shouldCompareHtml(file) {
  for (const prefix of excludedHtmlPrefixes) {
    if (file.startsWith(prefix)) return false;
  }
  return true;
}

function slugForRoute(routePath) {
  const readable = routePath === '/' ? 'root' : routePath.replace(/^\/|\/$/g, '').replace(/[^a-z0-9]+/gi, '-').toLowerCase();
  const hash = createHash('sha1').update(routePath).digest('hex').slice(0, 8);
  return `${readable || 'root'}-${hash}`;
}

async function screenshot(browser, url, outputPath) {
  const page = await browser.newPage({ viewport });
  try {
    await page.goto(url, { waitUntil: 'networkidle' });
    await page.addStyleTag({
      content: [
        '*, *::before, *::after {',
        '  animation-duration: 0s !important;',
        '  animation-delay: 0s !important;',
        '  transition-duration: 0s !important;',
        '  transition-delay: 0s !important;',
        '}',
        'html { scroll-behavior: auto !important; }',
      ].join('\n'),
    });
    await page.screenshot({ path: outputPath, fullPage: true, animations: 'disabled' });
  } finally {
    await page.close();
  }
}

async function comparePngs(baselinePath, candidatePath, diffPath) {
  const baseline = PNG.sync.read(await readFile(baselinePath));
  const candidate = PNG.sync.read(await readFile(candidatePath));
  const width = Math.max(baseline.width, candidate.width);
  const height = Math.max(baseline.height, candidate.height);
  const normalizedBaseline = normalizePng(baseline, width, height);
  const normalizedCandidate = normalizePng(candidate, width, height);
  const diff = new PNG({ width, height });
  const diffPixels = pixelmatch(
    normalizedBaseline.data,
    normalizedCandidate.data,
    diff.data,
    width,
    height,
    { threshold },
  );

  await writeFile(diffPath, PNG.sync.write(diff));
  return {
    width,
    height,
    baselineSize: { width: baseline.width, height: baseline.height },
    candidateSize: { width: candidate.width, height: candidate.height },
    diffPixels,
    diffRatio: Number((diffPixels / (width * height)).toFixed(6)),
  };
}

function normalizePng(source, width, height) {
  if (source.width === width && source.height === height) return source;
  const target = new PNG({ width, height, fill: true });
  for (let y = 0; y < source.height; y += 1) {
    for (let x = 0; x < source.width; x += 1) {
      const sourceIndex = (source.width * y + x) << 2;
      const targetIndex = (width * y + x) << 2;
      source.data.copy(target.data, targetIndex, sourceIndex, sourceIndex + 4);
    }
  }
  return target;
}

async function findChromiumExecutable() {
  const candidates = [
    process.env.CHROME_PATH,
    process.env.CHROME_BIN,
    process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH,
    '/usr/bin/google-chrome',
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
  ].filter(Boolean);

  for (const candidate of candidates) {
    if (existsSync(candidate)) return candidate;
  }

  if (process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH) {
    return process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH;
  }
  try {
    const puppeteer = await import('puppeteer');
    return puppeteer.default.executablePath();
  } catch {
    throw new Error('Chrome/Chromium executable not found. Set CHROME_PATH or CHROME_BIN to a valid browser binary.');
  }
}

async function launchBrowser() {
  const executablePath = await findChromiumExecutable();
  try {
    return await chromium.launch({
      executablePath,
      args: ['--no-sandbox', '--disable-dev-shm-usage'],
    });
  } catch (error) {
    throw new Error(`Failed to launch Chromium at ${executablePath}. Set CHROME_PATH to the Chrome/Chromium binary from the devcontainer image.\n${error.message}`);
  }
}

async function serveStatic(root) {
  const server = http.createServer(async (request, response) => {
    try {
      const requestUrl = new URL(request.url ?? '/', 'http://localhost');
      const decodedPath = decodeURIComponent(requestUrl.pathname);
      const filePath = await resolveStaticPath(root, decodedPath);
      response.writeHead(200, { 'content-type': contentType(filePath) });
      createReadStream(filePath).pipe(response);
    } catch (error) {
      response.writeHead(error.statusCode ?? 500, { 'content-type': 'text/plain; charset=utf-8' });
      response.end(error.statusCode === 404 ? 'Not found' : String(error.message ?? error));
    }
  });

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();
  return {
    origin: `http://127.0.0.1:${address.port}`,
    close: () => new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve()))),
  };
}

async function resolveStaticPath(root, requestPath) {
  const cleanPath = requestPath.replace(/^\/+/, '');
  const candidates = [];
  const directPath = path.resolve(root, cleanPath);
  candidates.push(directPath);
  if (requestPath.endsWith('/')) {
    candidates.push(path.resolve(root, cleanPath, 'index.html'));
  }

  for (const candidate of candidates) {
    if (!isInsideDir(root, candidate)) continue;
    try {
      const stats = await stat(candidate);
      if (stats.isFile()) return candidate;
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
  }

  const notFound = new Error(`Not found: ${requestPath}`);
  notFound.statusCode = 404;
  throw notFound;
}

function isInsideDir(parent, candidate) {
  const relative = path.relative(parent, candidate);
  return relative === '' || (!relative.startsWith('..') && !path.isAbsolute(relative));
}

function contentType(filePath) {
  const types = {
    '.css': 'text/css; charset=utf-8',
    '.html': 'text/html; charset=utf-8',
    '.ico': 'image/x-icon',
    '.js': 'text/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.svg': 'image/svg+xml',
    '.ttf': 'font/ttf',
    '.webp': 'image/webp',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.xml': 'application/xml; charset=utf-8',
  };
  return types[path.extname(filePath).toLowerCase()] ?? 'application/octet-stream';
}

function renderHtml(report) {
  const rows = report.results.map((row) => `
        <tr>
          <td><a href="${escapeHtml(row.path)}">${escapeHtml(row.path)}</a></td>
          <td><span class="status ${row.status}">${row.status}</span></td>
          <td>${row.diffPixels.toLocaleString()}</td>
          <td>${(row.diffRatio * 100).toFixed(3)}%</td>
          <td>${row.width}x${row.height}</td>
          <td class="assets">
            <a href="${escapeHtml(row.assets.baseline)}">baseline</a>
            <a href="${escapeHtml(row.assets.candidate)}">candidate</a>
            <a href="${escapeHtml(row.assets.diff)}">diff</a>
          </td>
        </tr>`).join('');

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Visual Diff Report</title>
  <style>
    :root { color-scheme: light dark; font-family: system-ui, sans-serif; }
    body { margin: 2rem; line-height: 1.45; }
    header { margin-bottom: 1.5rem; }
    h1 { font-size: 1.6rem; margin: 0 0 0.5rem; }
    dl { display: grid; grid-template-columns: max-content 1fr; gap: 0.25rem 0.75rem; margin: 0; }
    dt { font-weight: 700; }
    dd { margin: 0; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border-bottom: 1px solid color-mix(in srgb, currentColor 20%, transparent); padding: 0.55rem; text-align: left; vertical-align: top; }
    th { font-size: 0.85rem; }
    .status { border-radius: 999px; display: inline-block; font-size: 0.8rem; font-weight: 700; padding: 0.1rem 0.5rem; }
    .passed { background: #d7f5df; color: #145523; }
    .changed { background: #ffe0d6; color: #7b2414; }
    .assets { white-space: nowrap; }
    .assets a + a { margin-left: 0.5rem; }
    @media (prefers-color-scheme: dark) {
      .passed { background: #173b20; color: #a9e7b6; }
      .changed { background: #4a2018; color: #ffc2b2; }
    }
  </style>
</head>
<body>
  <header>
    <h1>Visual Diff Report</h1>
    <dl>
      <dt>Generated</dt><dd>${escapeHtml(report.generatedAt)}</dd>
      <dt>Compared</dt><dd>${report.summary.compared}</dd>
      <dt>Changed</dt><dd>${report.summary.changed}</dd>
      <dt>Passed</dt><dd>${report.summary.passed}</dd>
      <dt>Viewport</dt><dd>${report.viewport.width}x${report.viewport.height}</dd>
      <dt>Baseline</dt><dd>${escapeHtml(report.baselineDir)}</dd>
      <dt>Candidate</dt><dd>${escapeHtml(report.candidateDir)}</dd>
    </dl>
  </header>
  <main>
    <table>
      <thead>
        <tr>
          <th>Path</th>
          <th>Status</th>
          <th>Diff pixels</th>
          <th>Diff ratio</th>
          <th>Image size</th>
          <th>Assets</th>
        </tr>
      </thead>
      <tbody>${rows || '<tr><td colspan="6">No matching HTML files found.</td></tr>'}
      </tbody>
    </table>
  </main>
</body>
</html>
`;
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  })[char]);
}

function toPosix(filePath) {
  return filePath.split(path.sep).join('/');
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
