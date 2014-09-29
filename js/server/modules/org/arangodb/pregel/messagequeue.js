/*jslint indent: 2, nomen: true, maxlen: 120, sloppy: true, vars: true, white: true, plusplus: true */
/*global require, exports*/

////////////////////////////////////////////////////////////////////////////////
/// @brief Pregel module. Offers all submodules of pregel.
///
/// @file
///
/// DISCLAIMER
///
/// Copyright 2010-2014 triagens GmbH, Cologne, Germany
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
/// @author Michael Hackstein
/// @author Copyright 2011-2014, triAGENS GmbH, Cologne, Germany
////////////////////////////////////////////////////////////////////////////////
var p = require("org/arangodb/profiler");

var db = require("internal").db;
var _ = require("underscore");
var pregel = require("org/arangodb/pregel");
var query = "FOR m IN @@collection FILTER m.step == @step RETURN m";
var arangodb = require("org/arangodb");
var ERRORS = arangodb.errors;
var ArangoError = arangodb.ArangoError;

var VertexMessageQueue = function(parent, vertexInfo) {
  this._parent = parent;
  this._vertexInfo = vertexInfo;
  this._inc = [];
  this._pos = 0;
};


////////////////////////////////////////////////////////////////////////////////
/// @startDocuBlock JSF_pregel_vertex_message_count
/// @brief **VertexMessageQueue.count**
///
/// `pregel.VertexMessageQueue.count()`
///
/// Returns the amount of messages in the vertex message queue.
///
/// @EXAMPLES
///
/// @EXAMPLE_ARANGOSH_OUTPUT{pregelVertexMessageQueueCount}
/// ~  var pregel = require("org/arangodb/pregel");
/// | var queue = new pregel.MessageQueue(1, [{_doc : {_id : 1}, _locationInfo :
///   {_id : 1}}, {_doc : {_id : 2}, _locationInfo : {_id : 2}}]);
///   var vertexMessageQueue = queue[1];
///   vertexMessageQueue.count();
///   vertexMessageQueue._fill({plain : "This is a message"});
///   vertexMessageQueue.count();
/// @END_EXAMPLE_ARANGOSH_OUTPUT
/// @endDocuBlock
///
////////////////////////////////////////////////////////////////////////////////
VertexMessageQueue.prototype.count = function () {
  return this._inc.length;
};

////////////////////////////////////////////////////////////////////////////////
/// @startDocuBlock JSF_pregel_vertex_message_hasNext
/// @brief **VertexMessageQueue.hasNext**
///
/// `pregel.VertexMessageQueue.hasNext()`
///
/// Returns true if the message queue contains more messages.
///
/// @EXAMPLES
///
/// @EXAMPLE_ARANGOSH_OUTPUT{pregelVertexMessageQueuehasNext}
/// ~  var pregel = require("org/arangodb/pregel");
/// | var queue = new pregel.MessageQueue(1, [{_doc : {_id : 1}, _locationInfo : {_id : 1}},
///   {_doc : {_id : 2}, _locationInfo : {_id : 2}}]);
///   var vertexMessageQueue = queue[1];
///   vertexMessageQueue.hasNext();
///   vertexMessageQueue._fill({plain : "This is a message"});
///   vertexMessageQueue.hasNext();
/// @END_EXAMPLE_ARANGOSH_OUTPUT
/// @endDocuBlock
///
////////////////////////////////////////////////////////////////////////////////
VertexMessageQueue.prototype.hasNext = function () {
  return this._pos < this.count();
};

////////////////////////////////////////////////////////////////////////////////
/// @startDocuBlock JSF_pregel_vertex_message_next
/// @brief **VertexMessageQueue.next**
///
/// `pregel.VertexMessageQueue.next()`
///
/// Returns the next message in the vertex message queue.
///
/// @EXAMPLES
///
/// @EXAMPLE_ARANGOSH_OUTPUT{pregelVertexMessageQueueNext}
/// ~  var pregel = require("org/arangodb/pregel");
/// | var queue = new pregel.MessageQueue(1, [{_doc : {_id : 1}, _locationInfo : {_id : 1}},
///   {_doc : {_id : 2}, _locationInfo : {_id : 2}}]);
///   var vertexMessageQueue = queue[1];
///   vertexMessageQueue.next();
///   vertexMessageQueue._fill({plain : "This is a message"});
///   vertexMessageQueue.next();
/// @END_EXAMPLE_ARANGOSH_OUTPUT
/// @endDocuBlock
///
////////////////////////////////////////////////////////////////////////////////
VertexMessageQueue.prototype.next = function () {
  if (!this.hasNext()) {
    return null;
  }
  var next = this._inc[this._pos];
  this._pos++;
  return next;
};

////////////////////////////////////////////////////////////////////////////////
/// @startDocuBlock JSF_pregel_vertex_message_fill
/// @brief **VertexMessageQueue._fill**
///
/// `pregel.VertexMessageQueue._fill(msg)`
///
/// Adds a message to the vertex' message queue.
///
/// @PARAMS
/// @PARAM{msg, object, required} : The message to be added to the queue, can be a string or any object.
///
/// @EXAMPLES
///
/// @EXAMPLE_ARANGOSH_OUTPUT{pregelVertexMessageQueueFill}
/// ~  var pregel = require("org/arangodb/pregel");
/// | var queue = new pregel.MessageQueue(1, [{_doc : {_id : 1}, _locationInfo : {_id : 1}},
///   {_doc : {_id : 2}, _locationInfo : {_id : 2}}]);
///   var vertexMessageQueue = queue[1];
///   vertexMessageQueue.next();
///   vertexMessageQueue._fill({plain : "This is a message"});
///   vertexMessageQueue.next();
/// @END_EXAMPLE_ARANGOSH_OUTPUT
/// @endDocuBlock
///
////////////////////////////////////////////////////////////////////////////////
VertexMessageQueue.prototype._fill = function (msg) {
  if (msg.a) {
    this._inc.push({data: msg.a});
  }
  if (msg.plain) {
    this._inc = this._inc.concat(msg.plain);
  }
};

////////////////////////////////////////////////////////////////////////////////
/// @startDocuBlock JSF_pregel_vertex_message_clear
/// @brief **VertexMessageQueue._clear**
///
/// `pregel.VertexMessageQueue._clear()`
///
/// Empties the message queue.
///
/// @EXAMPLES
///
/// @EXAMPLE_ARANGOSH_OUTPUT{pregelVertexMessageQueueClear}
/// ~  var pregel = require("org/arangodb/pregel");
/// | var queue = new pregel.MessageQueue(1, [{_doc : {_id : 1}, _locationInfo : {_id : 1}},
///   {_doc : {_id : 2}, _locationInfo : {_id : 2}}]);
///   var vertexMessageQueue = queue[1];
///   vertexMessageQueue.count();
///   vertexMessageQueue._fill({plain : "This is a message"});
///   vertexMessageQueue.count();
///   vertexMessageQueue._clear();
///   vertexMessageQueue.count();
/// @END_EXAMPLE_ARANGOSH_OUTPUT
/// @endDocuBlock
///
////////////////////////////////////////////////////////////////////////////////
VertexMessageQueue.prototype._clear = function () {
  this._inc = [];
  this._pos = 0;
};


////////////////////////////////////////////////////////////////////////////////
/// @startDocuBlock JSF_pregel_vertex_message_sendTo
/// @brief **VertexMessageQueue.sendTo**
///
/// `pregel.VertexMessageQueue.sendTo(target, data, sendLocation)`
///
/// Sends a message to a vertex defined by target.
///
/// @PARAMS
/// @PARAM{target, object, required} : The recipient of the message, can either be a vertex _id or a
/// location object containing the attributes *_id* and *shard*.
/// @PARAM{data, object, required} : The message's content, can be a string or an object.
/// @PARAM{sendLocation, boolean, optional} : If false the location object of the sender is not added.
/// as *sender* to the message.
///
/// @EXAMPLES
///
/// Send a message with information about the sender.
/// @EXAMPLE_ARANGOSH_OUTPUT{pregelVertexMessageQueueSendTo}
/// ~  var pregel = require("org/arangodb/pregel");
/// | var queue = new pregel.MessageQueue(1, [{_doc : {_id : 1}, _locationInfo : {_id : 1}},
///   {_doc : {_id : 2}, _locationInfo : {_id : 2}}]);
///   var vertexMessageQueue = queue[1];
///   vertexMessageQueue.sendTo({_id : 2, shard : "shard"}, {msg : "This is a message"});
///   queue.__output;
/// @END_EXAMPLE_ARANGOSH_OUTPUT
/// Send a message without information about the sender.
/// @EXAMPLE_ARANGOSH_OUTPUT{pregelVertexMessageQueueSendToWithoutSender}
/// ~  var pregel = require("org/arangodb/pregel");
/// | var queue = new pregel.MessageQueue(1, [{_doc : {_id : 1}, _locationInfo : {_id : 1}},
///   {_doc : {_id : 2}, _locationInfo : {_id : 2}}]);
///   var vertexMessageQueue = queue[1];
///   vertexMessageQueue.sendTo({_id : 2, shard : "shard"}, {msg : "This is a message"}, false);
///   queue.__output;
/// @END_EXAMPLE_ARANGOSH_OUTPUT
/// @endDocuBlock
///
////////////////////////////////////////////////////////////////////////////////
VertexMessageQueue.prototype.sendTo = function (target, data, sendLocation) {
  var t = p.stopWatch();
  if (sendLocation !== false) {
    sendLocation = true; 
  }
  if (target && typeof target === "string" && target.match(/\S+\/\S+/)) {
    target = pregel.getLocationObject(this.__executionNumber, target);
  } else if (!(
    target && typeof target === "object" &&
                                target._id && target.shard
  )) {
    var err = new ArangoError();
    err.errorNum = ERRORS.ERROR_PREGEL_NO_TARGET_PROVIDED.code;
    err.errorMessage = ERRORS.ERROR_PREGEL_NO_TARGET_PROVIDED.message;
    throw err;
  }
  var toSend = {
    data: data
  };
  if (sendLocation) {
    toSend.sender = this._vertexInfo;
  }
  this._parent._send(target, toSend);
  p.storeWatch("sendTo", t);
};

// End of Vertex Message queue

var Queue = function (executionNumber, vertices, aggregate) {
  this.__vertices = vertices;
  this.__executionNumber = executionNumber;
  this.__collection = pregel.getMsgCollection(executionNumber);
  this.__workCollection = pregel.getWorkCollection(executionNumber);
  this.__step = 0;
  if (aggregate) {
    this.__aggregate = aggregate;
  }
  this.__queues = [];
  vertices.reset();
  var v, id;
  while (vertices.hasNext()) {
    v = vertices.next();
    id = v._id;
    this.__queues.push(id);
    this[id] = new VertexMessageQueue(this, v._getLocationInfo());
  }
  vertices.reset();
  this.__output = {};
};

Queue.prototype._fillQueues = function () {
  var t = p.stopWatch();
  var self = this;
  var t3 = p.stopWatch();
  _.each(this.__queues, function(q) {
    self[q]._clear();
  });
  p.storeWatch("fillQueueFirstEach", t3);
  this.__output = {};
  var t1 = p.stopWatch();
  var cursor = db._query(query, {
    "@collection": this.__workCollection.name(),
    step: this.__step
  });
  p.storeWatch("fillQueueQuery", t1);
  var msg, vQueue, doc, key;
  this.__step++;
  var t2 = p.stopWatch();
  while (cursor.hasNext()) {
    msg = cursor.next();
    doc = JSON.parse(msg.messages);
    for (key in doc) {
      if(doc.hasOwnProperty(key)) {
        if (this.hasOwnProperty(key)) {
          vQueue = this[key];
          vQueue._fill(doc[key]);
        }
      }
    }
  }
  p.storeWatch("fillQueueWhile", t2);
  p.storeWatch("fillQueue", t);
};

//msg has data and optionally sender
Queue.prototype._send = function (target, msg) {
  var t = p.stopWatch();
  var out = this.__output;
  var shard = target.shard;
  var id = target._id;
  out[shard] = out[shard] || {};
  out[shard][id] = out[shard][id] || {};
  var msgContainer = out[shard][id];
  if (msg.hasOwnProperty("sender") || !this.__aggregate) {
    msgContainer.plain = msgContainer.plain || [];
    msgContainer.plain.push(msg);
  } else {
    if (msgContainer.hasOwnProperty("a")) {
      msgContainer.a = this.__aggregate(msg.data, msgContainer.a);
    } else {
      msgContainer.a = msg.data;
    }
  }
  p.storeWatch("_send", t);
};

Queue.prototype._storeInCollection = function() {
  var t = p.stopWatch();
  var self = this;
  _.each(this.__output, function(doc, shard) {
    var toSave = {
      toShard: shard,
      messages: JSON.stringify(doc),
      step: self.__step
    };
    self.__collection.save(toSave);
  });
  p.storeWatch("storeInCol", t);
};

exports.MessageQueue = Queue;