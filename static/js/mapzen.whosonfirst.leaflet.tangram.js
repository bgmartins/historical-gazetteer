var mapzen = mapzen || {};
mapzen.whosonfirst = mapzen.whosonfirst || {};
mapzen.whosonfirst.leaflet = mapzen.whosonfirst.leaflet || {};

mapzen.whosonfirst.leaflet.tangram = (function(){

	var _scenefile = 'static/tangram/simple.yaml'
	
	var _cache = {};
	
	var _key=""

	var self = {
		'clear_map': function(layers){
			console.log(layers);
			for(const layer of layers){
				self.map('map').removeLayer(layer);
			}
		},
		
		'map_with_bbox': function(id, swlat, swlon, nelat, nelon){

			if ((swlat == nelat) && (swlon == nelon)){
				return self.map_with_latlon(id, swlat, swlon, 14);
			}

			var map = self.map(id);
			map.fitBounds([[swlat, swlon], [ nelat, nelon ]]);

			return map;
		},

		'map_with_latlon': function(id, lat, lon, zoom){

			var map = self.map(id);
			map.setView([ lat , lon ], zoom);

			return map;
		},
		
		'map': function(id){

			if (! _cache[id]){
				var map = L.map(id);
				map.scrollWheelZoom.enable();
				
				var tangram = self.tangram();
				tangram.addTo(map);

				_cache[id] = map;
			}

			return _cache[id];
		},

		'tangram': function(scene){

			var scene = self.scenefile();

			var attributions = self.attributions();
			var attribution = self.render_attributions(attributions);

			var tangram = Tangram.leafletLayer({
				scene: {
					import: _scenefile,
					global: {
						sdk_mapzen_api_key: _key
					}
				},
				numWorkers: 2,
        			unloadInvisibleTiles: false,
				updateWhenIdle: false,
				attribution: attribution,
			});
			
			return tangram;
		},

		'scenefile': function(url){

			if (url){
				_scenefile = url;
			}

			return _scenefile;
		},

		'attributions': function(){

			var attributions = { };

			return attributions;
		},

		'render_attributions': function(attrs){

			var parts = [];

			for (var label in attrs){

				var link = attrs[label];

				var enc_label = mapzen.whosonfirst.php.htmlspecialchars(label);

				if (! link){
					parts.push(enc_label);
					continue;
				}

				var anchor = '<a href="' + link + '" target="_blank">' + enc_label + '</a>';
				parts.push(anchor);
			}

			return parts.join(" | ");
		},

		set_api_key: function(api_key) {
			_key = api_key;
		}
		
	};

	return self;
})();
