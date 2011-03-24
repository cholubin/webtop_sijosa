function getParameterByName( name )
{
  name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
  var regexS = "[\\?&]"+name+"=([^&#]*)";
  var regex = new RegExp( regexS );
  var results = regex.exec( window.location.href );
  if( results == null )
	return "";
  else
	return results[1];
}

function checkPage()
{
	var url = "";
	var page = getParameterByName("page");
	var zoomed = getParameterByName("zoomed");
	if (page)
	{
		url = "#/"+page;
		if (zoomed)
			url+="/zoomed";
			
		var curURL = window.location.href;
		window.location.replace(curURL.substring(0,curURL.indexOf("?")) + url);
	}
}