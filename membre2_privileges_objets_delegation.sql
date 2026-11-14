-- ============================================================
-- PROJET DBA ORACLE - SAKILA
-- Membre 2 : Privileges objet, colonnes et delegation
-- ============================================================
-- Schema utilise par le groupe : SAKILA_ADMIN
-- Comptes crees dans la partie 1 : STAFF_MIKE, STAFF_JON
-- Compte utilise pour la delegation : MANAGER1
--
-- Chaque bloc est execute dans la connexion indiquee.
-- Ne pas lancer le fichier entier d'un seul coup : certaines
-- commandes doivent etre executees par des utilisateurs differents.
-- ============================================================


-- ============================================================
-- PARTIE 1 - MISE EN PLACE DES PRIVILEGES
-- ============================================================

-- 1. Preparation du compte MANAGER1
-- Connexion : SYSTEM (XEPDB1)
-- MANAGER1 n'est pas cree dans la partie du membre 1.
-- Creation une seule fois, si le compte n'existe pas deja.
-- Mot de passe de demonstration utilise pour MANAGER1 : Manager1#2026.
-- A partager avec les membres du groupe pour leurs bases locales.

-- A executer uniquement si MANAGER1 n'existe pas :
CREATE USER MANAGER1 IDENTIFIED BY "Manager1#2026";
GRANT CREATE SESSION TO MANAGER1;


-- 2. Acces en lecture aux films et aux clients
-- Connexion : SAKILA_ADMIN
-- STAFF_MIKE peut consulter FILM et CUSTOMER.

GRANT SELECT ON FILM TO STAFF_MIKE;
GRANT SELECT ON CUSTOMER TO STAFF_MIKE;


-- 3. Modification limitee a certaines colonnes
-- Connexion : SAKILA_ADMIN
-- STAFF_MIKE peut modifier EMAIL et ACTIVE de CUSTOMER,
-- mais ne recoit pas le droit UPDATE sur CUSTOMER_ID.

GRANT UPDATE (EMAIL, ACTIVE) ON CUSTOMER TO STAFF_MIKE;


-- 4. Delegation d'un privilege objet
-- Connexion : SAKILA_ADMIN
-- MANAGER1 peut lire PAYMENT et donner ce droit a un autre compte.

GRANT SELECT ON PAYMENT TO MANAGER1 WITH GRANT OPTION;


-- 5. Delegation d'un privilege systeme
-- Connexion : SYSTEM (XEPDB1)
-- STAFF_MIKE peut creer des tables et transmettre ce droit.

GRANT CREATE TABLE TO STAFF_MIKE WITH ADMIN OPTION;


-- ============================================================
-- PARTIE 2 - VERIFICATION DES PRIVILEGES
-- Connexion : SYSTEM (XEPDB1)
-- ============================================================

-- Privileges sur les tables
SELECT GRANTEE, OWNER, TABLE_NAME, PRIVILEGE, GRANTABLE
FROM DBA_TAB_PRIVS
WHERE OWNER = 'SAKILA_ADMIN'
  AND TABLE_NAME IN ('FILM', 'CUSTOMER', 'PAYMENT')
  AND GRANTEE IN ('STAFF_MIKE', 'MANAGER1')
ORDER BY TABLE_NAME, GRANTEE;

-- Privileges sur les colonnes EMAIL et ACTIVE
SELECT GRANTEE, TABLE_NAME, COLUMN_NAME, PRIVILEGE
FROM DBA_COL_PRIVS
WHERE OWNER = 'SAKILA_ADMIN'
  AND TABLE_NAME = 'CUSTOMER'
  AND GRANTEE = 'STAFF_MIKE'
ORDER BY COLUMN_NAME;

-- Privileges systeme et droit de delegation
SELECT GRANTEE, PRIVILEGE, ADMIN_OPTION
FROM DBA_SYS_PRIVS
WHERE GRANTEE IN ('STAFF_MIKE', 'MANAGER1')
ORDER BY GRANTEE, PRIVILEGE;


-- ============================================================
-- PARTIE 3 - TESTS PRINCIPAUX
-- ============================================================

-- TEST 1 : acces refuse sans SELECT
-- Connexion : SAKILA_ADMIN
-- On retire temporairement SELECT sur FILM.
REVOKE SELECT ON FILM FROM STAFF_MIKE;

-- Connexion : STAFF_MIKE
-- Resultat attendu : ORA-00942 (si aucun autre acces).
SELECT * FROM SAKILA_ADMIN.FILM;


-- TEST 2 : WITH GRANT OPTION et revocation en cascade
-- Connexion : MANAGER1
-- MANAGER1 transmet SELECT sur PAYMENT a STAFF_MIKE.
GRANT SELECT ON SAKILA_ADMIN.PAYMENT TO STAFF_MIKE;

-- Connexion : SAKILA_ADMIN
-- La revocation a MANAGER1 retire aussi le droit qu'il a transmis.
REVOKE SELECT ON PAYMENT FROM MANAGER1;

-- Connexion : STAFF_MIKE
-- Resultat attendu : ORA-00942 (si aucun autre acces).
SELECT * FROM SAKILA_ADMIN.PAYMENT;


-- TEST 3 : WITH ADMIN OPTION, sans revocation en cascade
-- Connexion : STAFF_MIKE
-- STAFF_MIKE transmet CREATE TABLE a MANAGER1.
GRANT CREATE TABLE TO MANAGER1;

-- Connexion : SYSTEM (XEPDB1)
-- On retire CREATE TABLE a STAFF_MIKE.
REVOKE CREATE TABLE FROM STAFF_MIKE;

-- MANAGER1 garde CREATE TABLE malgre cette revocation.
SELECT GRANTEE, PRIVILEGE, ADMIN_OPTION
FROM DBA_SYS_PRIVS
WHERE GRANTEE IN ('STAFF_MIKE', 'MANAGER1')
  AND PRIVILEGE = 'CREATE TABLE';


-- TEST 4 : modification autorisee sur EMAIL
-- Connexion : STAFF_MIKE
-- Exemple sur le client 1, si cet identifiant existe.
UPDATE SAKILA_ADMIN.CUSTOMER
SET EMAIL = 'nouveau@email.com'
WHERE CUSTOMER_ID = 1;

-- On annule immediatement cette modification avant tout GRANT/REVOKE,
-- car ces commandes peuvent valider automatiquement la transaction.
ROLLBACK;

-- Le refus de UPDATE sur CUSTOMER_ID est deja illustre par
-- les privileges visibles dans DBA_COL_PRIVS. Si une demonstration
-- directe est demandee, executer separement la requete suivante :
-- UPDATE SAKILA_ADMIN.CUSTOMER
-- SET CUSTOMER_ID = 999 WHERE CUSTOMER_ID = 1;
-- Resultat attendu : ORA-01031 si aucun autre privilege UPDATE.
-- ROLLBACK;


-- ============================================================
-- PARTIE 4 - RESTAURATION APRES LES TESTS
-- Pour retrouver les memes privileges qu'avant les tests.
-- Cette partie sert a remettre la base en etat pour le groupe.
-- ============================================================

-- Connexion : SAKILA_ADMIN
-- Restaurer SELECT sur FILM pour STAFF_MIKE.
GRANT SELECT ON FILM TO STAFF_MIKE;

-- Restaurer SELECT sur PAYMENT pour MANAGER1, avec delegation.
GRANT SELECT ON PAYMENT TO MANAGER1 WITH GRANT OPTION;

-- Connexion : SYSTEM (XEPDB1)
-- Restaurer CREATE TABLE avec ADMIN OPTION a STAFF_MIKE.
GRANT CREATE TABLE TO STAFF_MIKE WITH ADMIN OPTION;

-- Retirer a MANAGER1 le CREATE TABLE recu uniquement pour le test.
-- A faire seulement s'il ne possedait pas ce droit avant le test.
REVOKE CREATE TABLE FROM MANAGER1;



