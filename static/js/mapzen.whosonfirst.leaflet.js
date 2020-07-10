var mapzen = mapzen || {};
mapzen.whosonfirst = mapzen.whosonfirst || {};

mapzen.whosonfirst.leaflet = (function(map){
	var self = {		
		'draw_point': function(map, geojson, style, handler){
			var center = geojson['geometry']['coordinates'];
			var icon = L.circleMarker(center, handler);
			var layer = L.geoJson(geojson, {
				//'style': style,
				'pointToLayer': function () {
					return icon;
					}
			});
			layer.bindPopup(geojson['properties']['popupContent'],{closeButton: false});
			/*layer.on('mouseover', function() { 
				this.setStyle({'fillColor': '#f21b0d'});
				layer.openPopup(); 
			});
			layer.on('mouseout', function () {
				this.setStyle({'fillColor': '#2424da'});
			});*/
			layer.addTo(map);
			return layer;
		},
		
		'draw_poly': function(map, geojson, style){
			var layer = L.geoJson(geojson, {
				'style': style				
			});
			
			// https://github.com/Leaflet/Leaflet.label
			
			try {
				var props = geojson['properties'];
				var label = props['lflt:label_text'];

				if (label){
					layer.bindLabel(label, {noHide: true });
				}
			}
			
			catch (e){
				mapzen.whosonfirst.log.error("failed to bind label because " + e);
			}
			layer.bindPopup(geojson['properties']['popupContent'],{closeButton: false});
			/*layer.on('mouseover', function() { 
				this.setStyle({'fillColor': '#f21b0d'});
				layer.openPopup(); 
			});
			layer.on('mouseout', function () {
				this.setStyle({'fillColor': '#2424da'});
			});*/
			layer.addTo(map);
			return layer;
		},
		
		'draw_bbox': function(map, geojson, style){

			var bbox = mapzen.whosonfirst.geojson.derive_bbox(geojson);
			
			if (! bbox){
				mapzen.whosonfirst.log.error("no bounding box to draw");
				return false;
			}

			var bbox = geojson['bbox'];
			var swlat = bbox[1];
			var swlon = bbox[0];
			var nelat = bbox[3];
			var nelon = bbox[2];

			var geom = {
				'type': 'Polygon',
				'coordinates': [[
					[swlon, swlat],
					[swlon, nelat],
					[nelon, nelat],
					[nelon, swlat],
					[swlon, swlat],
				]]
			};

			var bbox_geojson = {
				'type': 'Feature',
				'geometry': geom
			}

			return self.draw_poly(map, bbox_geojson, style);
		},

		'fit_map': function(map, geojson, force){
			
			var bbox = mapzen.whosonfirst.geojson.derive_bbox(geojson);

			if (! bbox){
				mapzen.whosonfirst.log.error("no bounding box to fit");
				return false;
			}
			
			if ((bbox[1] == bbox[3]) && (bbox[2] == bbox[4])){
				map.setView([bbox[1], bbox[0]], 14);
				return;
			}
			
			var sw = [bbox[1], bbox[0]];
			var ne = [bbox[3], bbox[2]];
			
			var bounds = new L.LatLngBounds([sw, ne]);
			var current = map.getBounds();

			var redraw = true;

			if (! force){

				var redraw = false;
				
				if (bounds.getSouth() <= current.getSouth().toFixed(6)){
					redraw = true;
				}
				
				else if (bounds.getWest() <= current.getWest().toFixed(6)){
					redraw = true;
				}
				
				else if (bounds.getNorth() >= current.getNorth().toFixed(6)){
					redraw = true;
				}
				
				else if (bounds.getEast() >= current.getEast().toFixed(6)){
					redraw = true;
				}
				
				else {}
			}
			
			if (redraw){
				map.fitBounds(bounds);
			}
		}
	};
	
	return self;
})();
