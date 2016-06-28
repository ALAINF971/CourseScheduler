//*** EVENT HANDLERS ***

$(document).ready(function(){
	$('#savedSchedules').hide();
	$('#editStudentRecord').hide();
})

$('#navEditProfile').click(function(){
	console.log('click');
	hideAll();
	unactivateAll();
	$('#editProfile').show();
	$('#naveEditProfileLI').addClass('active');
})

$('#navStudentRecord').click(function(){
	hideAll();
	unactivateAll();
	$('#editStudentRecord').show();
	$('#navStudentRecordLI').addClass('active');
})

$('#navSavedSchedules').click(function(){
	hideAll();
	unactivateAll();
	$('#savedSchedules').show();
	$('#navSavedSchedulesLI').addClass('active');
})

$('#schedulePageRedirect').click(function(){
	window.location='/schedule';
});

$('#submitDeleteProfile').click(function(){
	console.log('click');
	$.post('/profile/deleteProfile',
			{"password":$('#delete_current_password').val()}
	).done(function (data){
		if(!data.error){
			window.location = data;
		}
		else
			$('#deleteError').html(data.error);
	});
})

$('#submitEditProfile').click(function(){
	$.post('/profile/editProfile', {"firstName":$('#first_name').val(), "lastName":$('#last_name').val(), "email":$('#email').val(), "sid":$('#student_id').val(), "newPassword":$('#password').val(), "confirmedNewPassword": $('#confirmed_password').val(), "password":$('#current_password').val()}
	).done(function (data){
		if(data.error)
			$('#editError').html(data.error);
		else
			location.reload();
	});
})

$('#submitAddCourse').click(function(){
	$.post('/profile/addCourse', {"courseDepartment":$('#courseDepartment').val(), "courseCode":$('#courseCode').val()}
	).done(function (data){
		if(data.error)
			$('#addCourseError').html(data.error);
		else
			location.reload();
	});
})

$('.removeCourse').click(function(){
	console.log($(this).attr('id'));
	$.post('/profile/removeCourse', {"courseDepartment":$(this).attr('id').split('//')[0], "courseCode":$(this).attr('id').split('//')[1]}
	).done(function (data){
		if(data.error)
			$('#removeCourseError').html(data.error);
		else
			location.reload();
	});
});

//*** FUNCTIONS ***

function hideAll(){
	$('#editProfile').hide();
	$('#savedSchedules').hide();
	$('#editStudentRecord').hide();
}

function unactivateAll(){
	$('#naveEditProfileLI').removeClass('active');
	$('#navStudentRecordLI').removeClass('active');
	$('#navSavedSchedulesLI').removeClass('active');
}