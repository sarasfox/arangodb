'use strict';

////////////////////////////////////////////////////////////////////////////////
/// @brief Foxx Sessions
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2013 triagens GmbH, Cologne, Germany
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///     http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
/// Copyright holder is triAGENS GmbH, Cologne, Germany
///
/// @author Jan Steemann, Lucas Dohmen
/// @author Copyright 2013, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

var Foxx = require('org/arangodb/foxx');
var crypto = require('org/arangodb/crypto');

// -----------------------------------------------------------------------------
// --SECTION--                                                  helper functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief decorates the controller with session logic
////////////////////////////////////////////////////////////////////////////////

function decorateController(auth, controller) {
  var cfg = auth.configuration;

  controller.before('/*', function (req) {
    var sessions = auth.getSessionStorage();
    var sid;
    if (cfg.cookie) {
      sid = req.cookie(cfg.cookie.name, cfg.cookie.secret ? {
        signed: {
          secret: cfg.cookie.secret,
          algorithm: cfg.cookie.algorithm
        }
      } : undefined);
    }
    if (!sid && cfg.header) {
      sid = req.headers[cfg.header.toLowerCase()];
    }
    if (sid) {
      if (cfg.jwt) {
        sid = crypto.jwtDecode(cfg.jwt.secret, sid, !cfg.jwt.verify);
      }
      try {
        req.session = sessions.get(sid);
      } catch (e) {
        if (!(e instanceof sessions.errors.SessionNotFound)) {
          throw e;
        }
      }
    }
    if (!req.session && cfg.autoCreateSession) {
      req.session = sessions.create();
    }
  });

  controller.after('/*', function (req, res) {
    if (req.session) {
      var sid = req.session.forClient();
      if (cfg.jwt) {
        sid = crypto.jwtEncode(cfg.jwt.secret, sid, cfg.jwt.algorithm);
      }
      if (cfg.cookie) {
        res.cookie(cfg.cookie.name, sid, {
          ttl: req.session.getTTL() / 1000,
          signed: cfg.cookie.secret ? {
            secret: cfg.cookie.secret,
            algorithm: cfg.cookie.algorithm
          } : undefined
        });
      }
      if (cfg.header) {
        res.set(cfg.header, sid);
      }
    }
  });
}

////////////////////////////////////////////////////////////////////////////////
/// @brief convenience wrapper for session destruction logic
////////////////////////////////////////////////////////////////////////////////

function createDestroySessionHandler(auth, opts) {
  if (!opts) {
    opts = {};
  }
  if (typeof opts === 'function') {
    opts = {after: opts};
  }
  if (!opts.after) {
    opts.after = function (req, res) {
      res.json({message: 'logged out'});
    };
  }
  var cfg = auth.configuration;
  return function (req, res, injected) {
    if (typeof opts.before === 'function') {
      opts.before(req, res, injected);
    }
    if (req.session && typeof req.session.delete === 'function') {
      req.session.delete();
    }
    if (cfg.autoCreateSession) {
      req.session = auth.getSessionStorage().create();
    } else {
      if (cfg.cookie) {
        res.cookie(cfg.cookie.name, '', {
          ttl: -(7 * 24 * 60 * 60),
          sign: cfg.cookie.secret ? {
            secret: cfg.cookie.secret,
            algorithm: cfg.cookie.algorithm
          } : undefined
        });
      }
      delete req.session;
    }
    if (typeof opts.after === 'function') {
      opts.after(req, res, injected);
    }
  };
}

// -----------------------------------------------------------------------------
// --SECTION--                                                     FOXX SESSIONS
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// --SECTION--                                      constructors and destructors
// -----------------------------------------------------------------------------

var sessionTypes = ['cookie', 'header'];

////////////////////////////////////////////////////////////////////////////////
/// @brief constructor
////////////////////////////////////////////////////////////////////////////////

function Sessions(opts) {
  if (!opts) {
    opts = {};
  }

  if (opts.type) {
    console.warn(
      'The Foxx session option "type" is deprecated and will be removed.'
      + ' Use the options "cookie" and/or "header" instead.'
    );
    if (opts.type === 'cookie') {
      delete opts.header;
      opts.cookie = opts.cookie || true;
    } else if (opts.type === 'header') {
      delete opts.cookie;
      opts.header = opts.header || true;
    } else {
      throw new Error('Only the following session types are supported at this time: ' + sessionTypes.join(', '));
    }
  }

  if (opts.cookie) {
    if (opts.cookie === true) {
      opts.cookie = {};
    } else if (typeof opts.cookie === 'string') {
      opts.cookie = {name: opts.cookie};
    } else if (typeof opts.cookie !== 'object') {
      throw new Error('Expected cookie settings to be an object, boolean or string.');
    }
    if (!opts.cookie.name) {
      opts.cookie.name = 'sid';
    } else if (typeof opts.cookie.name !== 'string') {
      throw new Error('Cookie name must be a string or empty.');
    }
    if (opts.cookie.secret && typeof opts.cookie.secret !== 'string') {
      throw new Error('Cookie secret must be a string or empty.');
    }
  }
  if (opts.header) {
    if (opts.header === true) {
      opts.header = 'X-Session-Id';
    } else if (typeof opts.header !== 'string') {
      throw new Error('Header name must be true, a string or empty.');
    }
  }
  if (opts.jwt) {
    // TODO Remove this in 2.7
    console.warn(
      'The Foxx session option "jwt" is deprecated and will be removed.'
      + ' Please use the session-jwt app instead.'
    );
    if (opts.jwt === true) {
      opts.jwt = {};
    } else if (typeof opts.jwt === 'string') {
      opts.jwt = {secret: opts.jwt};
    } else if (typeof opts.jwt !== 'object') {
      throw new Error('Expected JWT settings to be an object, boolean or string.');
    }
    if (opts.jwt.verify !== false) {
      opts.jwt.verify = true;
    }
    if (!opts.jwt.secret) {
      opts.jwt.secret = '';
      if (!opts.jwt.algorithm) {
        opts.jwt.algorithm = 'none';
      } else if (opts.jwt.algorithm !== 'none') {
        throw new Error('Must provide a JWT secret to use any algorithm other than "none".');
      }
    } else {
      if (typeof opts.jwt.secret !== 'string') {
        throw new Error('Header JWT secret must be a string or empty.');
      }
      if (!opts.jwt.algorithm) {
        opts.jwt.algorithm = 'HS256';
      } else {
        opts.jwt.algorithm = crypto.jwtCanonicalAlgorithmName(opts.jwt.algorithm);
      }
    }
  }
  if (opts.autoCreateSession !== false) {
    opts.autoCreateSession = true;
  }
  if (!opts.sessionStorage) {
    if (opts.sessionStorageApp) {
      // TODO Remove this in 2.7
      console.warn(
        'The Foxx session option "sessionStorageApp" has been renamed to "sessionStorage".'
        + ' Use the option "sessionStorage" instead.'
      );
      opts.sessionStorage = opts.sessionStorageApp;
    } else {
      opts.sessionStorage = '/_system/sessions';
    }
  }
  this.configuration = opts;
}

// -----------------------------------------------------------------------------
// --SECTION--                                                  public functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief fetches the session storage
////////////////////////////////////////////////////////////////////////////////

Sessions.prototype.getSessionStorage = function () {
  if (typeof this.configuration.sessionStorage !== 'string') {
    return this.configuration.sessionStorage;
  }
  return Foxx.requireApp(this.configuration.sessionStorage).sessionStorage;
};

// -----------------------------------------------------------------------------
// --SECTION--                                                    module exports
// -----------------------------------------------------------------------------

exports.sessionTypes = sessionTypes;
exports.Sessions = Sessions;
exports.decorateController = decorateController;
exports.createDestroySessionHandler = createDestroySessionHandler;

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

/// Local Variables:
/// mode: outline-minor
/// outline-regexp: "/// @brief\\|/// @addtogroup\\|/// @page\\|// --SECTION--\\|/// @\\}\\|/\\*jslint"
/// End:
