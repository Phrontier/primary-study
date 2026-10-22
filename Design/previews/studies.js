const c = window.studyContent;
const paths = {
 home:'<path d="m3 10 9-7 9 7v10h-6v-7H9v7H3z"/>',
 calendar:'<rect x="3" y="5" width="18" height="16" rx="3"/><path d="M7 3v4m10-4v4M3 11h18m-13 4h1m3 0h1m3 0h1"/>',
 users:'<circle cx="9" cy="8" r="3"/><path d="M3 21v-3a6 6 0 0 1 12 0v3m2-16a3 3 0 0 1 0 6m2 4a5 5 0 0 1 2 4v2"/>',
 more:'<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>',
 search:'<circle cx="10" cy="10" r="7"/><path d="m15 15 6 6"/>',
 arrow:'<path d="M4 12h16m-6-6 6 6-6 6"/>',
 plane:'<path d="m21 3-6 18-4-8-8-4zM11 13 21 3"/>',
 shield:'<path d="m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6zM12 8v5m0 3h.01"/>',
 flame:'<path d="M12 3c1 5 6 5 6 11a6 6 0 0 1-12 0c0-2 1-4 3-6 0 3 1 4 2 4 2-2 2-5 1-9z"/>',
 book:'<path d="M12 5v16M3 4c4-1 7 0 9 1 2-1 5-2 9-1v15c-4-1-7 0-9 2-2-2-5-3-9-2z"/>'
};
const icon = name => `<svg viewBox="0 0 24 24" aria-hidden="true">${paths[name]}</svg>`;
const originalConfigs = [
 ['a','A','Refined current','Familiar surfaces. Clearer priorities. Less nesting.'],
 ['b','B','Open composition','A welcoming activity area and a highlighted place to resume.'],
 ['c','C','Compact & colorful','More information in view, with open sections and purposeful color.'],
 ['d','D','Expressive exploration','A bolder flight-path composition, oversized numbers, and asymmetric color.']
];
const selectedFlash = new URLSearchParams(location.search).get('round') === '9';
const flashStudies = selectedFlash || new URLSearchParams(location.search).get('round') === '8';
const instructorHybrid = new URLSearchParams(location.search).get('round') === '7';
const detailStudies = instructorHybrid || new URLSearchParams(location.search).get('round') === '6';
const ratingStudies = new URLSearchParams(location.search).get('round') === '5';
const approvedCompanions = ratingStudies || new URLSearchParams(location.search).get('round') === '4';
const companions = flashStudies || detailStudies || approvedCompanions || new URLSearchParams(location.search).get('round') === '3';
const refined = new URLSearchParams(location.search).get('round') === '2';
const companionConfigs = [
 ['events','A','Events · Open rows','Original A. Open phase rows and a distinct library shortcut.'],
 ['events-b','B','Events · Grouped directory','One white phase directory, with restrained icon color.'],
 ['events-c','C','Events · Phase tiles','A vertical two-column phase grid. Color identifies destinations.'],
 ['list','A','Sims · Open rows','Original A. Clear event identifiers and full summaries.'],
 ['list-b','B','Sims · Grouped list','A white list surface separates the event directory from page chrome.'],
 ['list-c','C','Sims · Identifier rail','Blue code tiles anchor open rows; titles and summaries share a column.'],
 ['instructors','A','Instructors · Open roster','Original A. Open instructor rows with paired scores below.'],
 ['instructors-b','B','Instructors · Profile surfaces','One white surface per instructor, without nested score cards.'],
 ['instructors-c','C','Instructors · Compact roster','Open rows with identity above a compact aligned score line.']
];
const detailConfigs = ['eventdetail','instructordetail','discussion'].flatMap(kind=>['a','b','c'].map(v=>[kind+'-'+v,v.toUpperCase(),({eventdetail:'Event detail',instructordetail:'Instructor detail',discussion:'Discussion reading'})[kind]+' · '+v.toUpperCase(),({a:'Open sections and selective emphasis.',b:'Grouped content surfaces with quiet boundaries.',c:'Compact hierarchy with colored anchors.'})[v]]));
const flashConfigs=['deck','question','answer'].flatMap(kind=>['a','b','c'].map(v=>['flash-'+kind+'-'+v,v.toUpperCase(),({deck:'Deck overview',question:'Question side',answer:'Answer side'})[kind]+' · '+v.toUpperCase(),({a:'Open chrome, soft card surfaces, familiar hierarchy.',b:'A more defined card edge and compact supporting controls.',c:'A color accent anchors the card; open sections stay quiet.'})[v]]));
const configs = selectedFlash ? [['flash-deck-c','C+','Deck · Refined selection','C introduction and actions, with one white card per flashcard.'],['flash-question-c','C','Question · Refined selection','C card treatment, with a cleaner progress header.'],['flash-answer-c','C+','Answer · Refined selection','C answer card and a compact single-row rating control.']] : flashStudies ? flashConfigs : instructorHybrid ? [['instructordetail-a','A','Open summary + accent','Aligned overall grades, with a blue heading rule.'],['instructordetail-b','B','Blue summary surface','A softly colored summary gives overall averages more emphasis.'],['instructordetail-c','C','White summary + blue edge','A clear white summary with a stronger colored anchor.']] : detailStudies ? detailConfigs : ratingStudies ? [['instructors-color-a','A','Colored numbers + scale','The current proposal: colored numbers, segmented scales, and descriptors.'],['instructors-color-d','D','Spectrum + position marker','A continuous color scale with a marker locating each average.'],['instructors-color-e','E','Color arc + score','A compact color arc frames the score; labels remain below.']] : approvedCompanions ? [['events','A','Events · Selected A','Approved open phase rows and highlighted library access.'],['list','A','Sims · Selected A','Approved event hierarchy, identifiers, and open summaries.'],['instructors','A+','Instructors · Refined A','A’s open roster + C’s segmented control, visible review action, and rating color.']] : companions ? companionConfigs : refined ? [
 ['r1','A1','Flame + daily count','A larger flame and streak, paired with a clear daily count. No goal.'],
 ['r2','A2','Flame + goal ring','A warmer streak treatment with a sample 12 / 20 daily goal.'],
 ['r3','A3','Paired activity dials','Two balanced circles: streak and daily activity. No goal.']
] : originalConfigs;
function activity(id) {
 if (!refined) return `<div class="activity"><div class="streak">${icon('flame')}<span>${c.streak}</span></div><p class="daily"><strong>12</strong><span>flashcards reviewed today</span></p><div class="activity-decoration" aria-hidden="true">${icon('plane')}<span></span></div></div>`;
 const goal=id==='r2';
 return `<div class="activity revised"><div class="streak-stat"><div class="flame-art" aria-hidden="true">🔥</div><div><strong>4</strong><span>day streak</span></div></div><div class="daily-stat ${goal?'goal':''}">${id==='r1'?'':`<svg class="activity-ring" viewBox="0 0 100 100" aria-hidden="true"><circle class="track" cx="50" cy="50" r="43"/>${goal?'<circle class="progress" cx="50" cy="50" r="43"/>':''}</svg>`}<strong>12</strong><span>flashcards reviewed today</span>${goal?'<small>Daily goal · 20</small>':''}</div></div>`;
}
function content(id){if(flashStudies)return flashPage(id);if(detailStudies)return detailPage(id);if(companions) return companionPage(id); return `<div class="intro"><div class="greeting"><span>Home</span><h2>${c.greeting}<span class="greeting-dot">.</span></h2></div>${activity(id)}</div>
<section class="recent"><h3>Continue studying</h3><div class="recent-list">${c.recent.map((r,i)=>`<div class="study-item ${i===0?'featured':''}"><div class="item-icon">${icon(i===0?'plane':'book')}</div><div class="item-copy"><span class="code">${r.code}</span><h4>${r.title}</h4><p>${r.detail}</p></div>${i===0?`<button type="button" class="resume">Resume ${icon('arrow')}</button>`:`<span class="row-arrow">${icon('arrow')}</span>`}</div>`).join('')}</div></section>
<section class="question-section"><div class="section-title"><h3>Question of the day</h3><span class="daily-dot" aria-hidden="true"></span></div><div class="question"><p>${c.question}</p><div class="answers">${c.choices.map((x,i)=>`<button type="button"><span>${'ABCD'[i]}</span>${x}</button>`).join('')}</div></div></section>
<section class="reference"><div class="reference-icon">${icon('shield')}</div><div><h3>${c.reference}</h3><p>Your core memory items, together.</p></div>${icon('arrow')}</section>`;}
const nav = `<nav class="tabbar" aria-label="App navigation">${c.nav.map((n,i)=>`<div class="nav-item ${i===0?'active':''}">${icon(['home','calendar','users','more','search'][i])}<span>${n}</span></div>`).join('')}</nav>`;
document.querySelector('#studies').innerHTML=configs.map(([id,letter,title,desc])=>`<article class="study" id="study-${id}"><header class="study-label"><span>${letter}</span><div><h2>${title}</h2><p>${desc}</p></div></header><div class="phone ${companions ? 'a companion '+(flashStudies?'flash-study ':'')+(selectedFlash?'selected-flash ':'')+(detailStudies?'detail-study ':'')+(instructorHybrid?'instructor-hybrid ':'')+(approvedCompanions?'approved-companion ':'')+(ratingStudies?'rating-study '+id+' ':'')+'variant-'+(ratingStudies?'a':id.endsWith('-b')?'b':id.endsWith('-c')?'c':'a') : refined ? 'a refinement' : ''} ${id}" aria-label="${title} Home preview"><div class="statusbar"><span>9:41</span><div class="island"></div><span class="device-status">▮▮▮ ◔ ▰</span></div><div class="screen" tabindex="0" aria-label="Scroll ${title}">${content(id)}</div>${companions ? nav.replace('nav-item active','nav-item').replace(id.startsWith('instructor') ? '<div class="nav-item ">'+icon('users') : '<div class="nav-item ">'+icon('calendar'), id.startsWith('instructor') ? '<div class="nav-item active">'+icon('users') : '<div class="nav-item active">'+icon('calendar')) : nav}<div class="home-indicator"></div></div><a class="solo-link" href="?${companions ? (flashStudies?(selectedFlash?'round=9&':'round=8&'):detailStudies?(instructorHybrid?'round=7&':'round=6&'):ratingStudies?'round=5&':approvedCompanions?'round=4&':'round=3&') : refined ? 'round=2&' : ''}option=${id}">View this option alone ↗</a></article>`).join('');
const selected = new URLSearchParams(location.search).get('option');
if(configs.some(x=>x[0]===selected)){document.body.classList.add('solo');document.querySelectorAll('.study').forEach(el=>el.hidden=el.id!==`study-${selected}`);}

if(companions){
 document.body.classList.add('round-two','companion-round');
 document.querySelector('.studio-label').textContent='PRIMARY GOUGE / COMPANION SCREENS / ROUND 03';
 document.querySelector('.studio h1').textContent=approvedCompanions?'Keep the direction. Clarify the ratings.':'One language. Different tasks.';
 document.querySelector('.studio p:not(.studio-label)').textContent=approvedCompanions?'Selected direction: Events A, Sims A, and instructor A with the segmented control, highlighted review action, and rating color A.':'Three options per screen, all grounded in approved Home A1. A preserves the previous studies.';
 document.querySelector('.studio aside').innerHTML='Light mode · 393 × 852<br>Event titles and summaries come from the app.<br>Instructor identities and scores are fictional sample data.';
 document.querySelector('.studio-footer').innerHTML='Static visual studies. No new navigation, filters, ratings, or tracking implemented. <a href="?round=2&option=r1">Approved Home A1</a>';
} else if(refined){
 document.body.classList.add('round-two');
 document.querySelector('.studio-label').textContent='PRIMARY GOUGE / HOME REFINEMENT / ROUND 02';
 document.querySelector('.studio h1').textContent='Keep the layout. Improve the activity.';
 document.querySelector('.studio p:not(.studio-label)').textContent='A’s composition + B’s green reference tile. Only the activity area changes.';
 document.querySelector('.studio aside').innerHTML='Light mode · 393 × 852<br>All activity is sample data. A2 alone assumes a goal.<br>Flame emoji is a temporary art direction placeholder.';
 document.querySelector('.studio-footer').innerHTML='The goal is an exploration, not a committed feature. <a href="?">Original studies</a> <a href="?round=3">Companion options A–C</a>';
} else {
 document.querySelector('.studio-footer').innerHTML += ' <a href="?round=2">View round 02 refinements ↗</a>';
}

function companionPage(id) {
 id=id.split('-')[0];
 const d=window.companionContent;
 const row=(title,subtitle,kind,tint='blue')=>`<div class="destination-row ${tint}"><div class="item-icon">${icon(kind)}</div><div class="item-copy"><h4>${title}</h4>${subtitle?`<p>${subtitle}</p>`:''}</div><span class="row-arrow">${icon('arrow')}</span></div>`;
 if(id==='events')return `<div class="page-intro"><h2>Events</h2><p>Find your event. Prepare for what’s next.</p></div><section class="phase-section"><h3>Choose your phase</h3>${d.phases.map((title,i)=>row(title,'',i===0?'plane':i===1?'arrow':'book',['blue','purple','teal','amber','blue'][i])).join('')}</section><section class="reference library-tile"><div class="reference-icon">${icon('book')}</div><div><h3>General Library</h3><p>Reference material across your training.</p></div>${icon('arrow')}</section>`;
 if(id==='list')return `<div class="detail-bar">${icon('arrow')}<span>Contacts</span></div><div class="page-intro"><h2>Sims</h2><p>Familiarization · Cockpit procedures and beyond</p></div><section class="event-rows">${d.events.map(e=>`<div class="event-row"><div class="item-copy"><span class="code">${e.code}</span><h4>${e.title}</h4><p>${e.summary}</p></div><span class="row-arrow">${icon('arrow')}</span></div>`).join('')}</section>`;
 return `<div class="page-intro"><h2>Instructors</h2><p>Know who you’re flying with.</p></div><div class="instructor-tools"><div class="search-field">${icon('search')}<span>Search instructors or squadrons</span></div><div class="filter-row"><span class="selected">All</span><span>Sims</span><span>Flights</span></div></div><div class="section-title roster-title"><h3>Instructor reviews</h3><button class="text-action" type="button">Submit review ${icon('arrow')}</button></div><section>${d.instructors.map(e=>`<div class="instructor-row"><div class="instructor-head"><div class="item-icon">${icon('users')}</div><div class="item-copy"><h4>${e.name}</h4><p>${e.squadron} · ${e.capability}</p></div><span class="row-arrow">${icon('arrow')}</span></div><div class="rating-pair"><div>${approvedCompanions?rating(e.chill,'chill'): `<strong>${e.chill}<small> / 5</small></strong><span>Chill factor</span>`}</div><div>${approvedCompanions?rating(e.grading,'grading'): `<strong>${e.grading}<small> / 5</small></strong><span>Grading style</span>`}</div></div></div>`).join('')}</section>`;
}
if(companions){
 const group=new URLSearchParams(location.search).get('screen');
 if(['events','list','instructors'].includes(group))document.querySelectorAll('.study').forEach(el=>el.hidden=!el.id.startsWith('study-'+group));
 const links=document.createElement('div');links.className='comparison-links';links.innerHTML='<a href="?round=3&screen=events">Events A–C</a><a href="?round=3&screen=list">Sims A–C</a><a href="?round=3&screen=instructors">Instructors A–C</a><a href="?round=3">All nine</a>';
 if(approvedCompanions){links.innerHTML='<a href="?round=4&screen=instructors">Refined instructors</a><a href="?round=4">Selected screens</a><a href="?round=3&screen=instructors">Previous instructor options</a>';document.querySelector('.studio-label').textContent='PRIMARY GOUGE / SELECTED SCREENS / ROUND 04';}if(ratingStudies){links.innerHTML='<a href="?round=4&screen=instructors">Previous instructor refinement</a>';document.querySelector('.studio-label').textContent='PRIMARY GOUGE / INSTRUCTOR RATING COLOR / ROUND 05';document.querySelector('.studio h1').textContent='A as reference. Two fresh directions.';document.querySelector('.studio p:not(.studio-label)').textContent='B and C are retired. D and E explore more expressive scales within the same instructor layout.';}document.querySelector('.studio').after(links);
}

function rating(raw,category){
 const n=Math.max(1,Math.min(7,Math.round(Number(raw))));
 const labels=category==='chill'?['Hammer','Intense','Serious','Neutral','Pretty Chill','Super Chill','Chillmaster']:['MIF Monster','Harsh','Tough but Fair','Fair','Good but Fair','Easy Grader','Santa Claus'];
 const colors=['#D93A2F','#E46B2E','#D59A2A','#A69C3D','#78BF58','#3FAE4C','#1D8F3E'];
 const ink=['#A82A23','#A84317','#87600E','#746B20','#3D7927','#23772C','#196F31'];
 return `<div class="rating-arc" aria-hidden="true"><svg viewBox="0 0 120 68"><path class="arc-track" d="M10 58 A50 50 0 0 1 110 58"/><path class="arc-color" d="M10 58 A50 50 0 0 1 110 58" style="stroke:${colors[n-1]};stroke-dasharray:${Number(raw)/7*157} 157"/></svg></div><strong style="color:${ink[n-1]};--rating-tint:${colors[n-1]}22;--rating-border:${colors[n-1]}55">${(Number(raw)/7*10).toFixed(1)}<small> / 10</small></strong><span>${category==='chill'?'Chill factor':'Grading style'}</span><div class="rating-spectrum" style="--position:${(Number(raw)-1)/6*100}%;--marker:${ink[n-1]}" aria-hidden="true"><i></i></div><div class="rating-scale" aria-hidden="true">${colors.map((color,i)=>`<i style="background:${i<n?color:'#e0e6ee'}"></i>`).join('')}</div><span class="rating-description" style="color:${ink[n-1]}">${labels[n-1]}</span>`;
}

function detailPage(id){
 const d=window.detailContent,kind=id.split('-')[0];
 const back=(title)=>`<div class="detail-bar">${icon('arrow')}<span>${title}</span></div>`;
 const section=(title,body,cls='')=>`<section class="detail-section ${cls}"><h3>${title}</h3><div class="section-body">${body}</div></section>`;
 const action=(title,subtitle,kind,tint='blue')=>`<div class="destination-row ${tint}"><div class="item-icon">${icon(kind)}</div><div class="item-copy"><h4>${title}</h4><p>${subtitle}</p></div><span class="row-arrow">${icon('arrow')}</span></div>`;
 if(kind==='eventdetail') return `${back('Sims')}<div class="page-intro"><span class="code">${d.code}</span><h2>${d.title}</h2></div>${section('Overview',`<p>${d.overview}</p>`,'overview-section')}${section('Study and rehearse',action('Discussion Items','Read the key preparation material.','book','teal')+action('Flashcards','Practice the discussion items.','book','purple'),'tool-section')}${section('Briefing guide',action('FAM 2101 Briefing Guide','1542.166D','book','amber'),'guide-section')}`;
 if(kind==='instructordetail')return `${back('Instructors')}<div class="page-intro"><h2>Sample Instructor A</h2><p>VT-27 · Flights · Sims</p><div class="profile-meta">2 sample reviews <span class="report-link">Report</span></div></div>${section('At a glance',`<div class="rating-pair"><div>${rating('4.6','chill')}</div><div>${rating('3.8','grading')}</div></div>`,'profile-ratings')}<div class="review-header"><h3>Reviews</h3><span>Most recent ${icon('arrow')}</span></div>${d.reviews.map(r=>`<section class="review-body"><div class="review-meta"><span class="code">${r.event}</span><span>${r.date}</span></div><div class="review-grades"><div>${rating(r.chill,'chill')}</div><div>${rating(r.grading,'grading')}</div></div><p>${r.text}</p><span class="report-link">Report review</span></section>`).join('')}`;
 const items=(xs)=>`<ul>${xs.map(item=>`<li>${item.text||''}${item.children?items(item.children):''}</li>`).join('')}</ul>`;
 return `${back(d.code)}<div class="page-intro"><h2>Discussion Items</h2><p>${d.title}</p></div><div class="reading-content">${d.notes.map(n=>`<details class="detail-section reading-section" open><summary><h3>${n.title}</h3><svg class="collapse-chevron" viewBox="0 0 24 24" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg></summary><div class="section-body">${items(n.items)}</div></details>`).join('')}</div>`;
}
if(detailStudies){
 document.querySelector('.studio-label').textContent='PRIMARY GOUGE / DETAIL SCREENS / ROUND 06';
 document.querySelector('.studio h1').textContent='Three screens. Three directions each.';
 document.querySelector('.studio p:not(.studio-label)').textContent='Same Home language, with task-specific composition. A, B, and C use identical content.';
 document.querySelector('.studio aside').innerHTML='Light mode · 393 × 852<br>Event and discussion text comes from the app.<br>Instructor identity, ratings, and reviews are fictional.';
 const links=document.querySelector('.comparison-links');links.innerHTML=['eventdetail','instructordetail','discussion'].map(kind=>`<a href="?round=6&kind=${kind}">${({eventdetail:'Event detail',instructordetail:'Instructor detail',discussion:'Discussion reading'})[kind]} A–C</a>`).join('')+'<a href="?round=6">All nine</a>';
 const kind=new URLSearchParams(location.search).get('kind');if(['eventdetail','instructordetail','discussion'].includes(kind))document.querySelectorAll('.study').forEach(el=>el.hidden=!el.id.startsWith('study-'+kind));
 document.querySelector('.studio-footer').innerHTML='All detail patterns are proposals for review. Static studies; no app code changes. <a href="?round=4">Selected root screens</a>';
}

if(instructorHybrid){
 document.querySelector('.studio-label').textContent='PRIMARY GOUGE / INSTRUCTOR DETAIL REFINEMENT / ROUND 07';
 document.querySelector('.studio h1').textContent='Separate reviews. Stronger summary.';
 document.querySelector('.studio p:not(.studio-label)').textContent='A’s open identity + B’s individual review cards. Only the overall summary treatment varies.';
 document.querySelector('.comparison-links').innerHTML='<a href="?round=6&kind=instructordetail">Previous detail options</a>';
 document.querySelector('.studio-footer').textContent='Three proposed summaries. Same fictional data and review cards; no production changes.';
}

function flashPage(id){
 const d=window.flashcardContent,kind=id.split('-')[1],card=d.cards[0];
 const answer=card.answer.split('\n').map(line=>`<span class="answer-line">${line}</span>`).join('');
 if(kind==='deck')return `<div class="detail-bar">${icon('arrow')}<span>${d.code}</span></div><div class="page-intro"><span class="code code-pill">${d.code}</span><h2>${d.title}</h2><p>Flashcard deck</p></div><section class="deck-actions"><div class="deck-stat"><strong>7</strong><span>cards in this deck</span><span class="new-state">7 new</span></div><button class="resume" type="button">Smart Review ${icon('arrow')}</button><button class="full-deck" type="button">${icon('book')} Study Full Deck</button></section><section class="deck-list"><h3>All cards</h3>${d.cards.map(c=>`<div class="deck-row"><span class="new-state">New</span><h4>${c.prompt}</h4><p>${c.answer.split('\n')[0]}</p></div>`).join('')}</section>`;
 const back=kind==='answer';
 return `<div class="detail-bar">${icon('arrow')}<span>${d.code}</span></div><div class="session-header"><div><span class="code code-pill">${d.code}</span><h2>${d.title}</h2></div><span class="card-position">Card 1 of 7</span></div><div class="session-progress" aria-label="Card 1 of 7"><span></span></div><div class="flash-stack"><div class="study-card ${back?'is-answer':''}" role="button" tabindex="0" aria-label="${back?'Hide answer':'Reveal answer'}"><div class="flash-face front-face"><div class="face-header"><span>Prompt</span>${icon('book')}</div><p class="flash-prompt">${card.prompt}</p><div class="face-footer"><span>Tap the card to reveal the answer.</span><span>Front</span></div></div><div class="flash-face back-face"><div class="face-header"><span>Answer</span>${icon('book')}</div><div class="flash-answer">${answer}</div><div class="face-footer"><span>Tap the card to hide the answer.</span><span>Back</span></div></div></div></div><section class="rating-controls ${back?'':'hidden-rating'}"><h3>How well did you know it?</h3><div class="rating-buttons">${['Missed','Hard','Good','Easy'].map((x,i)=>`<button type="button" class="grade-${i}">${x}</button>`).join('')}</div></section>`;
}
if(flashStudies){
 document.querySelector('.studio-label').textContent='PRIMARY GOUGE / FLASHCARD STUDIES / ROUND 08';
 document.querySelector('.studio h1').textContent='Real cards. Three ways to study.';
 document.querySelector('.studio p:not(.studio-label)').textContent='Three options each for deck overview, question side, and answer side. Same content and locked visual language.';
 document.querySelector('.studio aside').innerHTML='Light mode · 393 × 852<br>Actual FAM2101 prompts and answers.<br>Study state is sample data; rating buttons are static.';
 document.querySelector('.comparison-links').innerHTML=['deck','question','answer'].map(kind=>`<a href="?round=8&kind=${kind}">${kind[0].toUpperCase()+kind.slice(1)} A–C</a>`).join('')+'<a href="?round=8">All nine</a>';
 const kind=new URLSearchParams(location.search).get('kind');if(['deck','question','answer'].includes(kind))document.querySelectorAll('.study').forEach(el=>el.hidden=!el.id.startsWith('study-flash-'+kind));
 document.querySelector('.studio-footer').textContent='Tap a question or answer card to preview both faces. Review actions and ratings do not save or navigate. All options await review.';
 document.querySelectorAll('.study-card').forEach(card=>{const flip=()=>{card.classList.toggle('is-answer');const back=card.classList.contains('is-answer');card.setAttribute('aria-label',back?'Hide answer':'Reveal answer');card.closest('.screen').querySelector('.rating-controls').classList.toggle('hidden-rating',!back)};card.addEventListener('click',flip);card.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();flip()}})});
}

if(selectedFlash){
 document.querySelector('.studio-label').textContent='PRIMARY GOUGE / FLASHCARD REFINEMENT / ROUND 09';
 document.querySelector('.studio h1').textContent='Individual cards. A cleaner study flow.';
 document.querySelector('.studio p:not(.studio-label)').textContent='Your selected C direction, with individual deck cards and tighter rating buttons.';
 document.querySelector('.comparison-links').innerHTML='<a href="?round=9">Selected screens</a><a href="?round=8">Previous A–C options</a>';
 document.querySelector('.studio-footer').textContent='Tap a study card to preview its reverse. Rating controls remain static. No production changes.';
}
