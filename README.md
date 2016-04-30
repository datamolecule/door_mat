# DoorMat

Keeping keys safe since front doors have locks...

[![Gem Version](https://badge.fury.io/rb/door_mat.svg)](https://badge.fury.io/rb/door_mat) [![Code Climate](https://codeclimate.com/github/datamolecule/door_mat/badges/gpa.svg)](https://codeclimate.com/github/datamolecule/door_mat) <a href="https://codeclimate.com/github/datamolecule/door_mat/coverage"><img src="https://codeclimate.com/github/datamolecule/door_mat/badges/coverage.svg" /></a>

### What is the DoorMat library?

DoorMat is a Rails Engine that provides a solution for both user authentication and the encryption of user information. It aims to offer safe defaults so you can get going with what your website is really about.

Although DoorMat is flexible and supports a variety of information sharing scenarios, its most basic configuration is such that _in the normal course of business_, the system operator does not have access to the user information protected by the encrypted store. The impact of this feature is that users must upload a recovery key file in order to reset their password should they forget it.


### Security

#### Read me first!
**Disclaimer**: DoorMat is a fairly young and experimental library that could greatly benefit from the scrutiny of many eyes. Although care and efforts were taken while crafting this library, there is no doubt that it will contain various bugs. _Proceed with caution!_

That being said, DoorMat aims to cover the basics and set sensible defaults while allowing customization.

#### Batteries included
DoorMat seeks to provide reasonable default configuration values for session management and data encryption. Many behaviour settings are biased toward security rather than a smooth user experience and may need to be relaxed depending on your site's security requirements.

Although the initial default values may need to be updated, there should not be a need for the new user to select adequate values in order to harden the system. Rather, it should be secure by default and later customized to provide a better user experience.

#### Crunchy on the Outside _and_ the Inside
The reason for this emphasis is that although data theft by external actors get a lot of visibility in the press and makes for sensational news, [insider threats outrank external attacks](https://securityintelligence.com/the-threat-is-coming-from-inside-the-network/).

One aspect of user data security addressed by DoorMat is that _in the normal course of business_, with the engine running in a `RAILS_ENV=production` environment using unaltered source code, the user information protected by the symmetric store is not accessible to the site operator.

This means that by default, when a user creates an account, the site operator or any individual that gains access to the database cannot simply query the emails table to harvest user addresses. Each user's email address is encrypted using a key derived from their password.


### Features

DoorMat currently provides the following features out of the box:

User side features
- User account sign-up
- Email address confirmation
- Manage account email address (add, remove) for an account
- Change password
- Download password recovery key file
- Reset forgotten password (using the recovery key file)
- Public / private computer selection at login time
- Remember me feature when a session is opened from a private computer
- Terminate other active sessions (so you can remotely kill that session you forgot to close on the public library computer)

System side features
- Standard email / password based accounts
- Alternative password less accounts with access control based on security tokens sent to users email address
- User information stores using symmetric encryption. For password secured accounts only
- Secret sharing store using asymmetric encryption
- Before / after hooks for various user activities: sign up/in/out, etc.
- Access restriction filters
 - Only allow access to sessions from confirmed email address
 - Require user to re-enter password for access to sensitive routes
- Easy to override defaults
 - Redirection after user activity success / failure
 - Session / remember me expiration delay for public / private computer selection
 - Maximum number of emails per account
 - Maximum number of accounts a single email can be associated with (aka server side plausible deniability)
 - etc.


### Usage

Run tests with `bundle exec rspec` and set `COVERAGE=true` to generate the coverage report after setting up the test database with `RAILS_ENV=test bundle exec rake db:drop db:create db:migrate`.

See `spec/test_app` for a sample application illustrating the various DoorMat features. You can `bundle exec rails server -p3001` to run a local instance.

You will also need to have [MailCatcher](https://mailcatcher.me/) running so you can confirm the email address you register with and to receive password less access tokens.
Point one browser tab to `http://localhost:1080` to access your local email and a second one to `http://localhost:3001` to interact with the test application.

See [&mu;PM](https://github.com/datamolecule/mupm) for a sample integration of DoorMat.


### Gem Version History

**0.0.5 - Why so serious?** (April 4, 2016)

* Initial public release.


### License

Copyright &copy; 2016 Luc Lussier

Released under the MIT license. See [MIT-LICENSE](MIT-LICENSE) for details.
