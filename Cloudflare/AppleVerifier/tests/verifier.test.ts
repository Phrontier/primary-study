import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Buffer} from 'node:buffer';
import {sign, X509Certificate} from 'node:crypto';
import {SignedDataVerifier,Environment,VerificationException,VerificationStatus} from '@apple/app-store-server-library';
import {handle,verify} from '../src/index.ts';
const f=JSON.parse(readFileSync(new URL('./fixtures/certificates.json',import.meta.url),'utf8'));
const original=readFileSync(new URL('./fixtures/transactionInfo.jws',import.meta.url),'utf8').trim();
const chain=f.JWT_CHAIN;
const claims=JSON.parse(Buffer.from(original.split('.')[1],'base64url').toString());
function signed(claims:object){const parts=original.split('.');parts[1]=Buffer.from(JSON.stringify(claims)).toString('base64url');return parts.join('.');}
const fixtureVerifier=(environment=Environment.SANDBOX,bundle=claims.bundleId)=>new SignedDataVerifier([Buffer.from(f.JWT_ROOT,'base64')],false,environment,bundle,environment===Environment.PRODUCTION?1234:undefined);
const env={APPLE_VERIFIER_TOKEN:'x'.repeat(48)};
const request=(body:unknown,token='Bearer '+env.APPLE_VERIFIER_TOKEN)=>new Request('https://test.invalid/verify',{method:'POST',headers:{authorization:token,'content-type':'application/json'},body:JSON.stringify(body)});
test('Apple fixture chain and signed transaction validate',async()=>assert.equal((await fixtureVerifier().verifyAndDecodeTransaction(original)).transactionId,claims.transactionId));
test('tampering, foreign app, environment and untrusted roots fail closed',async()=>{
 const valid=original;const parts=valid.split('.');parts[1]=Buffer.from(JSON.stringify({...claims,transactionId:'forged'})).toString('base64url');
 await assert.rejects(fixtureVerifier().verifyAndDecodeTransaction(parts.join('.')));
 await assert.rejects(fixtureVerifier(Environment.SANDBOX,'wrong').verifyAndDecodeTransaction(original));
 await assert.rejects(fixtureVerifier(Environment.PRODUCTION).verifyAndDecodeTransaction(original));
 await assert.rejects(verify('transaction',valid));
});
test('expired fixture certificates are rejected',async()=>await assert.rejects(fixtureVerifier().verifyAndDecodeTransaction(signed({...claims,signedDate:Date.UTC(2040,0,1)}))));
test('Xcode, malformed, missing chain and unsigned payloads rejected',async()=>{for(const payload of ['', 'a.b.c',signed({...claims,environment:'Xcode'}),Buffer.from('{"alg":"none"}').toString('base64url')+'.'+Buffer.from(JSON.stringify(claims)).toString('base64url')+'.']) await assert.rejects(verify('transaction',payload));});
test('service auth fails before verification',async()=>{let calls=0;const fake=async()=>{calls++;return claims};assert.equal((await handle(request({kind:'transaction',signedPayload:'test'},''),env,fake)).status,401);assert.equal((await handle(request({},'Bearer bad'),env,fake)).status,401);assert.equal(calls,0)});
test('body and payload bounds; versioned successful response',async()=>{
 assert.equal((await handle(request({kind:'transaction',signedPayload:'x'.repeat(50001)}),env)).status,400);
 assert.equal((await handle(request({kind:'notification',signedPayload:'x'.repeat(120000)}),env)).status,413);
 const response=await handle(request({kind:'transaction',signedPayload:'test'}),env,async()=>claims);assert.equal(response.status,200);assert.deepEqual(await response.json(),{version:1,kind:'transaction',payload:claims});
});
test('invalid signature and transient verification errors are distinct',async()=>{
 assert.equal((await handle(request({kind:'transaction',signedPayload:'test'}),env,async()=>{throw new VerificationException(VerificationStatus.INVALID_CERTIFICATE)})).status,422);
 assert.equal((await handle(request({kind:'transaction',signedPayload:'test'}),env,async()=>{throw new VerificationException(VerificationStatus.RETRYABLE_VERIFICATION_FAILURE)})).status,503);
});
test('all certificate APIs required by Apple work in Node',()=>{const cert=new X509Certificate(Buffer.from(f.REAL_APPLE_ROOT_BASE64_ENCODED,'base64'));assert.equal(cert.verify(cert.publicKey),true);assert.ok(cert.raw.length);assert.ok(cert.toString().includes('CERTIFICATE'));void cert.infoAccess;});
test('Apple certificate cache reuses valid results and rechecks expired entries',async()=>{
 class CacheProbe extends SignedDataVerifier {
  calls=0;
  protected override async checkOCSPStatus(){this.calls++;}
  async check(){return await this.verifyCertificateChain(this.rootCertificates,new X509Certificate(Buffer.from(f.JWT_CHAIN[0],'base64')),new X509Certificate(Buffer.from(f.JWT_CHAIN[1],'base64')),new Date());}
  expire(){for(const value of Object.values(this.verifiedPublicKeyCache))value.cacheExpiry=0;}
 }
 const p=new CacheProbe([Buffer.from(f.JWT_ROOT,'base64')],true,Environment.SANDBOX,claims.bundleId);
 await p.check();assert.equal(p.calls,2);await p.check();assert.equal(p.calls,2);p.expire();await p.check();assert.equal(p.calls,4);
});
