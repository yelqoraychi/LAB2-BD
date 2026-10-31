CREATE DATABASE IF NOT EXISTS bibliotheque
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE bibliotheque;
CREATE TABLE IF NOT EXISTS auteur (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(100) NOT NULL,
  prenom VARCHAR(100) NOT NULL,
  date_naissance DATE NULL,
  CONSTRAINT chk_auteur_nom CHECK (LENGTH(nom) > 0)
) ENGINE=InnoDB;
INSERT INTO auteur (nom, prenom, date_naissance)
VALUES ('Dupont', 'Marie', '1975-04-12');
CREATE TABLE IF NOT EXISTS ouvrage (
  id INT AUTO_INCREMENT PRIMARY KEY,
  titre VARCHAR(200) NOT NULL,
  isbn CHAR(13) NOT NULL UNIQUE,
  disponible BOOLEAN NOT NULL DEFAULT TRUE,
  auteur_id INT NOT NULL,
  CONSTRAINT fk_ouvrage_auteur FOREIGN KEY (auteur_id)
    REFERENCES auteur(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_isbn CHECK (isbn REGEXP '^[0-9]{13}$')
) ENGINE=InnoDB;
INSERT INTO ouvrage (titre, isbn, disponible, auteur_id)
VALUES ('Les Misérables', '1234567890123', TRUE, 1);
CREATE TABLE IF NOT EXISTS abonne (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(100) NOT NULL,
  prenom VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  date_inscription DATE NOT NULL DEFAULT CURRENT_DATE,
  CONSTRAINT chk_email_format CHECK (email LIKE '%@%._%')
) ENGINE=InnoDB;
INSERT INTO abonne (nom, prenom, email)
VALUES ('Martin', 'Luc', 'luc.martin@example.com');
CREATE TABLE IF NOT EXISTS emprunt (
  ouvrage_id INT NOT NULL,
  abonne_id INT NOT NULL,
  date_debut DATE NOT NULL DEFAULT CURRENT_DATE,
  date_fin DATE NULL,
  PRIMARY KEY (ouvrage_id, abonne_id, date_debut),
  CONSTRAINT fk_emprunt_ouvrage FOREIGN KEY (ouvrage_id)
    REFERENCES ouvrage(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_emprunt_abonne FOREIGN KEY (abonne_id)
    REFERENCES abonne(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_dates CHECK (date_fin IS NULL OR date_fin >= date_debut)
) ENGINE=InnoDB;
INSERT INTO emprunt (ouvrage_id, abonne_id, date_debut)
VALUES (1, 1, CURRENT_DATE);
ALTER TABLE ouvrage ADD INDEX idx_ouvrage_disponible (disponible);
ALTER TABLE emprunt ADD INDEX idx_emprunt_date_fin (date_fin);
INSERT INTO abonne (nom, prenom, email)
VALUES ('Dupont', 'Jean', 'luc.martin@example.com');
INSERT INTO emprunt (ouvrage_id, abonne_id, date_debut, date_fin)
VALUES (1, 1, '2024-10-01', '2024-09-30');
DELIMITER $$
CREATE TRIGGER trg_emprunt_insert BEFORE INSERT ON emprunt
FOR EACH ROW
BEGIN
  -- Vérifier que l'ouvrage est disponible
  IF (SELECT disponible FROM ouvrage WHERE id = NEW.ouvrage_id) = FALSE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'L''ouvrage n''est pas disponible.';
  END IF;
  -- Marquer l'ouvrage comme indisponible
  UPDATE ouvrage SET disponible = FALSE WHERE id = NEW.ouvrage_id;
END$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER trg_emprunt_update AFTER UPDATE ON emprunt
FOR EACH ROW
BEGIN
  IF NEW.date_fin IS NOT NULL THEN
    UPDATE ouvrage SET disponible = TRUE WHERE id = NEW.ouvrage_id;
  END IF;
END$$
DELIMITER ;