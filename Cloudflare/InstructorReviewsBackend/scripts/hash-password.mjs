import { pbkdf2Sync, randomBytes } from "node:crypto";

const password = process.argv[2];

if (!password) {
  console.error("Usage: npm run moderator:hash -- '<password>'");
  process.exit(1);
}

const iterations = 100000;
const salt = randomBytes(16);
const hash = pbkdf2Sync(password, salt, iterations, 32, "sha256");

console.log(`pbkdf2$${iterations}$${salt.toString("base64url")}$${hash.toString("base64url")}`);
