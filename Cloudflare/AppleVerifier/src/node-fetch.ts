// Transport adapter only: Apple's verifier and OCSP validation remain unchanged.
import {Buffer} from 'node:buffer';
export const Headers = globalThis.Headers;
export const Request = globalThis.Request;
export const Response = globalThis.Response;
export default async function workerFetch(input: string, init: RequestInit & {timeout?:number} = {}) {
  const {timeout,...options}=init;
  const url = new URL(input);
  const headers = new Headers(options.headers);
  if (!headers.has("user-agent")) headers.set("user-agent", "node-fetch/1.0 (+https://github.com/bitinn/node-fetch)");
  if (!headers.has("accept")) headers.set("accept", "*/*");
  if (options.body instanceof Uint8Array) headers.set("content-length", String(options.body.byteLength));
  const response=await globalThis.fetch(url,{...options,headers,signal:options.signal ?? AbortSignal.timeout(timeout ?? 30_000)});
  if (!response.ok) throw new Error(`OCSP transport HTTP ${response.status}`);
  return Object.assign(response,{buffer:async()=>Buffer.from(await response.arrayBuffer())});
}
