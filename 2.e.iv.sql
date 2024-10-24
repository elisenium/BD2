--2.e.iv
--1 Quel est le livre le plus cher publié par l'éditeur "Algodata Infosystems" ?
SELECT t.title_id, t.title, t.price
FROM titles t, publishers p
WHERE t.pub_id = p.pub_id
  AND p.pub_name = 'Algodata Infosystems'
  AND t.price IN (SELECT MAX(ti.price)
                 FROM titles ti
                 WHERE ti.pub_id = p.pub_id);

SELECT t.title_id, t.title, t.price
FROM titles t, publishers p
WHERE t.pub_id = p.pub_id
  AND p.pub_name = 'Algodata Infosystems'
  AND t.price = (SELECT MAX(ti.price)
                 FROM titles ti
                 WHERE ti.pub_id = p.pub_id);

--2 Quels sont les livres qui ont été vendus dans plusieurs magasins ?
SELECT t.title_id, t.title
FROM titles t
WHERE t.title_id IN (SELECT sd1.title_id
                     FROM salesdetail sd1, salesdetail sd2
                     WHERE sd1.stor_id <> sd2.stor_id
                     AND sd1.title_id = sd2.title_id);

SELECT t.title_id, t.title
FROM titles t, salesdetail sd
WHERE t.title_id = sd.title_id
GROUP BY t.title_id, t.title
HAVING COUNT(DISTINCT sd.stor_id) > 1;

--3 Quels sont les livres dont le prix est supérieur à une fois et demi le prix moyen des livres du même type ?
SELECT t.title_id, t.title
FROM titles t
WHERE t.price > (SELECT 1.5 * AVG(t2.price)
                 FROM titles t2
                 WHERE t.type = t2.type);

SELECT t.title_id, t.title
FROM titles t
WHERE t.price > 1.5 * (SELECT AVG(t2.price)
                 FROM titles t2
                 WHERE t.type = t2.type);

--4 Quels sont les auteurs qui ont écrit un livre (au moins), publié par un éditeur localisé dans le même état ?
--DISTINCT car l'auteur peut avoir écrit plusieurs livres pour le même éditeur
SELECT DISTINCT a.au_id, a.au_fname, a.au_lname
FROM authors a
INNER JOIN titleauthor ta
    ON a.au_id = ta.au_id
INNER JOIN titles t
    ON t.title_id = ta.title_id
INNER JOIN publishers p
    ON p.pub_id = t.pub_id
WHERE p.state = a.state;

--5 Quels sont les éditeurs qui n'ont rien édité ?
--solution 1
SELECT p.pub_id, p.pub_name
FROM publishers p
WHERE p.pub_id NOT IN (SELECT t.pub_id
                       FROM titles t);

--solution 2
SELECT p.pub_id, p.pub_name
FROM publishers p
WHERE NOT EXISTS(SELECT *
                 FROM titles t
                 WHERE p.pub_id = t.pub_id);

--solution 3
SELECT p.pub_id, p.pub_name
FROM publishers p LEFT JOIN titles t
    ON p.pub_id = t.pub_id
GROUP BY p.pub_id, p.pub_name
HAVING COUNT(t.title_id) = 0;

--6 Quel est l'éditeur qui a édité le plus grand nombre de livres ?
SELECT p.pub_id, p.pub_name
FROM publishers p, titles t
WHERE p.pub_id = t.pub_id
GROUP BY p.pub_id, p.pub_name
HAVING COUNT(t.title_id) >= ALL (SELECT COUNT(ti.title_id)
                                FROM titles ti
                                GROUP BY ti.pub_id);

SELECT p.*
FROM publishers p
WHERE (SELECT COUNT(*)
       FROM titles t
       WHERE t.pub_id = p.pub_id) >= ALL (SELECT COUNT(*)
                                          FROM publishers p1, titles t1
                                          WHERE p1.pub_id = t1.pub_id
                                          GROUP BY p1.pub_id);

--7 Quels sont les éditeurs dont on n'a vendu aucun livre ?
-- OK d'utiliser l'* ici car ça renvoie un booléen
SELECT p.pub_id, p.pub_name
FROM publishers p
WHERE NOT EXISTS (SELECT *
                  FROM titles t, salesdetail sd
                  WHERE t.title_id = sd.title_id
                    AND p.pub_id = t.pub_id);

--Correction
SELECT p.pub_id, p.pub_name
FROM publishers p
WHERE p.pub_id NOT IN (SELECT t.pub_id
                       FROM titles t, salesdetail sd
                       WHERE t.title_id = sd.title_id);

--8 Quels sont les différents livres écrits par des auteurs californiens, publiés par des éditeurs
--californiens, et qui n'ont été vendus que dans des magasins californiens ?
SELECT DISTINCT t.title_id, t.title
FROM titles t, publishers p, authors a, titleauthor ta
WHERE p.pub_id = t.pub_id
  AND a.au_id = ta.au_id
  AND ta.title_id = t.title_id
  AND a.state = 'CA'
  AND p.state = 'CA'
  AND NOT EXISTS (SELECT *
                  FROM salesdetail sd, stores st
                  WHERE sd.stor_id = st.stor_id
                    AND st.state != 'CA'
                    AND t.title_id = sd.title_id);

--9 Quel est le titre du livre vendu le plus récemment ? (S'il a des ex-aequo, donnez-les tous.)
SELECT DISTINCT t.title_id, t.title
FROM titles t, salesdetail sd, sales s
WHERE t.title_id = sd.title_id
  AND s.ord_num = sd.ord_num
  AND s.stor_id = sd.stor_id
  AND s.date = (SELECT MAX(s2.date)
                FROM sales s2);

--10 Quels sont les magasins où l'on a vendu (au moins) tous les livres vendus par le magasin "Bookbeat" ?
--noter la correction!!
SELECT st.stor_id, st.stor_name
FROM stores st LEFT OUTER JOIN salesdetail sd
ON st.stor_id = sd.stor_id
AND sd.title_id IN (SELECT sd2.title_id
                    FROM salesdetail sd2, stores st2
                    WHERE sd2.stor_id = st2.stor_id
                    AND st2.stor_name = 'Bookbeat')
GROUP BY st.stor_id, st.stor_name
HAVING COUNT(DISTINCT sd.title_id) = (SELECT COUNT(DISTINCT sd2.title_id)
                                    FROM salesdetail sd2, stores st2
                                    WHERE sd2.stor_id = st2.stor_id
                                    AND st2.stor_name = 'Bookbeat');

--11 Quelles sont les villes de Californie où l'on peut trouver un auteur, mais aucun magasin ?
SELECT DISTINCT a.city
FROM authors a
WHERE a.state = 'CA'
  AND a.city IS NOT NULL
  AND a.city NOT IN (SELECT st.city
                     FROM stores st
                     WHERE st.city IS NOT NULL
                       AND st.state = 'CA');

--12 Quels sont les éditeurs localisés dans la ville où il y a le plus d'auteurs ?
SELECT p.pub_id, p.pub_name, p.city
FROM publishers p
WHERE (p.city, p.state) IN (SELECT a.city, a.state
                            FROM authors a
                            WHERE a.city IS NOT NULL
                            GROUP BY a.city, a.state
                            HAVING COUNT(a.au_id) >= ALL (SELECT COUNT(au.au_id)
                                                          FROM authors au
                                                          GROUP BY au.city, au.state));

--Solution
SELECT p.pub_id, p.pub_name, p.city
FROM publishers p
WHERE p.city IN (SELECT a.city
                FROM authors a
                WHERE a.city IS NOT NULL
                GROUP BY a.city
                HAVING COUNT(a.au_id) >= ALL (SELECT COUNT(au.au_id)
                                              FROM authors au
                                              GROUP BY au.city));

--13 Donnez les titres des livres dont tous les auteurs sont californiens.
--=> DISTINCT car titleauthor !!!
SELECT DISTINCT t.title_id, t.title
FROM titles t, titleauthor ta
WHERE t.title_id = ta.title_id
AND 'CA' = ALL (SELECT a.state
                FROM authors a
                WHERE a.au_id = ta.au_id);

--14 Quels sont les livres qui n'ont été écrits par aucun auteur californien ?
SELECT t.title_id, t.title
FROM titles t
WHERE t.title_id NOT IN (SELECT ta.title_id
                         FROM titleauthor ta, authors a
                         WHERE ta.au_id = a.au_id
                           AND a.state = 'CA');

--15 Quels sont les livres qui n'ont été écrits que par un seul auteur ?
--OK par le prof
SELECT t.title_id, t.title
FROM titles t, titleauthor ta
WHERE t.title_id = ta.title_id
GROUP BY t.title_id, t.title
HAVING COUNT(ta.au_id) = 1;

--Autre solution
SELECT t.title_id, t.title
FROM titles t
WHERE 1 = (SELECT COUNT(ta.au_id)
           FROM titleauthor ta
           WHERE ta.title_id = t.title_id);

--16 Quels sont les livres qui n'ont qu'un auteur, et tels que cet auteur soit californien ?
SELECT t.title_id, t.title
FROM titles t, titleauthor ta, authors a
WHERE t.title_id = ta.title_id
AND ta.au_id = a.au_id
AND a.state = 'CA'
GROUP BY t.title_id, t.title
HAVING COUNT(ta.au_id) = 1;

SELECT DISTINCT t.title_id, t.title
FROM titles t
WHERE 1 = (SELECT COUNT(ta.au_id)
                FROM titleauthor ta, authors a
                WHERE t.title_id = ta.title_id
                AND a.au_id = ta.au_id
                AND a.state = 'CA');