--2.b.iv
--1 Affichez la liste de tous les livres, en indiquant pour chacun son titre, son prix et le nom de son éditeur.
SELECT t.title_id, t.title, t.price, pub.pub_name
FROM titles t, publishers pub
WHERE t.pub_id = pub.pub_id;

--2 Affichez la liste de tous les livres de psychologie, en indiquant pour chacun son titre, son prix et
-- le nom de son éditeur.
SELECT t.title_id, t.title, t.price, pub.pub_name
FROM titles t, publishers pub
WHERE t.type = 'psychology'
  AND t.pub_id = pub.pub_id;

--3 Quels sont les auteurs qui ont effectivement écrit un (des) livre(s) présent(s) dans la DB ? Donnez leurs noms et prénoms.
-- => Il faut un DISTINCT car un auteur peut avoir écrit plusieurs titres différents
SELECT DISTINCT au.au_lname, au_fname
FROM authors au, titleauthor ta
WHERE au.au_id = ta.au_id;

--4 Dans quels Etats y a-t-il des auteurs qui ont effectivement écrit un (des) livre(s) présent(s) dans la DB ?
SELECT DISTINCT au.state
FROM authors au, titleauthor ta
WHERE au.au_id = ta.au_id
  AND au.state IS NOT NULL;

--5 Donnez les noms et adresses des magasins qui ont commandé des livres en novembre 1991.
-- => DISTINCT car s'il y a 2 ventes en novembre 1991, il y aura des doublons
SELECT DISTINCT st.stor_name, st.stor_address
FROM stores st, sales s
WHERE st.stor_id = s.stor_id
  AND 11 = date_part('month', s.date)
  AND 1991 = date_part('year', s.date);

--6 Quels sont les livres de psychologie de moins de 20 $ édités par des éditeurs dont le nom ne
-- commence pas par "Algo" ?
SELECT t.title_id, t.title
FROM titles t, publishers pub
WHERE t.pub_id = pub.pub_id
  AND t.type = 'psychology'
  AND t.price < 20
  AND lower(pub.pub_name) NOT LIKE 'algo%'; --si on mets tout en minuscule, on met lower, sinon, upper

--7 Donnez les titres des livres écrits par (au moins) un auteur californien (state = "CA").
-- => DISTINCT car un titre pourrait avoir plusieurs auteurs californiens
SELECT DISTINCT t.title_id, t.title
FROM titleauthor ta, authors au, titles t
WHERE ta.au_id = au.au_id
  AND t.title_id = ta.title_id
  AND au.state = 'CA';

--8 Quels sont les auteurs qui ont écrit un livre (au moins) publié par un éditeur californien ?
-- => DISTINCT car un auteur peut avoir plusieurs livres édités par un auteur californien
SELECT DISTINCT au.au_id, au.au_lname, au.au_fname
FROM authors au, publishers pub, titles t, titleauthor ta
WHERE au.au_id = ta.au_id
  AND pub.pub_id = t.pub_id
  AND t.title_id = ta.title_id
  AND pub.state = 'CA';

--9 Quels sont les auteurs qui ont écrit un livre (au moins) publié par un éditeur localisé dans leur Etat ?
-- => DISTINCT car si un auteur a écris plusieurs livre avec un éditeurs localisé dans le même état que lui
SELECT DISTINCT au.au_id, au.au_lname, au.au_fname
FROM authors au, publishers pub, titles t, titleauthor ta
WHERE au.au_id = ta.au_id
  AND pub.pub_id = t.pub_id
  AND t.title_id = ta.title_id
  AND pub.state = au.state;

--10 Quels sont les éditeurs dont on a vendu des livres entre le 1/11/1990 et le 1/3/1991 ?
--=> Toujours mettre les deux conditions de jointures!!!
SELECT DISTINCT pub.pub_id, pub.pub_name, pub.city, pub.state
FROM publishers pub, titles t, salesdetail sd, sales s
WHERE pub.pub_id = t.pub_id
  AND sd.title_id = t.title_id
  AND s.stor_id = sd.stor_id
  AND s.ord_num = sd.ord_num
  AND s.date >= '1990-11-01'
  AND s.date <= '1991-03-01';

--11 Quels magasins ont vendu des livres contenant le mot "cook" (ou "Cook") dans leur titre ?
-- Utilisation du SIMILAR TO !!
SELECT DISTINCT st.stor_id, st.stor_name
FROM salesdetail sd, stores st, titles t
WHERE st.stor_id = sd.stor_id
  AND t.title_id = sd.title_id
  AND t.title SIMILAR TO '%[cC]ook%';

--12 Y a-t-il des paires de livres publiés par le même éditeur à la même date ?
-- => Pas obligé de passer par la table éditeurs car il y a pub_id
SELECT DISTINCT t1.title, t2.title
FROM titles t1, titles t2
WHERE t1.pub_id = t2.pub_id
  AND t1.pubdate = t2.pubdate
  AND t1.title_id < t2.title_id; --éviter la duplication !! l'un des 2 doit être plus petit que l'autre

--13 Y a-t-il des auteurs n'ayant pas publié tous leurs livres chez le même éditeur ?
SELECT a.*
FROM authors a
WHERE 1 < (SELECT count(DISTINCT pub_id)
           FROM titles t, titleauthor ta
           WHERE t.title_id = ta.title_id);

--Rajouter autre solution

--14 Y a-t-il des livres qui ont été vendus avant leur date de parution ?
SELECT DISTINCT t.title_id, t.title
FROM sales sa, salesdetail sd, titles t
WHERE sa.stor_id = sd.stor_id
  AND sa.ord_num = sd.ord_num
  AND t.title_id = sd.title_id
  AND sa.date < t.pubdate;

--15 Quels sont les magasins où l'on a vendu des livres écrits par Anne Ringer ?
SELECT DISTINCT st.stor_id, st.stor_name
FROM stores st, salesdetail sd, authors a, titleauthor ta
WHERE st.stor_id = sd.stor_id
  AND ta.title_id = sd.title_id
  AND a.au_id = ta.au_id
  AND a.au_fname = 'Anne'
  AND a.au_lname = 'Ringer';

--16 Quels sont les Etats où habite au moins un auteur dont on a vendu des livres en Californie en février 1991 ?
SELECT DISTINCT a.state
FROM stores st, salesdetail sd, authors a, titleauthor ta, sales sa
WHERE sd.stor_id = sa.stor_id
  AND st.stor_id = sa.stor_id
  AND sd.ord_num = sa.ord_num
  AND sd.title_id = ta.title_id
  AND a.au_id = ta.au_id
  AND st.state = 'CA'
  AND 1991 = date_part('y', sa.date)
  AND 02 = date_part('month', sa.date)
  AND a.state IS NOT NULL;

--17 Y a-t-il des paires de magasins situés dans le même Etat, où l'on a vendu des livres du même auteur ?
SELECT DISTINCT st1.stor_id, st2.stor_id, st1.stor_name, st2.stor_name
FROM stores st1, stores st2, salesdetail sd1, salesdetail sd2, titleauthor ta1, titleauthor ta2
WHERE st1.stor_id = sd1.stor_id
  AND st2.stor_id = sd2.stor_id
  AND ta1.title_id = sd1.title_id
  AND ta2.title_id = sd2.title_id
  AND st1.state = st2.state
  AND st1.stor_name < st2.stor_name
  AND ta1.au_id = ta2.au_id;

--18 Trouvez les paires de co-auteurs.
-- => DISTINCT CAR LES AUTEURS PEUVENT AVOIR ECRITS PLUSIEURS LIVRES ENSEMBLE
SELECT DISTINCT a1.au_lname, a2.au_lname
FROM authors a1, authors a2, titleauthor ta1, titleauthor ta2
WHERE a1.au_id = ta1.au_id
  AND a2.au_id = ta2.au_id
  AND a1.au_id < a2.au_id
  AND ta1.title_id = ta2.title_id;

--19 Pour chaque détail de vente, donnez le titre du livre, le nom du magasin, le prix unitaire, le
--nombre d'exemplaires vendus, le montant total et le montant de l'éco-taxe totale (qui s'élève à 2% du chiffre d'affaire).
SELECT st.stor_id, sd.ord_num, t.title_id, st.stor_name, t.price, sd.qty, t.price * sd.qty AS montant_total,
       t.price * sd.qty * 0,02 AS montant_eco_taxe
FROM salesdetail sd, titles t, stores st
WHERE sd.title_id = t.title_id
  AND sd.stor_id = st.stor_id;
