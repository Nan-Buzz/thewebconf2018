var lastFocusElement = '';
function openNav(obj) {
	lastFocusElement = obj;
		$("#mySidenav a").each(function(){
		$('#mySidenav a').removeClass('active');
		$('#mySidenav a[href=#'+ $(obj).closest("section").attr('id') +']').addClass('active');
	});	
    document.getElementById("mySidenav").style.width = "280px";
    document.getElementById("main").style.marginLeft = "280px";
    $('#mySidenav').attr({'aria-hidden':'false', 'tabindex':''});

    addTabindexToNav();
    if($(obj).attr('id') == 'ArtNav'){
    	setTimeout(function(){
	    	$(".closebtn").focus();
	    },300);
    }
    else{
    	$('.navLista').removeClass('active');
		$('.navLista[href=#'+ $(obj).closest("section").attr('id') +']').addClass('active').focus();
    }
}

function closeNav(isCloseBtnClick) {
	if(isCloseBtnClick === undefined) {
      isCloseBtnClick = false;
   	}
    document.getElementById("mySidenav").style.width = "0";
    document.getElementById("main").style.marginLeft= "auto";
    $('#mySidenav').attr({'aria-hidden':'true','tabindex':'-1'});

    $('.navLista').each(function(){
    	$(this).attr('tabindex','-1');
    });
    $(".navAbs").attr("tabindex","-1");
	$(".closebtn").attr("tabindex","-1");
	if(isCloseBtnClick){
		setTimeout(function(){
	    	$(lastFocusElement).focus();
	    }, 50);	
	}
}

function addTabindexToNav(){
	$('.navLista').removeClass('active');
	$(".navLista").attr("tabindex","1");
	$(".navAbs").attr("tabindex","1");
	$(".closebtn").attr("tabindex","1");
}

$(document).ready(function(){
	$('.front-matter').before($("<div id='mySidenav' class='sidenav' aria-hidden='true' tabindex='-1' role='region' aria-labelledby='sidebar_title'><span id='sidebar_title' class='navHead' align='center'>Article Navigation</span><a href='#' aria-label='Close article navigation' class='closebtn' onclick='closeNav(true)' tabindex='-1'><span aria-hidden='true'>&#x00D7;</span></a></div>"));
	var ToC = "<a href='#' class='navAbs' onclick='closeNav(false)' tabindex='-1'>Abstract</a>";
	var el, title, link, insRt, hR, titleN;
	$(".back-matter h1, .footnote h1, h2, h3, h4, h5").each(function() {
		el = $(this);
		insRt = "";
		hR = "";
		titleN = el.find('span.section-number').text();
		title = el.text().replace(titleN,'');
		link = "#" + (el).closest("section").prop("id");
		if ( el.is( "h3" ) ) {
			insRt = "&#x2003;";
		}
		if ( el.is( "h4" ) ) {
			insRt = "&#x2003;&#x2003;";
		}
		if ( el.is( "h5" ) ) {
			insRt = "&#x2003;&#x2003;&#x2003;";
		}
		if ( el.is( "h1, h2" ) ) {
			hR = "<hr\>";
		}
		newLine = hR + "<a class='navLista' onclick='closeNav(false)' style='display:list-item;' tabindex='-1' href='" + link + "'>"  + insRt +'<span style="vertical-align: top;">'+titleN+'</span><span style="display:inline-block;margin-left:5px;width:80%">'+title+ "</span></a>";
		ToC += newLine;
	});

	$(".sidenav").append(ToC);

	$(function () {
		$(".back-matter h1, .footnote h1, h2, h3, h4, h5, h6").each(function(){
			var hl = $(this);
			if(hl.children(".section-number").length > 0 ){
				/*	alert(hl.text()); */
					$('h2 .section-number, h3 .section-number, h4 .section-number, h5 .section-number, h6 .section-number').replaceWith(function () {
					return "<span class='section-number'><span class='nav-open' id='nav-open' onclick='openNav(this)' title='navigate to' tabindex='0'>" + $(this).text() + "</span></span>";
				});
			}else {
				$(hl).html("<span class='nav-open' id='nav-open' onclick='openNav(this)' tabindex='0' title='navigate to'>" + hl.text() + "</span>");
			}
		});
	});
	$( "body" ).attr("id", "main");
	$( "body" ).prepend( "<table><tbody><tr><td align='left'><button class='ArtNav' id='ArtNav' onclick='openNav(this)' tabindex='0'><span aria-hidden='true'>&#9776;</span><span class='ArticleNavi'> Article Navigation</span></button></td></tr></table>" );
	$(document).click(function(e) {
		if (e.target.id != 'ArtNav' && !$('#ArtNav').find(e.target).length && e.target.id != 'mySidenav' && !$('#mySidenav').find(e.target).length && $(e.target).attr('class') != 'nav-open') {
			document.getElementById("mySidenav").style.width = "0";
			document.getElementById("main").style.marginLeft= "auto";
		}
	});
	$("#ArtNav").keydown(function(event){
		var key = event.which || event.keyCode;
		if(key == 13){ // Enter			
			addTabindexToNav();
			//$(".ArtNav").attr("tabindex","1");
			document.getElementById("mySidenav").style.width = "280px";
			document.getElementById("main").style.marginLeft = "280px";
			setTimeout(function(){
		    	$(".closebtn").focus();
		    },300);
		}
	});

	$(document).on("keypress", "#nav-open", function(event){
		var key = event.which || event.keyCode;
		lastFocusElement = event.target;
		if(key == 13){ // Enter
			$('.navLista').removeClass('active');
			$('.navLista[href=#'+ $(this).closest("section").attr('id') +']').addClass('active').focus();
			document.getElementById("mySidenav").style.width = "280px";
			document.getElementById("main").style.marginLeft = "280px";
			addTabindexToNav();
		}
	});

	$(document).keyup(function(event) {
		var key = event.which || event.keyCode;
		if(key == 27){ // Excape key
			document.getElementById("mySidenav").style.width = "0";
			document.getElementById("main").style.marginLeft= "auto";
		}
	});

	$(document).on("keydown", ".navLista", function(){
		var key = event.which || event.keyCode;
		if(key == 13){
			var targetId = $(this).attr('href');
			$(targetId).focus(); 
		}
	});
});
