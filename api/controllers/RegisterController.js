/**
 * RegisterController
 *
 * @module      :: Controller
 * @description	:: A set of functions called `actions`.
 *
 *                 Actions contain code telling Sails how to respond to a certain type of request.
 *                 (i.e. do stuff, then send some JSON, show an HTML page, or redirect to another URL)
 *
 *                 You can configure the blueprint URLs which trigger these actions (`config/controllers.js`)
 *                 and/or override them with custom routes (`config/routes.js`)
 *
 *                 NOTE: The code you write here supports both HTTP and Socket.io automatically.
 *
 * @docs        :: http://sailsjs.org/#!documentation/controllers
 */

module.exports = {
    
  
register: function(req, res){
	var userData = req.body,
		firstName = userData['firstName'],
		lastName = userData['lastName'],
        email = userData['email'],
        password = userData['password'],
        confirmedPassword = userData['confirmedPassword'],
        sid = userData['sid'];

    if(password != confirmedPassword)
    	return res.send({"error":"Passords dont match."});

    User.create({
    	'firstName':firstName,
    	'lastName':lastName,
		'email': email,
		'password': password,
		'sid':sid
	}).done(function(err, user) {
	  // Error handling
	  if (err) {
	  	err.error = true;
	    return res.send(err);
	  // The User was created successfully!
	  }else {
	    return sails.controllers.authenticate.login(req,res);
	  }
	});
},

  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to RegisterController)
   */
  _config: {}

  
};
