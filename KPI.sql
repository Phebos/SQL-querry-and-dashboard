/*set la langue de sortie en fr pour les mois*/
SET lc_time_names = 'fr_FR';
use toys_and_models

/*1. Liste des catégories de produit et nombre de produit par catégorie*/
SELECT ROW_NUMBER() OVER() AS Num, p.productLine as Categ, count(p.productCode)
FROM products p
GROUP BY p.productLine
UNION ALL
SELECT count(DISTINCT(p.productLine))+1, 'Total', count(p.productCode)
FROM products p;


/*2. Indique pour chaque catégorie le nombre vendue par mois et 
compare avec l'année précédente les chiffres globaux du même mois*/
SET lc_time_names = 'fr_FR';
SELECT p.productLine as Categ, DATE_FORMAT(o.orderDate,'%M %Y') as Date, YEAR(o.orderDate) as Year, MONTHNAME(o.orderDate) as Month, SUM(od.quantityOrdered) as Sales, DATE_FORMAT(o.orderDate-INTERVAL 1 YEAR,'%M,%Y') as Date_prev,
COALESCE((SELECT SUM(od.quantityOrdered) FROM orderdetails od JOIN orders o ON od.orderNumber = o.orderNumber JOIN products p ON od.productCode = p.productCode WHERE o.status != 'Cancelled' AND p.productLine = Categ and YEAR(o.orderDate) = Year-1 and MONTHNAME(o.orderDate) = Month),0) as Sales_year_prior,
CONCAT(ROUND((SUM(od.quantityOrdered)
-(SELECT SUM(od.quantityOrdered) FROM orderdetails od JOIN orders o ON od.orderNumber = o.orderNumber JOIN products p ON od.productCode = p.productCode WHERE o.status != 'Cancelled' AND p.productLine = Categ and YEAR(o.orderDate) = Year-1 and MONTHNAME(o.orderDate) = Month))
/(SELECT SUM(od.quantityOrdered) FROM orderdetails od JOIN orders o ON od.orderNumber = o.orderNumber JOIN products p ON od.productCode = p.productCode WHERE o.status != 'Cancelled' AND p.productLine = Categ and YEAR(o.orderDate) = Year-1 and MONTHNAME(o.orderDate) = Month)*100,0),'%') as Taux_de_progression,
MONTH(o.orderDate) as NumMois
FROM orderdetails od
JOIN orders o ON od.orderNumber = o.orderNumber
JOIN products p ON od.productCode = p.productCode
WHERE o.status != 'Cancelled'
GROUP BY p.productLine, Year,Month, Date, Date_prev, NumMois
UNION ALL
SELECT 'Total', DATE_FORMAT(o.orderDate,'%M %Y') as Date, YEAR(o.orderDate) as Year,MONTHNAME(o.orderDate) as Month ,SUM(od.quantityOrdered) as Sales, DATE_FORMAT(o.orderDate-INTERVAL 1 YEAR,'%M,%Y') as Date_prev,
COALESCE((SELECT SUM(od.quantityOrdered) FROM orderdetails od JOIN orders o ON od.orderNumber = o.orderNumber JOIN products p ON od.productCode = p.productCode WHERE o.status != 'Cancelled' AND YEAR(o.orderDate) = Year-1 and MONTHNAME(o.orderDate) = Month),0) as Sales_year_prior,
CONCAT(ROUND((SUM(od.quantityOrdered)
-(SELECT SUM(od.quantityOrdered) FROM orderdetails od JOIN orders o ON od.orderNumber = o.orderNumber JOIN products p ON od.productCode = p.productCode WHERE o.status != 'Cancelled' AND YEAR(o.orderDate) = Year-1 and MONTHNAME(o.orderDate) = Month))
/(SELECT SUM(od.quantityOrdered) FROM orderdetails od JOIN orders o ON od.orderNumber = o.orderNumber JOIN products p ON od.productCode = p.productCode WHERE o.status != 'Cancelled' AND YEAR(o.orderDate) = Year-1 and MONTHNAME(o.orderDate) = Month)*100,0),'%') as Taux_de_progression,
MONTH(o.orderDate) as NumMois
FROM orderdetails od
JOIN orders o ON od.orderNumber = o.orderNumber
JOIN products p ON od.productCode = p.productCode
WHERE o.status != 'Cancelled'
GROUP BY Year,Month, Date, Date_prev, NumMois
ORDER BY Year, FIELD(MONTH,'Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre');


/*3. Marge des catégorie de produit par mois de chaque année*/
SET lc_time_names = 'fr_FR';
SELECT p.productLine as Categ,  DATE_FORMAT(o.orderDate,'%Y/%m') as DateNum, YEAR(o.orderDate) as Year, MONTHNAME(o.orderDate) as Mois, SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) as Marge,
COALESCE((SELECT SUM((od.priceEach - p.buyPrice) * od.quantityOrdered)
FROM orderdetails od
JOIN orders o on o.orderNumber = od.orderNumber
JOIN products p on p.productCode = od.productCode
WHERE   o.status != 'Cancelled' AND MONTHNAME(o.orderDate) = Mois AND YEAR(o.orderDate) = Year-1 AND p.productLine = Categ),0) as Marge_N1
FROM orderdetails od
JOIN orders o on o.orderNumber = od.orderNumber
JOIN products p on p.productCode = od.productCode
WHERE o.status != 'Cancelled'
GROUP BY Categ, Mois, DateNum, Year
UNION ALL
SELECT 'Total', DATE_FORMAT(o.orderDate,'%Y/%m') as DateNum, YEAR(o.orderDate) as Year, MONTHNAME(o.orderDate) as Mois, SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) as Marge_N2,
(SELECT SUM((od.priceEach - p.buyPrice) * od.quantityOrdered)
FROM orderdetails od
JOIN orders o on o.orderNumber = od.orderNumber
JOIN products p on p.productCode = od.productCode
WHERE  o.status != 'Cancelled' AND MONTHNAME(o.orderDate) = Mois AND YEAR(o.orderDate) = Year-1) as Marge_N1
FROM orderdetails od
JOIN orders o on o.orderNumber = od.orderNumber
JOIN products p on p.productCode = od.productCode
WHERE o.status != 'Cancelled'
GROUP BY Mois, DateNum, Year
ORDER BY DateNum, FIELD(Mois,'Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre');


/*Table des dates pour le slicer*/
SET lc_time_names = 'fr_FR';
SELECT DATE_FORMAT(o.orderDate,'%M %Y') as Date, DATE_FORMAT(o.orderDate,'%Y/%m') as DateNum
FROM orders o
GROUP BY Date, DateNum;


/*4. Marge du mois courant en $ et %*/
SET lc_time_names = 'fr_FR';
SELECT p.productLine as Categ, DATE_FORMAT(o.orderDate,'%M %Y') as Date, DATE_FORMAT(o.orderDate,'%Y/%m') as DateNum, MONTHNAME(o.orderDate) as Mois, YEAR(o.orderDate) as Année, SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) as Marge_du_mois, 
CONCAT(ROUND(SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) / (SELECT SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) 
FROM orders o JOIN orderdetails od on o.orderNumber = od.orderNumber JOIN products p on p.productCode = od.productCode
WHERE o.status != 'Cancelled' AND MONTHNAME(o.orderDate) = Mois AND YEAR(o.orderDate) = Année) * 100,1),'%') as Pourcentage_Mdm
FROM orderdetails od
JOIN orders o on o.orderNumber = od.orderNumber
JOIN products p on p.productCode = od.productCode
WHERE  o.status != 'Cancelled'
GROUP BY Categ, Mois, Année, DateNum, Date
UNION ALL
SELECT 'Total',  DATE_FORMAT(o.orderDate,'%M %Y') as Date, DATE_FORMAT(o.orderDate,'%Y/%m') as DateNum, MONTHNAME(o.orderDate) as Mois, YEAR(o.orderDate) as Année, SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) as Marge_du_mois, 
CONCAT(ROUND(SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) / (SELECT SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) 
FROM orders o JOIN orderdetails od on o.orderNumber = od.orderNumber JOIN products p on p.productCode = od.productCode
WHERE o.status != 'Cancelled' AND MONTHNAME(o.orderDate) = Mois AND YEAR(o.orderDate) = Année) * 100,0),'%') as Pourcentage_Mdm
FROM orderdetails od
JOIN orders o on o.orderNumber = od.orderNumber
JOIN products p on p.productCode = od.productCode
WHERE  o.status != 'Cancelled'
GROUP BY Mois, Année, DateNum, Date
ORDER BY DateNum, FIELD(Mois,'Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre');



/*5. Marge moyenne pour chaque categ de produit en %*/
SELECT p.productLine as Categ, CONCAT(ROUND(AVG((od.priceEach - p.buyPrice)/od.priceEach*100),2),' %') as Marge_moy
FROM orderdetails od
JOIN orders o on o.orderNumber = od.orderNumber
JOIN products p on p.productCode = od.productCode
WHERE o.status != 'Cancelled'
GROUP BY p.productLine
UNION ALL
SELECT 'Total',  CONCAT(ROUND(AVG((od.priceEach - p.buyPrice)/od.priceEach*100),2),' %') as Marge_moy
FROM orderdetails od
JOIN orders o on o.orderNumber = od.orderNumber
JOIN products p on p.productCode = od.productCode
WHERE o.status != 'Cancelled';

/*9. Produit phare*/
WITH ProductPopularity AS (
    SELECT p.productLine as Categ, p.productName as Product,
    SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) AS Marge,
    CONCAT(ROUND(SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) / (SELECT SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) FROM orderdetails od
    JOIN orders o on o.orderNumber = od.orderNumber
    JOIN products p on p.productCode = od.productCode
    WHERE o.orderDate BETWEEN CURDATE() - INTERVAL 60 DAY AND CURDATE()) * 100,1),'%')   AS Pourcentage,
    RANK() OVER(PARTITION BY p.productLine ORDER BY SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) DESC) AS MargeRank
    FROM orderdetails od
    JOIN orders o on o.orderNumber = od.orderNumber
    JOIN products p on p.productCode = od.productCode
    WHERE o.orderDate BETWEEN CURDATE() - INTERVAL 60 DAY AND CURDATE()
    GROUP BY Categ, Product
    UNION ALL
    SELECT 'Total', p.productName as Product,
    SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) AS Marge,
    CONCAT(ROUND(SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) / (SELECT SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) FROM orderdetails od
    JOIN orders o on o.orderNumber = od.orderNumber
    JOIN products p on p.productCode = od.productCode
    WHERE o.orderDate BETWEEN CURDATE() - INTERVAL 60 DAY AND CURDATE()) * 100,1),'%')   AS Pourcentage,
    RANK() OVER(ORDER BY SUM((od.priceEach - p.buyPrice) * od.quantityOrdered) DESC) AS MargeRank
    FROM orderdetails od
    JOIN orders o on o.orderNumber = od.orderNumber
    JOIN products p on p.productCode = od.productCode
    WHERE o.orderDate BETWEEN CURDATE() - INTERVAL 60 DAY AND CURDATE()
    GROUP BY Product
)
SELECT Categ, Product, Marge, Pourcentage
FROM ProductPopularity
WHERE MargeRank <=5
ORDER BY Categ, Marge DESC;