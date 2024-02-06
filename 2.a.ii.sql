--2.a.ii
--1 Quels sont les noms des auteurs habitant la ville de Oakland ? rajouter l'id même quand il n'est pas dmdé pour distinguer
SELECT au.au_id, au.au_lname
FROM authors au
WHERE au.city = 'Oakland';

--2 Donnez les noms et adresses des auteurs dont le prénom commence par la lettre "A".
SELECT au.au_id, au.au_lname, au.address
FROM authors au
WHERE upper(au.au_fname) LIKE 'A%';

--3 Donnez les noms et adresses complètes des auteurs qui n'ont pas de numéro de téléphone.
SELECT au.au_lname, au.au_fname, au.address, au.city, au.state, au.country
FROM authors au
WHERE au.phone IS NULL;

--4 Y a-t-il des auteurs californiens dont le numéro de téléphone ne commence pas par "415" ? => plus de SELECT * !!
SELECT au.au_id, au.au_lname, au.au_fname, au.address, au.phone, au.city, au.state, au.country
FROM authors au
WHERE au.state = 'CA' AND au.phone NOT LIKE '415%';

--5 Quels sont les auteurs habitant au Bénélux ? => Pas de distinct!
SELECT au.au_id, au.au_lname, au.au_fname, au.address, au.phone, au.city, au.state, au.country
FROM authors au
WHERE au.country = 'BEL'
   OR au.country = 'NED'
   OR au.country = 'LUX';

--6 Donnez les identifiants des éditeurs ayant publié au moins un livre de type "psychologie" ? => pas besoin de la table éditeurs!!
SELECT DISTINCT t.pub_id
FROM titles t
WHERE t.type = 'psychology';

--7 Donnez les identifiants des éditeurs ayant publié au moins un livre de type "psychologie", si
-- l'on omet tous les livres dont le prix est compris entre 10 et 25 $ ?

SELECT DISTINCT t.pub_id
FROM titles t
WHERE t.type = 'psychology'
  AND (t.price < 10
   OR t.price > 25);

--8 Donnez la liste des villes de Californie où l'on peut trouver un (ou plusieurs) auteur(s)
-- dont le prénom est Albert ou dont le nom finit par "er".
SELECT DISTINCT au.city
FROM authors au
WHERE (lower(au.au_fname) = 'albert'
  OR lower(au.au_lname) = '%er')
  AND au.state = 'CA'
  AND au.city IS NOT NULL;

--9 Donnez tous les couples Etat-pays ("state" - "country") de la table des auteurs, pour lesquels l'Etat est fourni, mais le pays est autre que "USA".
SELECT DISTINCT au.state, au.country
FROM authors au
WHERE au.country != 'USA'
  AND au.state IS NOT NULL
  AND au.country IS NOT NULL;

--10 Pour quels types de livres peut-on trouver des livres de prix inférieur à 15 $ ?
SELECT DISTINCT t.type
FROM titles t
WHERE t.price < 15
  AND t.price IS NOT NULL;
