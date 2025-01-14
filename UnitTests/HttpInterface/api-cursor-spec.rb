# coding: utf-8

require 'rspec'
require 'arangodb.rb'

describe ArangoDB do
  api = "/_api/cursor"
  prefix = "api-cursor"

  context "dealing with cursors:" do
    before do
      @reId = Regexp.new('^\d+$')
    end

################################################################################
## error handling
################################################################################

    context "error handling:" do
      it "returns an error if body is missing" do
        cmd = api
        doc = ArangoDB.log_post("#{prefix}-missing-body", cmd)
        
        doc.code.should eq(400)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['code'].should eq(400)
        doc.parsed_response['errorNum'].should eq(600)
      end

      it "returns an error if collection is unknown" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN unknowncollection LIMIT 2 RETURN u.n\", \"count\" : true, \"bindVars\" : {}, \"batchSize\" : 2 }"
        doc = ArangoDB.log_post("#{prefix}-unknown-collection", cmd, :body => body)
        
        doc.code.should eq(404)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['code'].should eq(404)
        doc.parsed_response['errorNum'].should eq(1203)
      end

      it "returns an error if cursor identifier is missing" do
        cmd = api
        doc = ArangoDB.log_put("#{prefix}-missing-cursor-identifier", cmd)
        
        doc.code.should eq(400)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['code'].should eq(400)
        doc.parsed_response['errorNum'].should eq(400)
      end

      it "returns an error if cursor identifier is invalid" do
        cmd = api + "/123456"
        doc = ArangoDB.log_put("#{prefix}-invalid-cursor-identifier", cmd)
        
        doc.code.should eq(404)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['code'].should eq(404)
        doc.parsed_response['errorNum'].should eq(1600)
      end

    end

################################################################################
## create and using cursors
################################################################################

    context "handling a cursor:" do
      before do
        @cn = "users"
        ArangoDB.drop_collection(@cn)
        @cid = ArangoDB.create_collection(@cn, false)

        (0...10).each{|i|
          ArangoDB.post("/_api/document?collection=#{@cid}", :body => "{ \"n\" : #{i} }")
        }
      end

      after do
        ArangoDB.drop_collection(@cn)
      end

      it "creates a cursor single run" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} LIMIT 2 RETURN u.n\", \"count\" : true, \"bindVars\" : {}, \"batchSize\" : 2 }"
        doc = ArangoDB.log_post("#{prefix}-create-for-limit-return-single", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        doc.parsed_response['hasMore'].should eq(false)
        doc.parsed_response['count'].should eq(2)
        doc.parsed_response['result'].length.should eq(2)
        doc.parsed_response['cached'].should eq(false)
      end
      
      it "creates a cursor single run, without count" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} LIMIT 2 RETURN u.n\", \"count\" : false, \"bindVars\" : {} }"
        doc = ArangoDB.log_post("#{prefix}-create-for-limit-return-single", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        doc.parsed_response['hasMore'].should eq(false)
        doc.parsed_response['count'].should eq(nil)
        doc.parsed_response['result'].length.should eq(2)
        doc.parsed_response['cached'].should eq(false)
      end

      it "creates a cursor single run, large batch size" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} LIMIT 2 RETURN u.n\", \"count\" : true, \"batchSize\" : 5 }"
        doc = ArangoDB.log_post("#{prefix}-create-for-limit-return-single-larger", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        doc.parsed_response['hasMore'].should eq(false)
        doc.parsed_response['count'].should eq(2)
        doc.parsed_response['result'].length.should eq(2)
        doc.parsed_response['cached'].should eq(false)
      end

      it "creates a cursor" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} LIMIT 5 RETURN u.n\", \"count\" : true, \"batchSize\" : 2 }"
        doc = ArangoDB.log_post("#{prefix}-create-for-limit-return", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(2)
        doc.parsed_response['cached'].should eq(false)

        id = doc.parsed_response['id']

        cmd = api + "/#{id}"
        doc = ArangoDB.log_put("#{prefix}-create-for-limit-return-cont", cmd)
        
        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(200)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        doc.parsed_response['id'].should eq(id)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(2)
        doc.parsed_response['cached'].should eq(false)

        cmd = api + "/#{id}"
        doc = ArangoDB.log_put("#{prefix}-create-for-limit-return-cont2", cmd)
        
        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(200)
        doc.parsed_response['id'].should be_nil
        doc.parsed_response['hasMore'].should eq(false)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(1)
        doc.parsed_response['cached'].should eq(false)

        cmd = api + "/#{id}"
        doc = ArangoDB.log_put("#{prefix}-create-for-limit-return-cont3", cmd)
        
        doc.code.should eq(404)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['errorNum'].should eq(1600)
        doc.parsed_response['code'].should eq(404)
      end

      it "creates a cursor and deletes it in the middle" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} LIMIT 5 RETURN u.n\", \"count\" : true, \"batchSize\" : 2 }"
        doc = ArangoDB.log_post("#{prefix}-create-for-limit-return", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(2)
        doc.parsed_response['cached'].should eq(false)

        id = doc.parsed_response['id']

        cmd = api + "/#{id}"
        doc = ArangoDB.log_put("#{prefix}-create-for-limit-return-cont", cmd)
        
        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(200)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        doc.parsed_response['id'].should eq(id)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(2)
        doc.parsed_response['cached'].should eq(false)

        cmd = api + "/#{id}"
        doc = ArangoDB.log_delete("#{prefix}-delete", cmd)

        doc.code.should eq(202)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(202)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
      end

      it "deleting a cursor" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} LIMIT 5 RETURN u.n\", \"count\" : true, \"batchSize\" : 2 }"
        doc = ArangoDB.post(cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(2)
        doc.parsed_response['cached'].should eq(false)

        id = doc.parsed_response['id']

        cmd = api + "/#{id}"
        doc = ArangoDB.log_delete("#{prefix}-delete", cmd)

        doc.code.should eq(202)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(202)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
      end

      it "deleting a deleted cursor" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} LIMIT 5 RETURN u.n\", \"count\" : true, \"batchSize\" : 2 }"
        doc = ArangoDB.post(cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(2)
        doc.parsed_response['cached'].should eq(false)

        id = doc.parsed_response['id']

        cmd = api + "/#{id}"
        doc = ArangoDB.log_delete("#{prefix}-delete", cmd)

        doc.code.should eq(202)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(202)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        
        doc = ArangoDB.log_delete("#{prefix}-delete", cmd)

        doc.code.should eq(404)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['errorNum'].should eq(1600);
        doc.parsed_response['code'].should eq(404)
        doc.parsed_response['id'].should be_nil
      end

      it "deleting an invalid cursor" do
        cmd = api
        cmd = api + "/999999" # we assume this cursor id is invalid
        doc = ArangoDB.log_delete("#{prefix}-delete", cmd)

        doc.code.should eq(404)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(true);
        doc.parsed_response['errorNum'].should eq(1600);
        doc.parsed_response['code'].should eq(404)
        doc.parsed_response['id'].should be_nil
      end

      it "creates a cursor that will expire" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} LIMIT 5 RETURN u.n\", \"count\" : true, \"batchSize\" : 1, \"ttl\" : 4 }"
        doc = ArangoDB.log_post("#{prefix}-create-ttl", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(1)
        doc.parsed_response['cached'].should eq(false)

        sleep 1
        id = doc.parsed_response['id']

        cmd = api + "/#{id}"
        doc = ArangoDB.log_put("#{prefix}-create-ttl", cmd)
        
        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(200)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        doc.parsed_response['id'].should eq(id)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(1)
        doc.parsed_response['cached'].should eq(false)

        sleep 1

        doc = ArangoDB.log_put("#{prefix}-create-ttl", cmd)
        
        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(200)
        doc.parsed_response['id'].should eq(id)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(1)
        doc.parsed_response['cached'].should eq(false)

        # after this, the cursor might expire eventually
        # the problem is that we cannot exactly determine the point in time
        # when it really vanishes, as this depends on thread scheduling, state     
        # of the cleanup thread etc.

        # sleep 10 # this should delete the cursor on the server
        # doc = ArangoDB.log_put("#{prefix}-create-ttl", cmd)
        # doc.code.should eq(404)
        # doc.headers['content-type'].should eq("application/json; charset=utf-8")
        # doc.parsed_response['error'].should eq(true)
        # doc.parsed_response['errorNum'].should eq(1600)
        # doc.parsed_response['code'].should eq(404)
      end
      
      it "creates a cursor that will not expire" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} LIMIT 5 RETURN u.n\", \"count\" : true, \"batchSize\" : 1, \"ttl\" : 60 }"
        doc = ArangoDB.log_post("#{prefix}-create-ttl", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(1)
        doc.parsed_response['cached'].should eq(false)

        sleep 1
        id = doc.parsed_response['id']

        cmd = api + "/#{id}"
        doc = ArangoDB.log_put("#{prefix}-create-ttl", cmd)
        
        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(200)
        doc.parsed_response['id'].should be_kind_of(String)
        doc.parsed_response['id'].should match(@reId)
        doc.parsed_response['id'].should eq(id)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(1)
        doc.parsed_response['cached'].should eq(false)

        sleep 1

        doc = ArangoDB.log_put("#{prefix}-create-ttl", cmd)
        
        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(200)
        doc.parsed_response['id'].should eq(id)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(1)
        doc.parsed_response['cached'].should eq(false)

        sleep 5 # this should not delete the cursor on the server
        doc = ArangoDB.log_put("#{prefix}-create-ttl", cmd)
        
        doc.code.should eq(200)
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(200)
        doc.parsed_response['id'].should eq(id)
        doc.parsed_response['hasMore'].should eq(true)
        doc.parsed_response['count'].should eq(5)
        doc.parsed_response['result'].length.should eq(1)
        doc.parsed_response['cached'].should eq(false)
      end

      it "creates a query that executes a v8 expression during query optimization" do
        cmd = api
        body = "{ \"query\" : \"RETURN CONCAT('foo', 'bar', 'baz')\" }"
        doc = ArangoDB.log_post("#{prefix}-create-v8", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        doc.parsed_response['hasMore'].should eq(false)
        doc.parsed_response['result'].length.should eq(1)
        doc.parsed_response['cached'].should eq(false)
      end

      it "creates a query that executes a v8 expression during query execution" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} RETURN PASSTHRU(KEEP(u, '_key'))\" }"
        doc = ArangoDB.log_post("#{prefix}-create-v8", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        doc.parsed_response['hasMore'].should eq(false)
        doc.parsed_response['result'].length.should eq(10)
        doc.parsed_response['cached'].should eq(false)
      end
      
      it "creates a query that executes a dynamic index expression during query execution" do
        cmd = api
        body = "{ \"query\" : \"FOR i IN #{@cn} FOR j IN #{@cn} FILTER i._key == j._key RETURN i._key\" }"
        doc = ArangoDB.log_post("#{prefix}-index-expression", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        doc.parsed_response['hasMore'].should eq(false)
        doc.parsed_response['result'].length.should eq(10)
        doc.parsed_response['cached'].should eq(false)
      end
      
      it "creates a query that executes a dynamic V8 index expression during query execution" do
        cmd = api
        body = "{ \"query\" : \"FOR i IN #{@cn} FOR j IN #{@cn} FILTER j._key == PASSTHRU(i._key) RETURN i._key\" }"
        doc = ArangoDB.log_post("#{prefix}-v8-index-expression", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        doc.parsed_response['hasMore'].should eq(false)
        doc.parsed_response['result'].length.should eq(10)
        doc.parsed_response['cached'].should eq(false)
      end

      it "creates a cursor with different bind values" do
        cmd = api
        body = "{ \"query\" : \"RETURN @values\", \"bindVars\" : { \"values\" : [ null, false, true, -1, 2.5, 3e4, \"\", \" \", \"true\", \"foo bar baz\", [ 1, 2, 3, \"bar\" ], { \"foo\" : \"bar\", \"\" : \"baz\", \" bar-baz \" : \"foo-bar\" } ] } }"
        doc = ArangoDB.log_post("#{prefix}-test-bind-values", cmd, :body => body)
        
        values = [ [ nil, false, true, -1, 2.5, 3e4, "", " ", "true", "foo bar baz", [ 1, 2, 3, "bar" ], { "foo" => "bar", "" => "baz", " bar-baz " => "foo-bar" } ] ]
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        doc.parsed_response['hasMore'].should eq(false)
        doc.parsed_response['result'].should eq(values)
        doc.parsed_response['cached'].should eq(false)
      end

    end

################################################################################
## checking a query
################################################################################

    context "checking a query:" do
      before do
        @cn = "users"
        ArangoDB.drop_collection(@cn)
        @cid = ArangoDB.create_collection(@cn, false)
      end

      after do
        ArangoDB.drop_collection(@cn)
      end

      it "valid query" do
        cmd = "/_api/query"
        body = "{ \"query\" : \"FOR u IN #{@cn} FILTER u.name == @name LIMIT 2 RETURN u.n\" }"
        doc = ArangoDB.log_post("api-query-valid", cmd, :body => body)
        
        doc.code.should eq(200)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(200)
        doc.parsed_response['bindVars'].should eq(["name"])
      end

      it "invalid query" do
        cmd = "/_api/query"
        body = "{ \"query\" : \"FOR u IN #{@cn} FILTER u.name = @name LIMIT 2 RETURN u.n\" }"
        doc = ArangoDB.log_post("api-query-invalid", cmd, :body => body)
        
        doc.code.should eq(400)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(true)
        doc.parsed_response['code'].should eq(400)
        doc.parsed_response['errorNum'].should eq(1501)
      end
      
    end

################################################################################
## floating point values
################################################################################

    context "fetching floating-point values:" do
      before do
        @cn = "users"
        ArangoDB.drop_collection(@cn)
        @cid = ArangoDB.create_collection(@cn, false)

        ArangoDB.post("/_api/document?collection=#{@cid}", :body => "{ \"_key\" : \"big\", \"value\" : 4e+262 }")
        ArangoDB.post("/_api/document?collection=#{@cid}", :body => "{ \"_key\" : \"neg\", \"value\" : -4e262 }")
        ArangoDB.post("/_api/document?collection=#{@cid}", :body => "{ \"_key\" : \"pos\", \"value\" : 4e262 }")
        ArangoDB.post("/_api/document?collection=#{@cid}", :body => "{ \"_key\" : \"small\", \"value\" : 4e-262 }")
      end

      after do
        ArangoDB.drop_collection(@cn)
      end

      it "fetching via cursor" do
        cmd = api
        body = "{ \"query\" : \"FOR u IN #{@cn} SORT u._key RETURN u.value\" }"
        doc = ArangoDB.log_post("#{prefix}-float", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        result = doc.parsed_response['result']
        result.length.should eq(4)
        result[0].should eq(4e262);
        result[1].should eq(-4e262);
        result[2].should eq(4e262);
        result[3].should eq(4e-262);
        
        doc = ArangoDB.get("/_api/document/#{@cid}/big")
        doc.parsed_response['value'].should eq(4e262)
        
        doc = ArangoDB.get("/_api/document/#{@cid}/neg")
        doc.parsed_response['value'].should eq(-4e262)

        doc = ArangoDB.get("/_api/document/#{@cid}/pos")
        doc.parsed_response['value'].should eq(4e262)

        doc = ArangoDB.get("/_api/document/#{@cid}/small")
        doc.parsed_response['value'].should eq(4e-262)
      end
    end

################################################################################
## query cache
################################################################################

    context "testing the query cache:" do
      before do
        doc = ArangoDB.get("/_api/query-cache/properties")
        @mode = doc.parsed_response['mode']
        ArangoDB.put("/_api/query-cache/properties", :body => "{ \"mode\" : \"demand\" }")

        ArangoDB.delete("/_api/query-cache")
      end

      after do
        ArangoDB.put("/_api/query-cache/properties", :body => "{ \"mode\" : \"#{@mode}\" }")
      end

      it "testing without cache attribute set" do
        cmd = api
        body = "{ \"query\" : \"FOR i IN 1..5 RETURN i\" }"
        doc = ArangoDB.log_post("#{prefix}-query-cache-disabled", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        result = doc.parsed_response['result']
        result.should eq([ 1, 2, 3, 4, 5 ])
        doc.parsed_response['cached'].should eq(false)
        doc.parsed_response['extra'].should have_key('stats')

        # should see same result, but not from cache
        doc = ArangoDB.log_post("#{prefix}-query-cache", cmd, :body => body)
        doc.code.should eq(201)
        result = doc.parsed_response['result']
        result.should eq([ 1, 2, 3, 4, 5 ])
        doc.parsed_response['cached'].should eq(false)
        doc.parsed_response['extra'].should have_key('stats')
      end

      it "testing explicitly disable cache" do
        cmd = api
        body = "{ \"query\" : \"FOR i IN 1..5 RETURN i\", \"cache\" : false }"
        doc = ArangoDB.log_post("#{prefix}-query-cache-disabled", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        result = doc.parsed_response['result']
        result.should eq([ 1, 2, 3, 4, 5 ])
        doc.parsed_response['cached'].should eq(false)
        doc.parsed_response['extra'].should have_key('stats')

        # should see same result, but not from cache
        doc = ArangoDB.log_post("#{prefix}-query-cache", cmd, :body => body)
        doc.code.should eq(201)
        result = doc.parsed_response['result']
        result.should eq([ 1, 2, 3, 4, 5 ])
        doc.parsed_response['cached'].should eq(false)
        doc.parsed_response['extra'].should have_key('stats')
      end

      it "testing enabled cache" do
        cmd = api
        body = "{ \"query\" : \"FOR i IN 1..5 RETURN i\", \"cache\" : true }"
        doc = ArangoDB.log_post("#{prefix}-query-cache-enabled", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        result = doc.parsed_response['result']
        result.should eq([ 1, 2, 3, 4, 5 ])
        doc.parsed_response['cached'].should eq(false)
        doc.parsed_response['extra'].should have_key('stats')

        # should see same result, but now from cache
        doc = ArangoDB.log_post("#{prefix}-query-cache", cmd, :body => body)
        doc.code.should eq(201)
        result = doc.parsed_response['result']
        result.should eq([ 1, 2, 3, 4, 5 ])
        doc.parsed_response['cached'].should eq(true)
        doc.parsed_response['extra'].should_not have_key('stats')
      end

      it "testing clearing the cache" do
        cmd = api
        body = "{ \"query\" : \"FOR i IN 1..5 RETURN i\", \"cache\" : true }"
        doc = ArangoDB.log_post("#{prefix}-query-cache-enabled", cmd, :body => body)
        
        doc.code.should eq(201)
        doc.headers['content-type'].should eq("application/json; charset=utf-8")
        doc.parsed_response['error'].should eq(false)
        doc.parsed_response['code'].should eq(201)
        doc.parsed_response['id'].should be_nil
        result = doc.parsed_response['result']
        result.should eq([ 1, 2, 3, 4, 5 ])
        doc.parsed_response['cached'].should eq(false)
        doc.parsed_response['extra'].should have_key('stats')

        # should see same result, but now from cache
        doc = ArangoDB.log_post("#{prefix}-query-cache", cmd, :body => body)
        doc.code.should eq(201)
        result = doc.parsed_response['result']
        result.should eq([ 1, 2, 3, 4, 5 ])
        doc.parsed_response['cached'].should eq(true)
        doc.parsed_response['extra'].should_not have_key('stats')

        # now clear cache
        ArangoDB.delete("/_api/query-cache")

        # query again. now response should not come from cache
        doc = ArangoDB.log_post("#{prefix}-query-cache", cmd, :body => body)
        doc.code.should eq(201)
        result = doc.parsed_response['result']
        result.should eq([ 1, 2, 3, 4, 5 ])
        doc.parsed_response['cached'].should eq(false)
        doc.parsed_response['extra'].should have_key('stats')

        doc = ArangoDB.log_post("#{prefix}-query-cache", cmd, :body => body)
        doc.code.should eq(201)
        result = doc.parsed_response['result']
        result.should eq([ 1, 2, 3, 4, 5 ])
        doc.parsed_response['cached'].should eq(true)
        doc.parsed_response['extra'].should_not have_key('stats')
      end

    end

  end
end
