-- ====================================================================
-- MODULE       : Ingénierie & Administration des Bases de Données
-- PROJET       : Administration & Sécurisation de la Base SAKILA
-- ETUDIANTE    : Rania SRIR (Génie Informatique CI2)
-- TÂCHE 4      : Synonymes Publics, Row-Level Security (SYS_CONTEXT) & Audit
-- ENVIRONNEMENT: Oracle 21c XE / PDB : XEPDB1 / SQL Developer
-- ====================================================================


-- ====================================================================
-- PARTIE 1 : MASQUAGE DU SCHÉMA PAR SYNONYMES PUBLICS 
-- Objectif : Permettre d'interroger les tables sans le préfixe 'SAKILA.'
-- ====================================================================

-- 1.1 Requête de métaprogrammation pour générer dynamiquement les synonymes :
-- SELECT 'CREATE PUBLIC SYNONYM ' || TABLE_NAME || ' FOR SAKILA.' || TABLE_NAME || ';'
-- FROM ALL_TABLES WHERE OWNER = 'SAKILA';

-- 1.2 Exécution de la création des 16 synonymes publics de Sakila :
CREATE PUBLIC SYNONYM ACTOR FOR SAKILA.ACTOR;
CREATE PUBLIC SYNONYM ADDRESS FOR SAKILA.ADDRESS;
CREATE PUBLIC SYNONYM CATEGORY FOR SAKILA.CATEGORY;
CREATE PUBLIC SYNONYM CITY FOR SAKILA.CITY;
CREATE PUBLIC SYNONYM COUNTRY FOR SAKILA.COUNTRY;
CREATE PUBLIC SYNONYM CUSTOMER FOR SAKILA.CUSTOMER;
CREATE PUBLIC SYNONYM FILM FOR SAKILA.FILM;
CREATE PUBLIC SYNONYM FILM_ACTOR FOR SAKILA.FILM_ACTOR;
CREATE PUBLIC SYNONYM FILM_CATEGORY FOR SAKILA.FILM_CATEGORY;
CREATE PUBLIC SYNONYM FILM_TEXT FOR SAKILA.FILM_TEXT;
CREATE PUBLIC SYNONYM INVENTORY FOR SAKILA.INVENTORY;
CREATE PUBLIC SYNONYM LANGUAGE FOR SAKILA.LANGUAGE;
CREATE PUBLIC SYNONYM PAYMENT FOR SAKILA.PAYMENT;
CREATE PUBLIC SYNONYM RENTAL FOR SAKILA.RENTAL;
CREATE PUBLIC SYNONYM STAFF FOR SAKILA.STAFF;
CREATE PUBLIC SYNONYM STORE FOR SAKILA.STORE;

-- 1.3 Contrôle dans le dictionnaire de données :
SELECT SYNONYM_NAME, TABLE_OWNER, TABLE_NAME 
FROM DBA_SYNONYMS 
WHERE TABLE_OWNER = 'SAKILA';


-- ====================================================================
-- PARTIE 2 : SÉCURITÉ AU NIVEAU LIGNE AVEC SYS_CONTEXT 
-- Objectif : Chaque caissier ne doit voir que ses propres transactions
-- ====================================================================

-- 2.1 Création de la vue filtrante basée sur la session active
CREATE OR REPLACE VIEW SAKILA.V_MES_LOCATIONS AS
SELECT 
    r.RENTAL_ID,
    r.RENTAL_DATE,
    r.INVENTORY_ID,
    r.CUSTOMER_ID,
    r.RETURN_DATE,
    r.STAFF_ID
FROM SAKILA.RENTAL r
WHERE r.STAFF_ID = (
    SELECT s.STAFF_ID 
    FROM SAKILA.STAFF s 
    WHERE UPPER(s.USERNAME) = SYS_CONTEXT('USERENV', 'SESSION_USER')
);

-- 2.2 Création du synonyme public et attribution du droit de lecture
CREATE PUBLIC SYNONYM V_MES_LOCATIONS FOR SAKILA.V_MES_LOCATIONS;
GRANT SELECT ON SAKILA.V_MES_LOCATIONS TO PUBLIC;


-- ====================================================================
-- PARTIE 3 : CRÉATION DU COMPTE EMPLOYÉ ET TESTS DE SÉCURITÉ 
-- ====================================================================

-- 3.1 Création du compte pour l'employé Mike (Staff_ID = 1)
CREATE USER MIKE IDENTIFIED BY "Mike#2026";
GRANT CREATE SESSION TO MIKE;

-- 3.2 Tests comparatifs de validation de la sécurité :
-- Test A (Connecté en SYSTEM) :
-- SELECT COUNT(*) FROM V_MES_LOCATIONS;
-- -> Résultat : 0 (SYSTEM n'est pas un employé caissier dans STAFF)

-- Test B (Connecté en MIKE) :
-- SELECT COUNT(*) FROM V_MES_LOCATIONS;
-- -> Résultat : 8040 locations
-- SELECT DISTINCT STAFF_ID FROM V_MES_LOCATIONS;
-- -> Résultat : UNIQUEMENT STAFF_ID = 1 (Isolation totale des données de Jon)


-- ====================================================================
-- PARTIE 4 : AUDIT GLOBAL DE SÉCURITÉ VIA LE DICTIONNAIRE 
-- Objectif : Consolider tous les privilèges système, objet et rôles
-- ====================================================================

SELECT GRANTEE, 'SYSTEME' AS TYPE_PRIV, PRIVILEGE AS DROIT, 'GLOBAL' AS CIBLE
FROM DBA_SYS_PRIVS 
WHERE GRANTEE IN ('MIKE', 'SAKILA')
UNION ALL
SELECT GRANTEE, 'OBJET', PRIVILEGE, OWNER || '.' || TABLE_NAME
FROM DBA_TAB_PRIVS 
WHERE OWNER = 'SAKILA' AND GRANTEE IN ('MIKE', 'PUBLIC')
UNION ALL
SELECT GRANTEE, 'ROLE', GRANTED_ROLE, 'N/A'
FROM DBA_ROLE_PRIVS 
WHERE GRANTEE IN ('MIKE', 'SAKILA')
ORDER BY 1, 2;


-- ====================================================================
-- PARTIE 5 : SCRIPT DE NETTOYAGE REJOUABLE (CLEANUP)
-- À exécuter en fin de projet pour réinitialiser l'environnement
-- ====================================================================
/*
DROP PUBLIC SYNONYM V_MES_LOCATIONS;
DROP VIEW SAKILA.V_MES_LOCATIONS;
DROP USER MIKE CASCADE;

DROP PUBLIC SYNONYM ACTOR;
DROP PUBLIC SYNONYM ADDRESS;
DROP PUBLIC SYNONYM CATEGORY;
DROP PUBLIC SYNONYM CITY;
DROP PUBLIC SYNONYM COUNTRY;
DROP PUBLIC SYNONYM CUSTOMER;
DROP PUBLIC SYNONYM FILM;
DROP PUBLIC SYNONYM FILM_ACTOR;
DROP PUBLIC SYNONYM FILM_CATEGORY;
DROP PUBLIC SYNONYM FILM_TEXT;
DROP PUBLIC SYNONYM INVENTORY;
DROP PUBLIC SYNONYM LANGUAGE;
DROP PUBLIC SYNONYM PAYMENT;
DROP PUBLIC SYNONYM RENTAL;
DROP PUBLIC SYNONYM STAFF;
DROP PUBLIC SYNONYM STORE;
*/
