--2.g.ii
--1 Donnez la liste des magasins, en ordre alphabétique, en mentionnant pour chacun le chiffre d'affaire total.
SELECT st.stor_id, st.stor_name, SUM(t.price * sd.qty) AS "chiffre_affaire_total"
FROM stores st, salesdetail sd, titles t
WHERE st.stor_id = sd.stor_id
  AND sd.title_id = t.title_id
GROUP BY st.stor_id, st.stor_name
ORDER BY st.stor_name;

--2 Donnez la liste des magasins, en mentionnant pour chacun le chiffre d'affaire total. Classez cette liste par
-- ordre décroissant de chiffre d'affaire.
SELECT st.stor_id, st.stor_name, SUM(t.price * sd.qty) AS "chiffre_affaire_total"
FROM stores st, salesdetail sd, titles t
WHERE st.stor_id = sd.stor_id
  AND sd.title_id = t.title_id
GROUP BY st.stor_id, st.stor_name
ORDER BY SUM(t.price * sd.qty) DESC;

--3 Donnez la liste des livres de plus de $20, classés par type, en donnant pour chacun son type, son titre, le nom
-- de son éditeur et son prix.
SELECT t.type, t.title, p.pub_name, t.price
FROM titles t, publishers p
WHERE t.pub_id = p.pub_id
  AND t.price > 20
GROUP BY t.type, t.title, p.pub_name, t.price;

--4 Donnez la liste des livres de plus de $20, classés par type, en donnant pour chacun son type, son titre, les noms
-- de ses auteurs et son prix.
SELECT t.title_id, title, type,price, a.au_id,a.au_lname, a.au_fname
FROM titles t LEFT OUTER JOIN titleauthor ta
ON t.title_id = ta.title_id LEFT OUTER JOIN  authors a
ON ta.au_id = a.au_id
AND t.price > 20
ORDER BY t.type;

--5 Quelles sont les villes de Californie où l'on peut trouver un auteur et/ou un éditeur, mais aucun magasin ?
SELECT p.city
FROM publishers p
WHERE p.state = 'CA'
UNION (SELECT a.city FROM authors a WHERE a.state = 'CA')
EXCEPT (SELECT st.city FROM stores st WHERE st.state = 'CA');

--6 Donnez la liste des auteurs en indiquant pour chacun, outre son nom et son prénom, le nombre de livres de plus de
-- 20 $ qu'il a écrits. Classez cela par ordre décroissant de nombre de livres, et, en cas d'ex aequo, par ordre
-- alphabétique. N'oubliez pas les auteurs qui n'ont écrit aucun livre de plus de 20 $ !
SELECT a.au_lname, a.au_fname, COUNT(t.title_id) AS nbrLivres
FROM authors a LEFT OUTER JOIN  titleauthor ta
ON a.au_id = ta.au_id LEFT OUTER JOIN titles t
ON ta.title_id = t.title_id
AND t.price > 20
GROUP BY a.au_lname, a.au_fname
ORDER BY nbrLivres DESC , a.au_lname, a.au_fname;