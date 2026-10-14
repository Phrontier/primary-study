import test from 'node:test';
import assert from 'node:assert/strict';
import {build} from 'esbuild';
import {Miniflare} from 'miniflare';
import {readFile, readdir} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';

const bundle = join(tmpdir(), `primary-gouge-worker-test-${process.pid}.mjs`);
await build({entryPoints:['src/index.ts'],bundle:true,format:'esm',platform:'node',outfile:bundle});
const worker = (await import(bundle)).default;
const mf = new Miniflare({modules:true,script:'export default {fetch(){return new Response("test")}}',d1Databases:['DB'],compatibilityDate:'2026-05-28'});
const DB = await mf.getD1Database('DB');
for (const file of (await readdir('migrations')).filter(x=>x.endsWith('.sql')).sort()) {
  const sql = await readFile(`migrations/${file}`, 'utf8');
  for (const statement of sql.split(';').map(x=>x.trim()).filter(Boolean)) await DB.prepare(statement).run();
}
const env={DB,AUTH_SESSION_SECRET:'test-only',MODERATOR_SESSION_SECRET:'test-only',SUPABASE_URL:'https://auth.test',SUPABASE_PUBLISHABLE_KEY:'test-only'};
const originalFetch=globalThis.fetch;
globalThis.fetch=async (url,opts)=>{
  const moderator=opts.headers.authorization==='Bearer moderator';
  if(String(url).includes('/auth/v1/user')) return Response.json({id:moderator?'moderator':'contributor'});
  if(String(url).includes('/rest/v1/account_roles')) return Response.json(moderator?[{permission:'instructor_gouge_moderator'}]:[]);
  throw new Error(`Unexpected authentication request ${url}`);
};
const request=(path,token,method='GET',body)=>worker.fetch(new Request(`https://worker.test${path}`,{method,headers:{...(token?{authorization:`Bearer ${token}`}:{ }), 'content-type':'application/json'},...(body?{body:JSON.stringify(body)}:{})}),env,{waitUntil(){}});

test('moderation bans are permission restricted, persistent, enforced, and reversible', async ()=>{
 try {
  await DB.prepare(`INSERT INTO review_submissions (id,instructor_name,squadron_id,event_kind,chill_score,grading_score,review_text,submitted_at,updated_at,created_at,submitter_client_id,submitter_user_id) VALUES ('test-review','Test Instructor','VT-27','flight',3,3,'Test content','2026-10-04','2026-10-04','2026-10-04','test-client','contributor')`).run();
  assert.equal((await request('/v1/moderation/submissions/test-review/ban','user','POST')).status,403);
  assert.equal((await request('/v1/moderation/submissions/test-review/ban','moderator','POST')).status,204);
  assert.equal((await DB.prepare("SELECT is_active FROM contributor_bans WHERE user_id='contributor'").first()).is_active,1);
  for(const path of ['/v1/submissions','/v1/reports','/v1/me/reviews/test-review/edit','/v1/community/submissions']) {
   assert.equal((await request(path,'user','POST',{category:'feedback'})).status,403,path);
   assert.equal((await request(path,null,'POST',{})).status,401,`anonymous ${path}`);
  }
  assert.equal((await request('/v1/moderation/bans','user')).status,403);
  assert.equal((await (await request('/v1/moderation/bans','moderator')).json()).bans.length,1);
  // Support remains reachable for appeals; validation fails on this deliberately empty payload.
  assert.equal((await request('/v1/community/submissions','user','POST',{category:'support'})).status,400);
  assert.equal((await request('/v1/moderation/bans/contributor','user','DELETE')).status,403);
  assert.equal((await request('/v1/moderation/bans/contributor','moderator','DELETE')).status,204);
  assert.equal((await DB.prepare("SELECT is_active FROM contributor_bans WHERE user_id='contributor'").first()).is_active,0);
  assert.equal((await request('/v1/submissions','user','POST',{})).status,400);
 } finally { globalThis.fetch=originalFetch; await mf.dispose(); }
});
