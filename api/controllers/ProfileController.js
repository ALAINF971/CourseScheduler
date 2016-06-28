/**
 * ProfileController
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
    
  	index: function (req, res) {
  		if(req.session.authenticated)
            return res.view('profile/profile');
        else
        	res.redirect('/');
    },

    deleteProfile: function (req, res){
      var password = req.body['password'];

      User.findOne({ 'email': req.session.userData.email }, function(err, user) {
        if(err || typeof user == "undefined")
          return res.send({"error":"Invalid information."});
        if(user.validatePassword(password)){
            user.destroy(function(err) {
              if(err)
                return res.send({"error":JSON.stringify(err)});
              req.session.authenticated = false;
              req.session.userData = undefined;
              return res.send('/');
            });
        }
        return res.send({"error":"Invalid information."});
      });

    },

    editProfile: function (req, res){
      var userData = req.body,
          firstName = userData['firstName'],
          lastName = userData['lastName'],
          email = userData['email'],
          password = userData['password'],
          newPassword = userData['newPassword']
          confirmedNewPassword = userData['confirmedNewPassword'],
          sid = userData['sid'];

      User.findOne({ 'email': req.session.userData.email }, function (err, user) {
        if(err)
          return res.send({"error":JSON.stringify(err)});
        if(!user.validatePassword(password))
          return res.send({"error":"Invalid password."});

        if(newPassword != "" && confirmedNewPassword != newPassword)
          return res.send({"error":"New passwords don't match."});
        else if(newPassword != "" && confirmedNewPassword == newPassword)
          user.password = newPassword;
        
        if(firstName != "")
          user.firstName = firstName;
        if(lastName != "")
          user.lastName = lastName;
        if(email != "")
          user.email = email;
        if(sid != "")
          user.sid = sid;

        user.save(function (err){
          if(err)
            return res.send({"error":JSON.stringify(err)});
          sails.controllers.session.updateSession(req, user);
          return res.send('/profile');
        });
      });
    },

    addCourse: function (req, res){
      var userData = req.body,
          courseDepartment = userData['courseDepartment'],
          courseCode = userData['courseCode'];

      User.findOne({ 'email': req.session.userData.email }, function (err, user) {
        if(err)
          return res.send({"error":err});

        if(typeof user.studentRecord == 'undefined')
          user.studentRecord = {};

        user.studentRecord[courseDepartment + '//' + courseCode] = {};
        user.studentRecord[courseDepartment + '//' + courseCode]['courseDepartment'] = courseDepartment;
        user.studentRecord[courseDepartment + '//' + courseCode]['courseCode'] = courseCode;

        user.save(function (err){
          if(err)
            return res.send({"error":JSON.stringify(err)});
          sails.controllers.session.updateSession(req, user);
          return res.send('/profile');
        });

      });
    },

    removeCourse: function (req, res){
      var userData = req.body,
          courseDepartment = userData['courseDepartment'],
          courseCode = userData['courseCode'];

      User.findOne({ 'email': req.session.userData.email }, function (err, user) {
        if(err)
          return res.send({"error":err});

        if(typeof user.studentRecord == 'undefined')
          return {"error":"No student record."};

        delete user.studentRecord[courseDepartment + '//' + courseCode];

        user.save(function (err){
          if(err)
            return res.send({"error":JSON.stringify(err)});
          sails.controllers.session.updateSession(req, user);
          return res.send('/profile');
        });

      });
    },

  /**
   * Overrides for the settings in `config/controllers.js`
   * (specific to ProfileController)
   */
  _config: {}

  
};
