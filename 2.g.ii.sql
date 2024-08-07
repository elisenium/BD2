--1 Donnez la liste des magasins, en ordre alphabétique, en mentionnant pour chacun le chiffre d'affaire total.
SELECT st.stor_id, st.stor_name, SUM(t.price * sd.qty) AS "chiffre_affaire_total"
FROM stores st, salesdetail sd, titles t
WHERE st.stor_id = sd.stor_id
  AND sd.title_id = t.title_id
GROUP BY st.stor_id, st.stor_name
ORDER BY stor_name;

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
SELECT t.type, t.title, p.pub_name, a.au_fname, a.au_lname, t.price
FROM titles t, publishers p, titleauthor ta, authors a
WHERE t.pub_id = p.pub_id
  AND ta.title_id = t.title_id
  AND a.au_id = ta.au_id
GROUP BY t.type, t.title, p.pub_name, a.au_fname, a.au_lname, t.price;

--5 Quelles sont les villes de Californie où l'on peut trouver un auteur et/ou un éditeur, mais aucun magasin ?
SELECT p.city
FROM publishers p
WHERE p.state = 'CA'
UNION (SELECT a.city FROM authors a WHERE a.state = 'CA')
EXCEPT (SELECT st.city FROM stores st WHERE st.state = 'CA')

--6 Donnez la liste des auteurs en indiquant pour chacun, outre son nom et son prénom, le nombre de livres de plus de
-- 20 $ qu'il a écrits. Classez cela par ordre décroissant de nombre de livres, et, en cas d'ex aequo, par ordre
-- alphabétique. N'oubliez pas les auteurs qui n'ont écrit aucun livre de plus de 20 $ !
(SELECT a.au_fname, a.au_lname, count(t.title_id)
FROM authors a, titles t, titleauthor ta
WHERE a.au_di = ta.au_id AND ta.title_id = t.title_id
AND t.price > 20
GROUP BY a.au_fname, a.au_lname)
UNION ALL
(SELECT a.au_fname, a.au_lname
FROM authors a WHERE a.au_id NOT IN (SELECT ta.au_id
									FROM titleauthor ta2, titles t2
									WHERE ta2.title_id = t2.title_id
									AND t2.price > 20)
)
ORDER BY 3 DESC,1)