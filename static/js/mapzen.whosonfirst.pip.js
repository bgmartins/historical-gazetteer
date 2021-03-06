var mapzen = mapzen || {};
mapzen.whosonfirst = mapzen.whosonfirst || {};

mapzen.whosonfirst.pip = (function(){

		var _endpoint = '/pip/';

		var self = {

			'get_by_latlon': function(id_string, placetype, on_success, on_error){
				var q = { 'id_string': id_string};

				q['v1'] = 1;	// PLEASE MAKE THIS A FLAG OR BETTER YET UPDATE THE CODE TO HANDLE SPR RESPONSES

				if (placetype){
					q['placetype'] = placetype;
				}

				q = mapzen.whosonfirst.net.encode_query(q);

				mapzen.whosonfirst.log.info("pip " + q);
				var req = self.endpoint() + "?" + q;
				
				mapzen.whosonfirst.net.fetch(req, on_success, on_error);
			},
			
			'endpoint': function(e){

				if (e){
					_endpoint = e;
				}

				return _endpoint;
			}
		};

		return self;
	})();
