/**
 * CoursesFall2013
 *
 * @module      :: Model
 * @description :: A short summary of how this model works and what it represents.
 * @docs		:: http://sailsjs.org/#!documentation/models
 */

module.exports = {

  attributes: {
  	
  	'courseName':{
		type: 'string',
		unique: true,
		required: true
	},
	'courseDepartment':{
		type: 'string',
		unique: false,
		required: true
	},
	'courseCode':{
		type: 'string',
		unique: false,
		required: true
	},
	'courseCredits':{
		type: 'integer',
		unique: false,
		required: true
	},
	'coursePrerequisites':{
		type:'array',
		unique: false,
		required: false
	},
	'lecture':{
		type:'json',
		unique:false,
		required:false
	},
	'laboratory':{
		type:'json',
		unique: false,
		required: false
	},
	toJSON: function() {
      var obj = this.toObject();
      return obj;
    },
    canTake: function(student){
    	return false;
    }
    
  }

};
