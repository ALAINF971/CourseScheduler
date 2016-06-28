/**
 * User
 *
 * @module      :: Model
 * @description :: A short summary of how this model works and what it represents.
 * @docs		:: http://sailsjs.org/#!documentation/models
 */

// var env = JSON.parse(process.env.VCAP_SERVICES),
// 	cre = env['mysql-5.1'][0]['credentials'];

module.exports = {
	
	//NOTE UNIQUE ONLY WORKS WITH DB, NOT DISK ADAPTOR

	// adapter: 'mysql',

	// config: {
	// 	user: cre.user,
	// 	password: cre.password,
	// 	database: cre.name,
	// 	host: cre.host
	// },

	// tableName: 'userAuthentication',

	connection: 'mongodb',

	attributes: {
		'firstName':{
			type: 'string',
			unique: false,
			required: true
		},
		'lastName':{
			type: 'string',
			unique: false,
			required: true
		},
		'email': {
			type: 'string',
			unique: true,
			required: true,
			minLength:6
	    },
		'password': {
			type: 'string',
			required: true,
			unique:false,
			minLength:8
		},
		'sid':{
			type: 'string',
			unique:true,
			required: true,
			minLength:7
		},
		'schedule':{
			type:'json',
			require:false,
			unique:false
		},
		toJSON: function() {
	      var obj = this.toObject();
	      delete obj.password;
	      return obj;
	    },
	    validatePassword: function(testPassword){
	    	return this.toObject().password == testPassword
	    }
    
	}

};
