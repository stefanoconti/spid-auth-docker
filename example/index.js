// Copyright 2018 AgID - Agenzia per l'Italia Digitale
//
// Licensed under the EUPL, Version 1.2 or - as soon they will be approved by
// the European Commission - subsequent versions of the EUPL (the "Licence").
//
// You may not use this work except in compliance with the Licence.
//
// You may obtain a copy of the Licence at:
//
//    https://joinup.ec.europa.eu/software/page/eupl
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the Licence is distributed on an "AS IS" basis, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// Licence for the specific language governing permissions and limitations
// under the Licence.
const express = require('express');
const path = require('path');
const session = require('express-session');

const PORT = 8080;
const SERVER_NAME = process.env.SERVER_NAME || 'localhost';

const app = express();

app.use(express.static('static'));

app.use(session({
  secret: 's3cr3t',
  cookie: {
    maxAge: 3600,
  },
}));

/**
 * Index page
 */
app.get('/', (req, res) => {
  const { fiscalNumber, name } = req.session;
  if (fiscalNumber && name) {
    res.send(`You are logged as ${name} (${fiscalNumber})<br/>`
      + `<a href="https://${SERVER_NAME}/iam/Logout`
      + '?return=/logout">Logout</a>');
  } else {
    res.sendFile(path.join(__dirname + '/static/pages/smart-button.html'));
  }
});

/**
 * Login callback (/iam/Login?entityId=...&target=https://<SERVER_NAME>/login)
 */
app.get('/login', (req, res) => {
  const fiscalNumber = req.get('FISCALNUMBER');
  const name = req.get('NAME');

  if (fiscalNumber && name) {
    console.log(`Got login headers (${fiscalNumber}, ${name})`);
    req.session.fiscalNumber = fiscalNumber;
    req.session.name = name;
    res.redirect('/');
  } else {
    res.status(400).send('Bad request');
  }
});

/**
 * Logout callback (/iam/Logout?return=/logout)
 */
app.get('/logout', (req, res) => {
  req.session.destroy((err) => {
    console.log('Successfully logged out');
    res.redirect('/');
  });
});

/**
 * Free access resource
 */
app.get('/other', (req, res) => {
  res.sendFile(path.join(__dirname + '/static/pages/other.html'));
});

/**
 * Manage error query string
 * https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPErrors
 */
app.get('/error', (req, res) => {
  const { errorType, errorText, entityID, now } = req.query;
  res.send({
    entityID,
    errorText,
    errorType,
    now,
  });
});

app.listen(PORT, () => {
  console.log(`App listening on port ${PORT}`);
});
