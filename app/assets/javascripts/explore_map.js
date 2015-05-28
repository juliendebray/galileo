var handler;
var markers = {};

function initializeFilterButtons(trip_id) {
  SetAndRemoveButtonActiveClassOnClick(trip_id);
}

function SetAndRemoveButtonActiveClassOnClick(trip_id) {
  $('a.category-btn').on('click', function() {
    if ($(this).hasClass('active')) {
      $(this).removeClass('active');
    } else {
      $(this).addClass('active');
    }
    requestDataFromAPI(trip_id, collectUserChoice());
  });
}

function collectUserChoice() {
  var categories = [];
  var activeButton = $('a.category-btn.active');
  $.each(activeButton, function(index, value) {
    categories.push(value.id);
  });
  return {'categories': categories }
}

function requestDataFromAPI(trip_id, dataToSend) {
  var url = "/trips/" + trip_id + "/search_results";
  $.getJSON(url,  dataToSend, function( data ) {
    console.log(data);
    handler.removeMarkers(markers);
    markers = handler.addMarkers(data);
  });
}