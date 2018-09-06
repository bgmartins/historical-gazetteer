var mapzen = mapzen || {};
mapzen.whosonfirst = mapzen.whosonfirst || {};

mapzen.whosonfirst.config = (function(){

	var self = {

		'init': function(){

			mapzen.whosonfirst.data.endpoint("http://localhost:9999/");
			mapzen.whosonfirst.pip.endpoint("http://localhost:8080/");

			mapzen.whosonfirst.iamhere.scenefile("/index.wsgi/static/tangram/refill.yaml");

			// filtering by more than one but not all placetypes indexed
			// in the pip server is best thought of as broken for the time
			// being - it can be done but because the it needs to be done
			// using multiple requests the synchronization of the results
			// and the various bits of UI/UX interaction are easily...
			// confused. the correct place to fix this is in the go-wof-pip
			// server itself and there is an open ticket.
			// https://github.com/whosonfirst/go-whosonfirst-pip/issues/22			
			// filtering by a single ticket works just fine though...
			// (20160217/thisisaaronland)
			// mapzen.whosonfirst.iamhere.placetypes(["neighbourhood"]);
			
			// https://mapzen.com/projects/pelias/
			// mapzen.whosonfirst.pelias.endpoint("");
			// mapzen.whosonfirst.pelias.apikey("");

			// Mapzen vector tiles require an API key
			mapzen.whosonfirst.leaflet.tangram.set_api_key("ckD92axlTP6zj4BK6rhhhA");
			
			// general debugging
			// mapzen.whosonfirst.log.show();
		}
	};

	return self

})();