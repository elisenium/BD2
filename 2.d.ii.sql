--2.d.ii
--1 Quel est le prix moyen des livres édités par "Algodata Infosystems" ?
SELECT AVG(t.price) as "prix_moyen"
FROM titles t, publishers p
WHERE t.pub_id = p.pub_id
  AND lower(p.pub_name) = 'algodata infosystems';

--2 Quel est le prix moyen des livres écrits par chaque auteur ? (Pour chaque auteur, donnez son
--nom, son prénom et le prix moyen de ses livres.)
--=>La moyenne ne prend pas en compte les valeurs nulles!! t.price IS NOT NULL n'est pas necessaire
SELECT a.au_id, a.au_lname, a.au_fname, AVG(t.price) as "prix_moyen_auteur"
FROM authors a, titleauthor ta, titles t
WHERE a.au_id = ta.au_id
  AND t.title_id = ta.title_id
GROUP BY a.au_id , au_lname, a.au_fname;

--3 Pour chaque livre édité par "Algodata Infosystems", donnez le prix du livre et le nombre d'auteurs.
--pas encore vu
SELECT t.title_id, t.price, COUNT(ta.au_id) as "nombre_auteurs"
FROM publishers p, titles t LEFT OUTER JOIN titleauthor ta
ON t.title_id = ta.title_id
WHERE p.pub_id = t.pub_id
  AND lower(pub_name) = 'algodata infosystems'
GROUP BY t.title_id, t.price;

--4 Pour chaque livre, donnez son titre, son prix, et le nombre de magasins différents où il a été vendu.
-- LEFT OUTER JOIN ICI !! On le mets pas car pas encore vu
SELECT t.title_id, t.title, t.price, COUNT(DISTINCT sd.stor_id) AS "nombre_magasins"
FROM titles t, salesdetail sd
WHERE t.title_id = sd.title_id
GROUP BY t.title_id, t.title, t.price;

SELECT t.title_id, t.title, t.price, COUNT(DISTINCT sd.stor_id) AS "nombre_magasins"
FROM titles t LEFT OUTER JOIN salesdetail sd
ON t.title_id = sd.title_id
GROUP BY t.title_id, t.title, t.price;

--5 Quels sont les livres qui ont été vendus dans plusieurs magasins ?
-- On a pas demandé d'afficher le COUNT donc on le mets pas dans le SELECT
SELECT DISTINCT t.title
FROM titles t, salesdetail sd
WHERE t.title_id = sd.title_id
GROUP BY t.title
HAVING COUNT(DISTINCT sd.stor_id) > 1;

--6 Pour chaque type de livre, donnez le nombre total de livres de ce type ainsi que leur prix moyen.
SELECT t.type, COUNT(t.title_id) AS "nb_livres", AVG(t.price)
FROM titles t
WHERE t.type IS NOT NULL
GROUP BY t.type;

--7 Pour chaque livre, le "total_sales" devrait normalement être égal au nombre total des ventes enregistrées pour ce livre,
-- c'est-à-dire à la somme de toutes les "qty" des détails de vente relatifs à ce livre.
-- Vérifiez que c'est bien le cas en affichant pour chaque livre ces deux valeurs côte à côte, ainsi que l'identifiant du livre.

SELECT t.title_id, t.title, COALESCE(t.total_sales, 0), COALESCE(SUM(sd.qty),0) AS "details_des_ventes"
FROM titles t LEFT OUTER JOIN salesdetail sd
ON t.title_id = sd.title_id
GROUP BY t.title_id, t.title, t.total_sales;

--8 Même question, mais en n'affichant que les livres pour lesquels il y a erreur.
SELECT t.title_id, t.title, t.total_sales, COALESCE(SUM(sd.qty),0) AS "detail_des_ventes"
FROM titles t LEFT OUTER JOIN salesdetail sd
ON t.title_id = sd.title_id
GROUP BY t.title_id, t.title, t.total_sales
HAVING COALESCE(t.total_sales,0) != COALESCE(SUM(sd.qty),0);


--9 Quels sont les livres ayant été écrits par au moins 3 auteurs ?
SELECT t.title, t.title_id --...+le reste
FROM titles t, titleauthor ta
WHERE t.title_id = ta.title_id
GROUP BY t.title, t.title_id --...+le reste
HAVING COUNT(ta.au_id) > 2;

--10 Combien d'exemplaires de livres d'auteurs californiens édités par des éditeurs californiens a- t-on vendus dans
-- des magasins californiens ? (Attention, il y a un piège : si vous le détectez, vous devrez peut-être attendre un
-- chapitre ultérieur avant de pouvoir résoudre correctement cet exercice...)
SELECT SUM(sd.qty)
FROM titles t, salesdetail sd, publishers p, stores st
WHERE t.title_id = sd.title_id
  AND t.pub_id = p.pub_id
  AND sd.stor_id = st.stor_id
  AND p.state = 'CA'
  AND st.state = 'CA'
  AND EXISTS(SELECT *
             FROM titleauthor ta, authors au
             WHERE ta.au_id = au.au_id
               AND au.state = 'CA'
               AND t.title_id = ta.title_id);