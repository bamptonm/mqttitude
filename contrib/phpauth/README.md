PHP < 5.5.0 Authentication based on https://defuse.ca/php-pbkdf2.htm

PHP to be used with mosquitto-auth-plug passowrd has standards to check and generate passwords.

functions:

create_hash(password);

returns password hash.

Createse PBKDF2 passwird hashe with mosquitto-auth-plug compatability

validate_password(password, valid_hash);

Returns true or false.

Checks password against DB saved one.
