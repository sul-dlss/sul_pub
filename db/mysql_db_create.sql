
DROP DATABASE IF EXISTS sulbib_test;
CREATE DATABASE sulbib_test
    DEFAULT CHARACTER SET utf8
    DEFAULT COLLATE utf8_general_ci;

DROP DATABASE IF EXISTS sulbib_development;
CREATE DATABASE sulbib_development
    DEFAULT CHARACTER SET utf8
    DEFAULT COLLATE utf8_general_ci;

# GRANT will create a user if it doesn't exist.
GRANT ALL PRIVILEGES ON sulbib_test.*
  TO 'capAdmin'@'localhost' IDENTIFIED BY 'capPass';
GRANT ALL PRIVILEGES ON sulbib_development.*
  TO 'capAdmin'@'localhost' IDENTIFIED BY 'capPass';
