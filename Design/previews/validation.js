// Browser-only theme/text stress study; this is not native Dynamic Type.
(() => {
 const q=new URLSearchParams(location.search),dark=q.get('theme')==='dark',large=q.get('text')==='large';
 const stage=q.get('qa-stage');if(stage&&document.querySelector('#stage')){document.querySelector('#stage').value=stage;document.querySelector('#stage').dispatchEvent(new Event('change'));}
 const focus=q.get('focus');if(focus)document.querySelectorAll('.study').forEach(study=>{const phone=study.querySelector('.phone');if(phone&&!phone.classList.contains('ob-'+focus)&&!phone.classList.contains('banner-'+focus))study.hidden=true});
 if(q.get('frame')==='1'){document.body.classList.add('validation-frame');window.addEventListener('message',e=>{if(e.origin!==location.origin||!['qa-top','qa-bottom'].includes(e.data))return;document.querySelectorAll('.study:not([hidden]) .screen').forEach(el=>el.scrollTop=e.data==='qa-bottom'?el.scrollHeight:0)});}
 const parse=c=>{const m=c.match(/^rgba?\((\d+)[, ]+(\d+)[, ]+(\d+)(?:[, /]+([\d.]+))?\)$/);return m?[+m[1],+m[2],+m[3],m[4]===undefined?1:+m[4]]:null};
 const light=c=>c?(.2126*c[0]+.7152*c[1]+.0722*c[2])/255:0;
 const out=c=>`rgba(${c[0]},${c[1]},${c[2]},${c[3]??1})`;
 const blend=(c,target,t)=>out(c.map((v,i)=>i<3?Math.round(v*(1-t)+target[i]*t):v));
 const bg=c=>{if(!c||c[3]===0)return null;if(c[0]>235&&c[1]>235&&c[2]>235)return out([29,39,54,c[3]]);if(light(c)<.7)return null;if(c[0]>c[2]+18)return out([64,48,24,c[3]]);if(c[1]>c[0]+8&&c[1]>c[2]+3)return out([25,53,44,c[3]]);if(c[2]>c[0]+5)return out([30,46,72,c[3]]);return out([30,40,57,c[3]])};
 const apply=()=>{
 if(focus)document.querySelectorAll('.study').forEach(study=>{const phone=study.querySelector('.phone');if(phone&&!phone.classList.contains('ob-'+focus)&&!phone.classList.contains('banner-'+focus))study.hidden=true});
 document.querySelectorAll('.phone').forEach(phone=>{
 if(phone.dataset.qaApplied)return;phone.dataset.qaApplied='true';
 const nodes=[phone,...phone.querySelectorAll('*')];const saved=nodes.map(el=>{const s=getComputedStyle(el);return {el,color:s.color,bg:s.backgroundColor,image:s.backgroundImage,border:s.borderColor,size:s.fontSize,line:s.lineHeight}});
 if(dark){phone.classList.add('qa-dark');for(const x of saved){let c=parse(x.color);if(c&&c[3]>0){if(c[0]===24&&c[1]===38&&c[2]===59)x.el.style.color='#e8eef8';else if(c[0]===99&&c[1]===112&&c[2]===134)x.el.style.color='#a9b5c7';else if(light(c)<.35)x.el.style.color=blend(c,[231,238,249],.78);else if(light(c)<.62)x.el.style.color=blend(c,[231,238,249],.48);}const b=bg(parse(x.bg));if(b)x.el.style.backgroundColor=b;let border=parse(x.border);if(border&&light(border)>.65)x.el.style.borderColor=bg(border)||'#38485d';if(x.image!=='none'&&/gradient/.test(x.image))x.el.style.backgroundImage=x.image.replace(/rgba?\([^)]*\)/g,c=>bg(parse(c))||c);}
 phone.style.backgroundColor='#111923';phone.style.setProperty('--ink','#e8eef8');phone.style.setProperty('--muted','#a9b5c7');phone.style.setProperty('--paper','#111923');phone.style.setProperty('--blue','#2867da');
 }
 if(dark){
 const ratingInk={'rgb(168, 42, 35)':'#FF968E','rgb(168, 67, 23)':'#FFB18A','rgb(135, 96, 14)':'#F1CA79','rgb(116, 107, 32)':'#DDD08B','rgb(61, 121, 39)':'#A3DC8C','rgb(35, 119, 44)':'#84D99C','rgb(25, 111, 49)':'#71D99B'};
 for(const x of saved){if(x.el.matches('.rating-pair strong,.review-grades strong,.rating-description')&&ratingInk[x.color])x.el.style.setProperty('color',ratingInk[x.color],'important');}
 }
 if(large){phone.classList.add('qa-large');for(const x of saved){x.el.style.fontSize=(parseFloat(x.size)*1.3)+'px';if(x.line.endsWith('px'))x.el.style.lineHeight=(parseFloat(x.line)*1.3)+'px';}}
 });
 };apply();document.addEventListener('click',()=>queueMicrotask(apply));document.addEventListener('change',()=>queueMicrotask(apply));
})();
