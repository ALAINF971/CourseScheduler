/**
 * AuthenticateController
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
    
  /**
   * Action blueprints:
   *    `/authenticate/login
   */
   
login: function (req, res) {
    var userData = req.body,
        email = userData['email'],
        password = userData['password'];

    //TEMPORARY used to list all registered people for testing
    console.log('Users:');
    User.find().done(function(err, data){
      console.log(data);
    });

    //TEMPORARY used to list all registered people for testing
    console.log('Some Fall 2013 Courses:');
    CoursesFall2013.find({"courseDepartment":"ENGR"}).done(function(err, data){
      console.log(data);
    });

    User.findOne({ 'email': email }, function(err, user) {
      if(err || typeof user == "undefined")
        return res.send({"error":"Invalid information."});
      if(user.validatePassword(password)){
        req.session.authenticated = true;
        sails.controllers.session.updateSession(req, user);
        return res.send('/schedule');
      }
      return res.send({"error":"Invalid information."});
    });
  },

logout: function (req, res) {
        req.session.authenticated = false;
        req.session.userData = undefined;
        return res.redirect('/');
},

  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to AuthenticateController)
   */
  _config: {}

  
};
