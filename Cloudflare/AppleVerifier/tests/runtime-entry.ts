// Local runtime smoke test only. Never used as the production entrypoint.
import {Buffer} from 'node:buffer';
import {X509Certificate} from 'node:crypto';
import fixtures from './fixtures/certificates.json';
export default {async fetch(){const {SignedDataVerifier,Environment}=await import('@apple/app-store-server-library');class Probe extends SignedDataVerifier {
 async checkChain(){return await this.verifyCertificateChain(this.rootCertificates,new X509Certificate(Buffer.from(fixtures.REAL_APPLE_SIGNING_CERTIFICATE_BASE64_ENCODED,'base64')),new X509Certificate(Buffer.from(fixtures.REAL_APPLE_INTERMEDIATE_BASE64_ENCODED,'base64')),new Date());}
}
const p=new Probe([Buffer.from(fixtures.REAL_APPLE_ROOT_BASE64_ENCODED,'base64')],true,Environment.SANDBOX,'bolt.Primary-Gouge');try {await p.checkChain();await p.checkChain();return Response.json({chain:true,onlineRevocation:true,cachedRepeat:true});} catch(e) {return Response.json({error:String(e),status:(e as any).status,cause:String((e as any).cause),stack:(e as any).cause?.stack}, {status:500});}}};
