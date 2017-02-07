// for phoenix_html support, including form and button helpers
// copy the following scripts into your javascript bundle:
// * https://raw.githubusercontent.com/phoenixframework/phoenix_html/v2.3.0/priv/static/phoenix_html.js


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
		
