-- =====================================================
-- PROJET SAKILA : Membre 1
-- Tablespaces, utilisateurs, quotas et profils de sécurité
-- =====================================================

-- ========== Connecté en SYSTEM ==========

-- 1. Espace disque dédié
-- (adapte le chemin avec : SELECT file_name FROM dba_data_files;)
CREATE TABLESPACE TBS_SAKILA_DATA
DATAFILE 'tbs_sakila01.dbf' SIZE 50M AUTOEXTEND ON NEXT 10M;

-- 2. Administrateur sans privilège ni quota
-- >>> TEST 1 : connexion SAKILA_ADMIN / SakilaAdmin#2026
-- >>> Erreur attendue : ORA-01045 (capture : ora-01045.png)

-- 3. Droits de session et de création de table
GRANT CREATE SESSION, CREATE TABLE TO SAKILA_ADMIN;

-- >>> TEST 2 : connecté en SAKILA_ADMIN, exécuter :
-- CREATE TABLE TEST (id NUMBER);
-- INSERT INTO TEST VALUES (1);
-- >>> Erreur attendue sur le INSERT : ORA-01950 (capture : ora-01950.png)

-- ========== Revenir en SYSTEM ==========

-- 4. Attribution du quota
ALTER USER SAKILA_ADMIN QUOTA 50M ON TBS_SAKILA_DATA;

-- >>> En SAKILA_ADMIN : INSERT INTO TEST VALUES (1);  -> réussit
-- >>> puis : DROP TABLE TEST;

-- 5. Comptes employés
CREATE USER STAFF_MIKE IDENTIFIED BY "Mike#2026" PASSWORD EXPIRE;
CREATE USER STAFF_JON  IDENTIFIED BY "Jon#2026"  ACCOUNT LOCK;
GRANT CREATE SESSION TO STAFF_MIKE, STAFF_JON;

-- >>> TEST 3 : connexion STAFF_MIKE / Mike#2026
-- >>> Erreur attendue : ORA-28001 (capture : ora-28001.png)
-- >>> TEST 4 : connexion STAFF_JON / Jon#2026
-- >>> Erreur attendue : ORA-28000 (capture : ora-28000.png)

-- 6. Profil de sécurité (blocage après 3 tentatives)
CREATE PROFILE PROF_SAKILA LIMIT
   FAILED_LOGIN_ATTEMPTS 3
   PASSWORD_LOCK_TIME 1/1440
   PASSWORD_LIFE_TIME 90;

ALTER USER STAFF_MIKE PROFILE PROF_SAKILA;
ALTER USER STAFF_JON  PROFILE PROF_SAKILA;

-- 7. Vérifications dans le dictionnaire
SELECT USERNAME, ACCOUNT_STATUS, DEFAULT_TABLESPACE, PROFILE
FROM DBA_USERS WHERE USERNAME LIKE 'STAFF_%';

SELECT * FROM DBA_TS_QUOTAS WHERE USERNAME = 'SAKILA_ADMIN';
