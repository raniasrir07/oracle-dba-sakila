
-- =====================================================
-- PROJET DBA ORACLE - SAKILA
-- MEMBRE 2 : PRIVILEGES ET DELEGATION
-- =====================================================

-- Schema du projet : SAKILA_ADMIN
-- Utilisateurs : STAFF_MIKE et MANAGER1
-- Chaque partie est executee avec la connexion indiquee.


-- =====================================================
-- PARTIE 1 : ATTRIBUTION DES PRIVILEGES
-- =====================================================

-- 1. Creation de MANAGER1
-- Connexion : SYSTEM
-- Ce compte sera utilise pour les tests de delegation.

CREATE USER MANAGER1 IDENTIFIED BY "Manager1#2026";

-- Autoriser MANAGER1 a se connecter.
GRANT CREATE SESSION TO MANAGER1;


-- 2. Privileges SELECT
-- Connexion : SAKILA_ADMIN
-- STAFF_MIKE peut consulter les films et les clients.

GRANT SELECT ON FILM TO STAFF_MIKE;
GRANT SELECT ON CUSTOMER TO STAFF_MIKE;


-- 3. Privileges sur les colonnes
-- Connexion : SAKILA_ADMIN
-- STAFF_MIKE peut modifier EMAIL et ACTIVE uniquement.

GRANT UPDATE (EMAIL, ACTIVE) ON CUSTOMER TO STAFF_MIKE;


-- 4. WITH GRANT OPTION
-- Connexion : SAKILA_ADMIN
-- MANAGER1 peut consulter PAYMENT et transmettre ce droit.

GRANT SELECT ON PAYMENT TO MANAGER1 WITH GRANT OPTION;


-- 5. WITH ADMIN OPTION
-- Connexion : SYSTEM
-- STAFF_MIKE peut creer des tables et transmettre ce privilege.

GRANT CREATE TABLE TO STAFF_MIKE WITH ADMIN OPTION;


-- =====================================================
-- PARTIE 2 : VERIFICATION DES PRIVILEGES
-- Connexion : SYSTEM
-- =====================================================

-- Afficher les privileges sur les tables.
SELECT GRANTEE, OWNER, TABLE_NAME, PRIVILEGE, GRANTABLE
FROM DBA_TAB_PRIVS
WHERE OWNER = 'SAKILA_ADMIN'
AND TABLE_NAME IN ('FILM', 'CUSTOMER', 'PAYMENT')
AND GRANTEE IN ('STAFF_MIKE', 'MANAGER1')
ORDER BY TABLE_NAME, GRANTEE;


-- Afficher les privileges sur les colonnes de CUSTOMER.
SELECT GRANTEE, TABLE_NAME, COLUMN_NAME, PRIVILEGE
FROM DBA_COL_PRIVS
WHERE OWNER = 'SAKILA_ADMIN'
AND TABLE_NAME = 'CUSTOMER'
AND GRANTEE = 'STAFF_MIKE'
ORDER BY COLUMN_NAME;


-- Afficher les privileges systeme.
SELECT GRANTEE, PRIVILEGE, ADMIN_OPTION
FROM DBA_SYS_PRIVS
WHERE GRANTEE IN ('STAFF_MIKE', 'MANAGER1')
ORDER BY GRANTEE, PRIVILEGE;


-- =====================================================
-- PARTIE 3 : TESTS DES PRIVILEGES
-- =====================================================

-- TEST 1 : Isolation des privileges
-- Connexion : SAKILA_ADMIN
-- Retirer SELECT sur FILM a STAFF_MIKE.

REVOKE SELECT ON FILM FROM STAFF_MIKE;

-- Connexion : STAFF_MIKE
-- Sans SELECT, l'acces a FILM est refuse (ORA-00942).

SELECT * FROM SAKILA_ADMIN.FILM;


-- =====================================================
-- TEST 2 : WITH GRANT OPTION
-- =====================================================

-- Connexion : MANAGER1
-- MANAGER1 transmet SELECT sur PAYMENT a STAFF_MIKE.

GRANT SELECT ON SAKILA_ADMIN.PAYMENT TO STAFF_MIKE;

-- Connexion : SAKILA_ADMIN
-- Retirer SELECT a MANAGER1 provoque une revocation en cascade.

REVOKE SELECT ON PAYMENT FROM MANAGER1;

-- Connexion : STAFF_MIKE
-- STAFF_MIKE perd aussi son acces a PAYMENT (ORA-00942).

SELECT * FROM SAKILA_ADMIN.PAYMENT;


-- =====================================================
-- TEST 3 : WITH ADMIN OPTION
-- =====================================================

-- Connexion : STAFF_MIKE
-- STAFF_MIKE transmet CREATE TABLE a MANAGER1.

GRANT CREATE TABLE TO MANAGER1;

-- Connexion : SYSTEM
-- Retirer CREATE TABLE a STAFF_MIKE.

REVOKE CREATE TABLE FROM STAFF_MIKE;

-- MANAGER1 conserve CREATE TABLE : pas de revocation en cascade.

SELECT GRANTEE, PRIVILEGE, ADMIN_OPTION
FROM DBA_SYS_PRIVS
WHERE GRANTEE IN ('STAFF_MIKE', 'MANAGER1')
AND PRIVILEGE = 'CREATE TABLE';


-- =====================================================
-- TEST 4 : PRIVILEGES SUR LES COLONNES
-- =====================================================

-- Connexion : STAFF_MIKE
-- La modification de EMAIL est autorisee.

UPDATE SAKILA_ADMIN.CUSTOMER
SET EMAIL = 'nouveau@email.com'
WHERE CUSTOMER_ID = 1;

-- Annuler la modification.
ROLLBACK;

-- La modification de CUSTOMER_ID n'est pas autorisee.
-- Ce droit n'a pas ete accorde a STAFF_MIKE.
-- Test facultatif :
-- UPDATE SAKILA_ADMIN.CUSTOMER
-- SET CUSTOMER_ID = 999
-- WHERE CUSTOMER_ID = 1;


-- =====================================================
-- PARTIE 4 : RESTAURATION DES PRIVILEGES
-- =====================================================

-- Connexion : SAKILA_ADMIN
-- Restaurer les privileges retires pendant les tests.

GRANT SELECT ON FILM TO STAFF_MIKE;

GRANT SELECT ON PAYMENT TO MANAGER1 WITH GRANT OPTION;


-- Connexion : SYSTEM
-- Redonner CREATE TABLE a STAFF_MIKE.

GRANT CREATE TABLE TO STAFF_MIKE WITH ADMIN OPTION;

-- Retirer le privilege donne temporairement a MANAGER1.
-- A executer s'il ne le possedait pas avant le test.

REVOKE CREATE TABLE FROM MANAGER1;



