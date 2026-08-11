import * as fs from 'fs';

const pages = [
  { file: 'docs/presentations/md-viewer.html', key: 'mdviewer', title: 'Markdown Viewer' },
  { file: 'docs/presentations/resources-index.html', key: 'resources', title: 'Resource Index' },
  { file: 'docs/presentations/social-post.html', key: 'socialpost', title: 'Social Post Studio' },
  { file: 'docs/presentations/video-studio.html', key: 'videostudio', title: 'Video Studio' },
];

for (const page of pages) {
  if (!fs.existsSync(page.file)) {
    console.log('Missing: ' + page.file);
    continue;
  }
  
  let content = fs.readFileSync(page.file, 'utf8');
  
  if (content.includes('class="hero"')) {
    console.log('Already has hero: ' + page.file);
    continue;
  }
  
  const navEnd = content.indexOf('</nav>');
  if (navEnd < 0) {
    console.log('No nav: ' + page.file);
    continue;
  }
  
  const insertPos = navEnd + 6;
  
  const section = `
    <header class="hero" id="overview" style="padding-top: 90px; min-height: 40vh;">
      <div>
        <span class="hero-badge mb-3">✦ Tool</span>
        <h1><span class="glow">${page.title}</span></h1>
        <p class="lead" data-i18n="c_${page.key}_desc">${page.title} - Gentle-Vanguard Tool</p>
      </div>
    </header>

    <section class="fade-in" id="content">
      <div class="section-title">
        <h2 data-i18n="sec_${page.key}">${page.title}</h2>
        <p data-i18n="c_${page.key}_content">${page.title} functionality and features</p>
      </div>
    </section>`;
  
  content = content.slice(0, insertPos) + section + content.slice(insertPos);
  
  fs.writeFileSync(page.file, content);
  console.log('✅ Updated: ' + page.file);
}

console.log('Done');
