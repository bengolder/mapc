var boston = [-71.0571571, 42.3133734];

var detailKeys = d3.map({
    'gas_exp_hhinc': [
		'% Med. Inc. Spent on Gas', 
		function(v){
			return d3.format(".1%")(v);
		},
	],
    'hh10': ['Households', d3.format(",f")],
    'med_hh_inc': ['Med. HH Income', d3.format("$,f")],
    'vmt_hh': ['Driving per HH per day', function(d){ return d3.format(".1f")(d) + ' mi.';}]
});


var colorScale = d3.scale.threshold()
    .domain(percents)
    .range(rd2grn);

// make a basic map
var map = L.mapbox.map('map', 'bengolder.map-dxbn3ewa')
    .setView([42.3133734, -71.05715710], 13);



var svg = d3.select(map.getPanes().overlayPane).append("svg");
var g = svg.append("g").attr("class", "leaflet-zoom-hide");

var overlay = d3.select("body").insert("div", ":first-child")
    .attr("class", "overlay")
    .style("display", "none");
    // the overlay should show:
    //   number of households
    //   vmt
    //   %
    //   median hh inc

var keys = detailKeys.entries();

var histDivs = d3.select("#sidebar").selectAll('.histogram-block')
	.data(keys).enter().append('div')
	.attr('id', function(d, i){
		return 'hist_'+d.key;
	})
	.attr('class', 'histogram-block');

var histTitles = histDivs.append('p')
	.attr('class', 'histogram-title')
	.text(function(d){
		return d.value[0];
	});

var histW = 225,
	histH = 50;

var histograms = histDivs.append('svg')
	.attr('width', histW)
	.attr('height', histH + 30)
	.attr('class', 'histogram');

var bargroups = histograms.append('g')
	.attr('class', 'bars')
	.attr('transform', 'translate(15,0)');


function moveOverlay(d){
    var coords = d3.mouse(document.body);
    overlay.style("left", coords[0] + 40 + "px")
        .style("top", coords[1] - 40 + "px");
};

function removeBlockGroupDetails(d){
    overlay.selectAll(".details").remove();
    overlay.style("display", "none");
	d3.selectAll('.histbar').classed('highlighted', false);
}

d3.json('blk_grp_topo.json', function (data) {

    var collection = topojson.feature( data, data.objects.blk_groups);

    var transform = d3.geo.transform({point: projectPoint});
    var path = d3.geo.path().projection(transform);
    var feature = g.selectAll("path")
        .data(collection.features)
        .enter().append("path")
        .style("fill", function(d){
            return colorScale(d.properties.gas_exp_hhinc);
        })
        .on("mouseenter", function(d){
            var shape = d3.select(this);
            shape.style("stroke-width", 2);
            renderBlockGroupDetails(d.properties);
            shape.on("mousemove", moveOverlay);
        }).on("mouseleave", function(d){
            var shape = d3.select(this);
            shape.style("stroke-width", 0.25);
            shape.on("mousemove", null);
            removeBlockGroupDetails();
        });
    
    map.on("viewreset", reset);
    reset();

	var bins = 20;

	var bars = bargroups.selectAll('rect')
		.data(histLayout).enter().append('rect')
		.attr('x', function(d, i){
			return ( (histW - 10) / bins) * i;
		}).attr('y', function(d, i){
			return histH - barHeight(d);
		}).attr('width', ((histW - 10) / bins) - 1)
		.attr('height', barHeight)
		.attr('class', 'histbar');

	var axes = histograms.append('g')
		.attr('class', 'hist-axis')
		.attr('transform', 'translate(15,'+ (histH + 10) + ')');

	detailKeys.forEach(function(key, keyData){
		makeAxis(key, keyData)
	});
	

	function barHeight(d){
		return (d.y / d.max) * ( histH ) + 3;
	}

	function makeAxis(key, data){
		console.log("domain", data.getBin.domain());
		var xScale = d3.scale.threshold()
			.domain(data.getBin.domain())
			.range(data.getBin.range().map(function(i){
				return i * ( (histW - 10) / bins);
			}));
		var axis = d3.svg.axis()
			.scale(xScale)
			.tickValues(data.getBin.domain().filter(function(v, i){
				return i % 5 == 0;
			})).tickFormat(data[1]);
		var g = d3.selectAll('#hist_'+key + ' .hist-axis');
		console.log("g", g);
		g.call(axis);
	}

	function histLayout(k){
		// get all values
		// determine thresholds
		// make histogram

		var layout = d3.layout.histogram()
			.value(function(d, i){
				return d.properties[k.key];
			}).bins(bins);

		var matrix = layout(collection.features);

		var max = d3.max( matrix, function(x){return x.y;});

		matrix.forEach(function(n){
			n.max = max;
		});
		var thresholds = matrix.map(function(n){ return n.x; });
		var binIndices = matrix.map(function(n, i){ return i; });
		thresholds.shift();

		var keyData = detailKeys.get(k.key);
		keyData.matrix = matrix;
		var binScale = d3.scale.threshold()
			.domain(thresholds)
			.range(binIndices);

		keyData.getBin = binScale;

		return matrix;
	}

    function reset(){
        var bounds = path.bounds(collection),
            topLeft = bounds[0],
            bottomRight = bounds[1];

        svg.attr("width", bottomRight[0] - topLeft[0])
           .attr("height", bottomRight[1] - topLeft[1])
           .style("left", topLeft[0] + "px")
           .style("top", topLeft[1] + "px");

        g.attr("transform", "translate(" + -topLeft[0] + "," + -topLeft[1] + ")");

        feature.attr("d", path);
    }

    function projectPoint(x, y){
        var point = map.latLngToLayerPoint(new L.LatLng(y, x));
        this.stream.point(point.x, point.y);
    }

	function renderBlockGroupDetails(d){
		overlay.style("display", "block");

		var details = overlay.selectAll("div")
			.data([d], function(d){return d.geoid10;}).enter()
			.append("div").attr("class", "details");

		detailKeys.forEach(function (key, keyData){
			var row = details.append("div").attr("class", "data-row");
			row.append("div").attr("class", "label")
				.text(keyData[0]);
			row.append("div").attr("class", "data")
				.text(keyData[1](d[key]));

		    // highlight the correct bin in the corresponding histogram
			var bin = keyData.getBin(d[key]);
			var selector = '#hist_'+key+' .histbar';
			var bars = d3.selectAll(selector);
			bars.classed('highlighted', function(h, i){
					return i == bin;
				});
		});
	}

});
