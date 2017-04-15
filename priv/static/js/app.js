// for phoenix_html support, including form and button helpers
// copy the following scripts into your javascript bundle:
// * https://raw.githubusercontent.com/phoenixframework/phoenix_html/v2.3.0/priv/static/phoenix_html.js



// image clipboard mark 
function image_cp_toggle(i) {
		var is_checked = $("#image_cp_" + i).hasClass("fa-check") ;
		var to_remove, to_add;
		if (is_checked) {
				to_remove = "fa-check";
				to_add    = "fa-shopping-cart";
		} else {
				to_remove = "fa-shopping-cart";
				to_add    = "fa-check";
		}
		$.ajax("/image/mark/" + (is_checked ? "rm" : "add") + "/" + i);
		$("#clipboard-count").html( (is_checked ? -1 : 1) + parseInt($("#clipboard-count").html()));
		$("#image_cp_" + i).addClass(to_add);
		$("#image_cp_" + i).removeClass(to_remove);
}

function image_cp_remove(i) {
		$.ajax("/image/mark/rm/" + i);
		$("#image_cp_" + i).closest(".card").remove();
}


// canvas + image stuff
function draw_mark(ctx, w,h,marks, color) {
		if (!marks || !marks.x || marks.x.length == 0) { return; }
		ctx.strokeStyle = color;
		ctx.lineWidth   = 2;
		ctx.lineJoin    = 'round';
		ctx.beginPath();
		ctx.moveTo(marks.x[0] * w, marks.y[0] * h);
		for (var i = 1; i< marks.x.length; i++) {
				ctx.lineTo(marks.x[i] * w, marks.y[i]* h);
		}
		ctx.stroke();
}

function attach_canvas(container_id,marks,color) {
		var img = $("#" + container_id + " > img");
		var w = img[0].clientWidth;
		var h = img[0].clientHeight;
		
		var canvas = $("#" + container_id + " > canvas");
		if (canvas.length==0) {
				canvas = $('<canvas/>',{id: container_id + '_cv'}).prop({width: w,height: h});
				$("#" + container_id).append(canvas);
		}
		var ctx = canvas[0].getContext('2d'); // [0] because canvas is a jquery object
		draw_mark(ctx,w,h,marks, color);
}

imagetag_colors=["#ff0000", "#00ff00", "#0000ff", "#ffff00", "#00ffff"];

// the following functions act on the global variables imagetag_mark and imagetag_ctx imagetag_canvas
imagetag_isdrawing=false;
function imagetag_canvas_event(event) {
		var drawer = {
				touchstart: function (coors) {
						imagetag_ctx.clearRect(0, 0, imagetag_canvas.width, imagetag_canvas.height);
						imagetag_marks={x:[], y:[]};
						imagetag_ctx.beginPath();
						imagetag_ctx.moveTo(coors.x, coors.y);
						imagetag_isdrawing = true;
				},
				touchmove: function (coors) {
						if (imagetag_isdrawing) {
								imagetag_ctx.lineTo(coors.x, coors.y);
								imagetag_ctx.stroke();
								imagetag_marks.x.push(coors.x/imagetag_maxx);
								imagetag_marks.y.push(coors.y/imagetag_maxy);
						}
				},
				touchend: function (coors) {
						if (imagetag_isdrawing) {
								this.touchmove(coors);
								imagetag_isdrawing = false;
								$('#imagetag_marks').val(JSON.stringify(imagetag_marks));
						}
				}
		};
		
		
		// map mouse events to touch events
    switch(event.type){
    case "mousedown":
        event.touches = [];
        event.touches[0] = { 
            pageX: event.pageX,
            pageY: event.pageY
        };
        type = "touchstart";                  
        break;
    case "mousemove":                
        event.touches = [];
        event.touches[0] = { 
            pageX: event.pageX,
            pageY: event.pageY
        };
        type = "touchmove";                
        break;
    case "mouseup":              
        event.touches = [];
        event.touches[0] = { 
            pageX: event.pageX,
            pageY: event.pageY
        };
        type = "touchend";
        break;
    }    
    
    // touchend clear the touches[0], so we need to use changedTouches[0]
    var coors;
    if(event.type === "touchend") {
        coors = {
            x: event.changedTouches[0].pageX,
            y: event.changedTouches[0].pageY
        };
    }
    else {
        // get the touch coordinates
        coors = {
            x: event.touches[0].pageX,
            y: event.touches[0].pageY
        };
    }
    type = type || event.type;
		coors.x = coors.x - $(event.target).offset().left;
		coors.y = coors.y - $(event.target).offset().top;
		drawer[type](coors);
}

function imagetag_init_draw(container_id) {
		var img = $("#" + container_id + " > img");
		imagetag_maxx = img[0].clientWidth;
		imagetag_maxy = img[0].clientHeight;
		imagetag_marks={x:[], y:[]};
		imagetag_canvas = ($("#" + container_id + " > canvas"))[0];
	  imagetag_ctx = imagetag_canvas.getContext('2d');
		imagetag_ctx.clearRect(0, 0, imagetag_canvas.width, imagetag_canvas.height);
		// attach the touchstart, touchmove, touchend event listeners.
		var events = ('createTouch' in document) || ('ontouchstart' in window) ?
				['touchstart', 'touchmove', 'touchend'] :
				['mousedown', 'mousemove', 'mouseup'];
		events.forEach(function(e) {
				imagetag_canvas.removeEventListener(e, imagetag_canvas_event, false); // in case already there
				imagetag_canvas.addEventListener(e, imagetag_canvas_event, false);
		});
}

function mainsearch() {
		var s = $("#searchbox").val();
		if (s.length < 2) {
				$("#searchresult").hide();
				$("#maincontent").show();
		} else {
				// after 100ms show a spinner
				var showWaiting=window.setTimeout(function() {
						$("#searchresult").html('<center><i class="fa fa-spinner fa-spin" style="font-size:150px"></i></center>')},
																					100);
				$("#searchresult").show();
				$("#maincontent").hide();
				$.get("/search/index/" + encodeURIComponent(s) +
							"?complete=" + ($("#search-prefix").is(':checked') ? '1' : '0'),
							function(fragment) {
									window.clearTimeout(showWaiting);
									$("#searchresult").html(fragment);
							});
		}
}
