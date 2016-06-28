$('#submit').click(function(){
	console.log('click');
	$.post(	'/register/register', 
			{"firstName":$('#first_name').val(), "lastName":$('#last_name').val(), "email":$("#email").val(),"password":$("#password").val(), 'sid':$('#student_id').val(), "confirmedPassword":$('#confirmed_password').val()}
	).done(function (data){
			if(!data.error){
				console.log(data);
				window.location = data;
			}
			else
				$('#error').html(JSON.stringify(data));
		});
})