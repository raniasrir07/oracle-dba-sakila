
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
