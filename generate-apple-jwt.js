const fs = require('fs');
const jwt = require('jsonwebtoken');

// Fill in your actual file name if different
const privateKey = fs.readFileSync('./AuthKey_BL9CXTN55S.p8').toString();
const teamId = '4D9DUT5BN5'; // Your Apple Team ID
const clientId = 'com.ridewealthassistant.app'; // Your App ID
const keyId = 'BL9CXTN55S'; // Your Key ID

const token = jwt.sign({}, privateKey, {
  algorithm: 'ES256',
  expiresIn: '180d',
  audience: 'https://appleid.apple.com',
  issuer: teamId,
  subject: clientId,
  keyid: keyId,
});

console.log(token); 