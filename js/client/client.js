/*jshint -W051:true */
/*global global:true, window, require */
'use strict';

////////////////////////////////////////////////////////////////////////////////
/// @brief ArangoShell client API
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2004-2013 triAGENS GmbH, Cologne, Germany
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
/// @author Achim Brandt
/// @author Copyright 2012-2013, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////

if (typeof global === 'undefined' && typeof window !== 'undefined') {
  global = window;
}

// -----------------------------------------------------------------------------
// --SECTION--                                                  global functions
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
// @brief common globals
////////////////////////////////////////////////////////////////////////////////

global.Buffer = require("buffer").Buffer;
global.process = require("process");
global.setInterval = global.setInterval || function () {};
global.clearInterval = global.clearInterval || function () {};
global.setTimeout = global.setTimeout || function () {};
global.clearTimeout = global.clearTimeout || function () {};

////////////////////////////////////////////////////////////////////////////////
/// @brief start paging
////////////////////////////////////////////////////////////////////////////////

global.start_pager = function start_pager () {
  var internal = require("internal");
  internal.startPager();
};

////////////////////////////////////////////////////////////////////////////////
/// @brief stop paging
////////////////////////////////////////////////////////////////////////////////

global.stop_pager = function stop_pager () {
  var internal = require("internal");
  internal.stopPager();
};

////////////////////////////////////////////////////////////////////////////////
/// @brief print the overall help
////////////////////////////////////////////////////////////////////////////////

global.help = function help () {
  var internal = require("internal");
  var arangodb = require("org/arangodb");
  var arangosh = require("org/arangodb/arangosh");

  internal.print(arangosh.HELP);
  arangodb.ArangoDatabase.prototype._help();
  arangodb.ArangoCollection.prototype._help();
  arangodb.ArangoStatement.prototype._help();
  arangodb.ArangoQueryCursor.prototype._help();
  internal.print(arangosh.helpExtended);
};

////////////////////////////////////////////////////////////////////////////////
/// @brief clear screen (poor man's way)
////////////////////////////////////////////////////////////////////////////////

global.clear = function clear () {
  var internal = require("internal");
  var result = '';

  for (var i = 0; i < 100; ++i) {
    result += '\n';
  }
  internal.print(result);
};

////////////////////////////////////////////////////////////////////////////////
/// @brief global 'console'
////////////////////////////////////////////////////////////////////////////////

global.console = global.console || require("console");

////////////////////////////////////////////////////////////////////////////////
/// @brief global 'db'
////////////////////////////////////////////////////////////////////////////////

global.db = require("org/arangodb").db;

////////////////////////////////////////////////////////////////////////////////
/// @brief global 'arango'
////////////////////////////////////////////////////////////////////////////////

global.arango = require("org/arangodb").arango;

////////////////////////////////////////////////////////////////////////////////
/// @brief global 'fm'
////////////////////////////////////////////////////////////////////////////////

global.fm = require("org/arangodb/foxx/manager");

////////////////////////////////////////////////////////////////////////////////
/// @brief global 'ArangoStatement'
////////////////////////////////////////////////////////////////////////////////

global.ArangoStatement = require("org/arangodb/arango-statement").ArangoStatement;

////////////////////////////////////////////////////////////////////////////////
/// @brief shell tutorial
////////////////////////////////////////////////////////////////////////////////

global.tutorial = require("org/arangodb/tutorial");

// -----------------------------------------------------------------------------
// --SECTION--                                                        initialise
// -----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////////
/// @brief prints help
////////////////////////////////////////////////////////////////////////////////

var initHelp = function() {
  var internal = require("internal");

  if (internal.db) {
    try {
      internal.db._collections();
    }
    catch (e) {}
  }

  if (internal.quiet !== true) {
    require("org/arangodb").checkAvailableVersions();

    if (internal.arango && internal.arango.isConnected && internal.arango.isConnected()) {
      internal.print("Type 'tutorial' for a tutorial or 'help' to see common examples");
    }
  }
};

////////////////////////////////////////////////////////////////////////////////
/// @brief read rc file
////////////////////////////////////////////////////////////////////////////////

if (typeof window === 'undefined') {
  // We're in arangosh
  initHelp();

  // these variables are not defined in the browser context
  if (
    global.IS_EXECUTE_SCRIPT ||
    global.IS_EXECUTE_STRING ||
    global.IS_CHECK_SCRIPT ||
    global.IS_UNIT_TESTS ||
    global.IS_JS_LINT
  ) {
    try {
      // this will not work from within a browser
      var __fs__ = require("fs");
      var __rcf__ = __fs__.join(__fs__.home(), ".arangosh.rc");

      if (__fs__.exists(__rcf__)) {
        /*jshint evil: true */
        var __content__ = __fs__.read(__rcf__);
        eval(__content__);
      }
    }
    catch (e) {
      require("console").warn("arangosh.rc: %s", String(e));
    }
  }

  try {
    delete global.IS_EXECUTE_SCRIPT;
    delete global.IS_EXECUTE_STRING;
    delete global.IS_CHECK_SCRIPT;
    delete global.IS_UNIT_TESTS;
    delete global.IS_JS_LINT;
  } catch (e) {}
}

// -----------------------------------------------------------------------------
// --SECTION--                                                       END-OF-FILE
// -----------------------------------------------------------------------------

// Local Variables:
// mode: outline-minor
// outline-regexp: "\\(/// @brief\\|/// @addtogroup\\|// --SECTION--\\|/// @page\\|/// @\\}\\)"
// End:
