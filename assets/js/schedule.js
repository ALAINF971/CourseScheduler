//*** EVENT HANDLERS ***

$(document).ready(function(){
	$('#manualGenerate').hide();
})

$('#navAutoGenerateSchedule').click(function(){
	hideAll();
	unactivateAll();
	$('#autoGenerate').show();
	$('#autoGenerateLI').addClass('active');
})

$('#navManuallyStudentRecord').click(function(){
	hideAll();
	unactivateAll();
	$('#manualGenerate').show();
	$('#manualGenerateLI').addClass('active');
})

//*** FUNCTIONS ***

function hideAll(){
	$('#manualGenerate').hide();
	$('#autoGenerate').hide();
}

function unactivateAll(){
	$('#autoGenerateLI').removeClass('active');
	$('#manualGenerateLI').removeClass('active');
}