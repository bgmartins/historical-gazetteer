var mapzen = mapzen || {};
mapzen.whosonfirst = mapzen.whosonfirst || {};
mapzen.whosonfirst.config = (function() {
	var self = {

		'init': function(){
			mapzen.whosonfirst.data.endpoint("/~gazetteer/index.wsgi/gazetteer-data/");
			mapzen.whosonfirst.pip.endpoint("/~gazetteer/index.wsgi/pip/");
			mapzen.whosonfirst.iamhere.scenefile("/~gazetteer/index.wsgi/static/tangram/simple.yaml");
			mapzen.whosonfirst.leaflet.tangram.set_api_key("3XqXMjEdT2StnrIRJ4HYbg");
			// general debugging
			// mapzen.whosonfirst.log.show();
		}
	};
	return self
})();
