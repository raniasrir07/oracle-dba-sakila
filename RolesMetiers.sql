ALTER USER STAFF_MIKE IDENTIFIED BY "Mike#2026" ACCOUNT UNLOCK;
-- Role des caissiers : operations quotidiennes au comptoir
CREATE ROLE ROLE_AGENT_LOCATION;

-- Role des responsables : supervision et statistiques
CREATE ROLE ROLE_MANAGER;

-- Role de l'administrateur : structure et technique
CREATE ROLE ROLE_ADMIN_SAKILA;

-- Un role peut porter le droit de connexion : les utilisateurs qui
-- recoivent le role pourront ainsi se connecter
GRANT CREATE SESSION TO ROLE_AGENT_LOCATION;
GRANT CREATE SESSION TO ROLE_MANAGER;
GRANT CREATE SESSION, CREATE VIEW, CREATE TABLE TO ROLE_ADMIN_SAKILA;


/* =====================================================================
   Principe  : on donne les droits au ROLE une seule fois, plus besoin
               de les donner utilisateur par utilisateur.
   ===================================================================== */

-- Agent : consulte le catalogue, enregistre locations et paiements
GRANT SELECT         ON FILM    TO ROLE_AGENT_LOCATION;
GRANT SELECT, INSERT ON RENTAL  TO ROLE_AGENT_LOCATION;
GRANT SELECT, INSERT ON PAYMENT TO ROLE_AGENT_LOCATION;

-- Manager : lecture seule pour superviser l'activite
GRANT SELECT ON PAYMENT  TO ROLE_MANAGER;
GRANT SELECT ON RENTAL   TO ROLE_MANAGER;
GRANT SELECT ON CUSTOMER TO ROLE_MANAGER;
GRANT SELECT ON STAFF    TO ROLE_MANAGER;
GRANT SELECT ON STORE    TO ROLE_MANAGER;


/* =====================================================================
   PARTIE 3 : AFFECTATION DES ROLES AUX UTILISATEURS
   Connexion : Oracle-xe (SYSTEM)
   ===================================================================== */

GRANT ROLE_ADMIN_SAKILA   TO SAKILA_ADMIN;
GRANT ROLE_MANAGER        TO MANAGER1;
GRANT ROLE_AGENT_LOCATION TO MANAGER1;
GRANT ROLE_AGENT_LOCATION TO STAFF_MIKE;

-- On retire a STAFF_MIKE son droit de connexion direct.
-- (Il avait CREATE SESSION en direct : ce REVOKE ne marche que dans ce cas.)
-- Il pourra quand meme se connecter grace a CREATE SESSION porte par le role.
REVOKE CREATE SESSION FROM STAFF_MIKE;


/* =====================================================================
   PARTIE 4 : VERIFICATION DES PRIVILEGES DE SESSION
   Connexion : staff_mike
   ===================================================================== */

-- Roles actifs dans la session : doit afficher ROLE_AGENT_LOCATION
SELECT * FROM SESSION_ROLES;

-- Privileges systeme actifs : doit afficher CREATE SESSION (recu via le role)
SELECT * FROM SESSION_PRIVS;

-- Le SELECT fonctionne grace au role
SELECT COUNT(*) FROM SAKILA.FILM;


/* =====================================================================
   PARTIE 5 : LE PIEGE DES VUES (DEFINER'S RIGHTS)
   ===================================================================== */

-- 5a. Connexion SYSTEM : MANAGER1 a le droit de creer des vues
GRANT CREATE VIEW TO MANAGER1;

-- 5b. Connexion manager1 : le SELECT sur PAYMENT marche, via le role
SELECT COUNT(*) FROM SAKILA.PAYMENT;

-- Tentative de creation d'une vue basee sur PAYMENT
CREATE VIEW V_STAT_PAIEMENTS AS
SELECT STAFF_ID, SUM(AMOUNT) AS TOTAL_ENCAISSE
FROM SAKILA.PAYMENT
GROUP BY STAFF_ID;
-- RESULTAT ATTENDU : ORA-01031 (ou ORA-01720) : privileges insuffisants.
-- EXPLICATION : les roles sont desactives pendant la creation d'un objet
-- stocke (vue, procedure, package). Seuls les privileges DIRECTS du
-- createur comptent. C'est le principe des droits du definisseur
-- (definer's rights).

-- 5c. Connexion sakila : SOLUTION, droit direct (hors role)
GRANT SELECT ON PAYMENT TO MANAGER1;

-- 5d. Connexion manager1 : meme commande, succes cette fois
CREATE VIEW V_STAT_PAIEMENTS AS
SELECT STAFF_ID, SUM(AMOUNT) AS TOTAL_ENCAISSE
FROM SAKILA.PAYMENT
GROUP BY STAFF_ID;

SELECT * FROM V_STAT_PAIEMENTS;


/* =====================================================================
   VERIFICATION GLOBALE
   Connexion : Oracle-xe (SYSTEM)
   ===================================================================== */

-- Roles accordes a chaque utilisateur
SELECT grantee, granted_role
FROM   dba_role_privs
WHERE  grantee IN ('SAKILA_ADMIN', 'MANAGER1', 'STAFF_MIKE');

-- Droits portes par les roles
SELECT grantee, table_name, privilege
FROM   dba_tab_privs
WHERE  grantee LIKE 'ROLE_%'
ORDER  BY grantee, table_name;



