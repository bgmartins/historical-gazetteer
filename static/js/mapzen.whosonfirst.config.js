var mapzen = mapzen || {};
mapzen.whosonfirst = mapzen.whosonfirst || {};
mapzen.whosonfirst.config = (function() {
	var self = {

		'init': function(){
			mapzen.whosonfirst.data.endpoint("http://localhost:9999/");
			mapzen.whosonfirst.pip.endpoint("http://localhost:8080/");
			mapzen.whosonfirst.iamhere.scenefile("/~gazetteer/index.wsgi/static/tangram/simple.yaml");
			mapzen.whosonfirst.leaflet.tangram.set_api_key("3XqXMjEdT2StnrIRJ4HYbg");
			// general debugging
			// mapzen.whosonfirst.log.show();
		}
	};
	return self
})();
