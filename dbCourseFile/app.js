//*** VARIABLES TO CHANGE ***
var inputFileName = 'toParseSummer2013.txt',
	outputFileName = 'summerCourses2013.json';

//*** VARIABLES & IMPORTS ***
var cheerio = require('cheerio'),
	fs = require('fs'),
	jsonArray = [];

fs.readFile(inputFileName, function (err, html){
	if(err){
		console.log(err);
		process.exit();
	}

	$ = cheerio.load(html);

	var tdLength = $('table').find('td').length,
		dataArray = [];
	for(var td = 0; td<tdLength;td++){
		getChild($('table').find('td')[td], function (child){
			if(dataArray.length == 0)
				dataArray[0] = child;
			else if(child.match(/^[A-Z]{1,4}\s\d{3}$/) && dataArray[dataArray.length-1].search('Prerequisite') == -1){
				console.log(td + ' / ' + tdLength + ' : ' + ((td/tdLength)*100) + ' %');
				formatData(dataArray);
				dataArray = [];
				dataArray[0] = child;
			}
			else if(child != '')
				dataArray[dataArray.length] = child;
		});
	}
	writeArray();
});


function getChild(tdWithChildren, callback){
	if(typeof tdWithChildren.children == 'undefined'){
		if(tdWithChildren.data.length != 1 && tdWithChildren.data.length != 0 && tdWithChildren.data.search('Fall') == -1 && !tdWithChildren.data.match(/\/\d/))
			callback(tdWithChildren.data.replace(/&.+;/g,''));
	}
	else{
		var tdWithChildrenLength = tdWithChildren.children.length;
		for(var x = 0; x<tdWithChildrenLength; x++){
			getChild(tdWithChildren.children[x], callback);
		}
	}
}

function formatData (data){
	if(!data[0].match(/^[A-Z]{1,4}\s\d{3}$/))
		return;
	else{
		var jsonArrayLength = jsonArray.length,
			json = jsonArray[jsonArrayLength],
			dataLocation = 3,
			dataLength = data.length,
			lastLectureSection = "",
			lastTutorialSection = "";
		
		jsonArray[jsonArrayLength] = {};
		jsonArray[jsonArrayLength]['courseDepartment'] = data[0].split(' ')[0];
		jsonArray[jsonArrayLength]['courseCode'] = data[0].split(' ')[1];
		jsonArray[jsonArrayLength]['courseName'] = data[1];
		jsonArray[jsonArrayLength]['courseCredits'] = data[2].match(/\d/)[0];

		for(dataLocation; dataLocation<dataLength;dataLocation++){

			if(data[dataLocation].match('Prerequisite')){
				jsonArray[jsonArrayLength]['coursePrerequisites'] = [];

				if(data[dataLocation+1].match(/[A-Z]{1,4}\s\d{3}\sor\s[A-Z]{1,4}\s\d{3}/)){
					//There is an or, must take into account
					var orArray = data[dataLocation+1].match(/[A-Z]{1,4}\s\d{3}\sor\s[A-Z]{1,4}\s\d{3}/g),
						splitOrArray = orArray.join(' or ').split(/\sor\s/),
						allCourses = data[dataLocation+1].match(/[A-Z]{1,4}\s\d{3}/g),
						difference = arr_diff(allCourses, splitOrArray);

					orArray = orArray.concat(difference);
					jsonArray[jsonArrayLength]['coursePrerequisites'] = orArray;
				}else{
					//No or, just extract courses
					jsonArray[jsonArrayLength]['coursePrerequisites'] = data[dataLocation+1].match(/[A-Z]{1,4}\s\d{3}/g);
				}

			}else if(data[dataLocation].match('Lect') && data[dataLocation+1] != '*Canceled*'){
				var section = data[dataLocation].split(' ')[1];
				
				if(typeof section == 'undefined'){
					//Used for limit case when it has the format
					//lec
					//AA
					section = data[dataLocation+1];
					lastLectureSection = section;

					if(typeof jsonArray[jsonArrayLength]['lecture'] == 'undefined')
						jsonArray[jsonArrayLength]['lecture'] = {};

					var lectureDayAndTime = data[dataLocation+2].split(' '),
						lectureTime = lectureDayAndTime[1].match(/\d{2}:\d{2}/g);

					jsonArray[jsonArrayLength]['lecture'][section] = {};
					jsonArray[jsonArrayLength]['lecture'][section]['lectureType'] = 'Lect';
					jsonArray[jsonArrayLength]['lecture'][section]['lectureSection'] = section;
					jsonArray[jsonArrayLength]['lecture'][section]['lectureDay'] = lectureDayAndTime[0];
					jsonArray[jsonArrayLength]['lecture'][section]['lectureStartTime'] = lectureTime[0];
					jsonArray[jsonArrayLength]['lecture'][section]['lectureEndTime'] = lectureTime[1];
					jsonArray[jsonArrayLength]['lecture'][section]['lectureLocation'] = data[dataLocation+3];
					jsonArray[jsonArrayLength]['lecture'][section]['lectureTeacher'] = null;

				}else{
					//Used normall when it has the format
					//lec AA
					lastLectureSection = section;

					if(typeof jsonArray[jsonArrayLength]['lecture'] == 'undefined')
						jsonArray[jsonArrayLength]['lecture'] = {};

					var lectureDayAndTime = data[dataLocation+1].split(' '),
						lectureTime = lectureDayAndTime[1].match(/\d{2}:\d{2}/g);

					jsonArray[jsonArrayLength]['lecture'][section] = {};
					jsonArray[jsonArrayLength]['lecture'][section]['lectureType'] = 'Lect';
					jsonArray[jsonArrayLength]['lecture'][section]['lectureSection'] = section;
					jsonArray[jsonArrayLength]['lecture'][section]['lectureDay'] = lectureDayAndTime[0];
					jsonArray[jsonArrayLength]['lecture'][section]['lectureStartTime'] = lectureTime[0];
					jsonArray[jsonArrayLength]['lecture'][section]['lectureEndTime'] = lectureTime[1];
					jsonArray[jsonArrayLength]['lecture'][section]['lectureLocation'] = data[dataLocation+2];
					jsonArray[jsonArrayLength]['lecture'][section]['lectureTeacher'] = data[dataLocation+3];
				}

			}else if(data[dataLocation].match('Tut') && data[dataLocation+2] != '*Canceled*' && typeof jsonArray[jsonArrayLength]['lecture'] != 'undefined'){
				var section = data[dataLocation+1];
				lastTutorialSection = section;

				if(typeof jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'] == 'undefined')
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'] = {};

				var tutorialDayAndTime = data[dataLocation+2].split(' '),
					tutorialTime = lectureDayAndTime[1].match(/\d{2}:\d{2}/g);

				jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][section] = {};
				jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][section]['tutorialType'] = 'Tut';
				jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][section]['tutorialSection'] = section;
				jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][section]['tutorialDay'] = tutorialDayAndTime[0]
				jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][section]['tutorialStartTime'] = tutorialTime[0];
				jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][section]['tutorialEndTime'] = tutorialTime[1];
				jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][section]['tutorialLocation'] = data[dataLocation+3];

			}else if(data[dataLocation].match('Lab') && data[dataLocation+2] != '*Canceled*' && typeof jsonArray[jsonArrayLength]['lecture'] != 'undefined'){
				var section = data[dataLocation+1];

				if(typeof jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'] == 'undefined'){
					//Lab is associated to the lecture not the tutorial

					if(typeof jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['laboratory'] == 'undefined')
						jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['laboratory'] = {};

					var laboratoryDayAndTime = data[dataLocation+2].split(' '),
						laboratoryTime = lectureDayAndTime[1].match(/\d{2}:\d{2}/g);

					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['laboratory'][section] = {};
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['laboratory'][section]['laboratoryType'] = 'Lab';
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['laboratory'][section]['laboratorySection'] = section;
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['laboratory'][section]['laboratoryDay'] = laboratoryDayAndTime[0]
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['laboratory'][section]['laboratoryStartTime'] = laboratoryTime[0];
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['laboratory'][section]['laboratoryEndTime'] = laboratoryTime[1];
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['laboratory'][section]['laboratoryLocation'] = data[dataLocation+3];

				}else{
					//Lab is associated to the tutorial

					if(typeof jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][lastTutorialSection]['laboratory'] == 'undefined')
						jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][lastTutorialSection]['laboratory'] = {};

					var laboratoryDayAndTime = data[dataLocation+2].split(' '),
						laboratoryTime = lectureDayAndTime[1].match(/\d{2}:\d{2}/g);

					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][lastTutorialSection]['laboratory'][section] = {};
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][lastTutorialSection]['laboratory'][section]['laboratoryType'] = 'Lab';
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][lastTutorialSection]['laboratory'][section]['laboratorySection'] = section;
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][lastTutorialSection]['laboratory'][section]['laboratoryDay'] = laboratoryDayAndTime[0]
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][lastTutorialSection]['laboratory'][section]['laboratoryStartTime'] = laboratoryTime[0];
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][lastTutorialSection]['laboratory'][section]['laboratoryEndTime'] = laboratoryTime[1];
					jsonArray[jsonArrayLength]['lecture'][lastLectureSection]['tutorial'][lastTutorialSection]['laboratory'][section]['laboratoryLocation'] = data[dataLocation+3];

				}


			}
		}
	}
}

function writeArray(){
	for(var x=0;x<jsonArray.length;x++){
		jsonArray[x] = JSON.stringify(jsonArray[x]);
		//jsonArray[x] = JSON.stringify(jsonArray[x], null, 4);
	}
	fs.writeFile(outputFileName, jsonArray.join('\n'), function (err) {
	    if(err) {
	      console.log(err);
	    } else {
	      console.log("JSON saved to " + outputFileName);
	    }
	}); 
}

function arr_diff(a1, a2){
	var a=[], diff=[];
	for(var i=0;i<a1.length;i++)
		a[a1[i]]=true;
	for(var i=0;i<a2.length;i++)
		if(a[a2[i]]) delete a[a2[i]];
		else a[a2[i]]=true;
	for(var k in a)
		diff.push(k);
	return diff;
}