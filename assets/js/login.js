//*** Variables ***

//*** Jquery Events ***

$('#submit').click(function(){
	$.post(
		'/authenticate/login',
		{"email":$('#email').val(),"password":$('#password').val()}
	).done(
		function (data){
			if(!data.error)
				window.location = data;
			else
				$('#error').html(data.error);
		});
});

//*** Socket events ***

// socket.on('error', function(session){
// 	//Will display an error to the user
// 	loginHeader.html(session.error);
// 	loginHeader.css({'color':'red'});
// });

//*** Functions ***

