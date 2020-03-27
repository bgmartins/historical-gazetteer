var mapzen = mapzen || {};
mapzen.whosonfirst = mapzen.whosonfirst || {};
mapzen.whosonfirst.config = (function() {
	var self = {

		'init': function(){
			mapzen.whosonfirst.data.endpoint("/gazetteer-data");
			mapzen.whosonfirst.pip.endpoint("/pip");
			mapzen.whosonfirst.iamhere.scenefile("static/tangram/simple.yaml");
			//mapzen.whosonfirst.leaflet.tangram.set_api_key("49a5b5dc29214864871852883a050425");
			// general debugging
			mapzen.whosonfirst.log.show();
		}
	};
	return self
})();
