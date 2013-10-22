PHP < 5.5.0 Authentication based on https://defuse.ca/php-pbkdf2.htm

PHP include file to be used with mosquitto-auth-plug password standards of generationg and checking passwords.

functions:

create_hash(password);

returns password hash.

Create PBKDF2 password hashe with mosquitto-auth-plug compatability

validate_password(password, valid_hash);

Returns true or false.

Checks password against DB saved one.
