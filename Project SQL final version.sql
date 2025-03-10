#PHASE 1: EXPLORATION DES DONNEES 
-- Affficher le nom des tableaux 
show tables;

-- On vérifie le nombre des customers (clients) que nous avons dans la base de données: 122
SELECT 
  distinct COUNT(customerNumber) 
FROM 
  customers;
  
-- On vérifie le nombre d'employés que nous avons: 23 employées 
SELECT 
  distinct COUNT(employeeNumber) 
FROM 
  employees;
  
-- On vérfie le nombre d'entreprises avec lesquelles chaque employé travaille et les entrseprises qui sont liées à chaque employee et on voit que Castillo Pamela est l'employée avec le plus de clients (10), suivie de Jones Barry et de Vanauf Goerge
SELECT 
  e.lastName, 
  e.firstName, 
  count(c.salesRepEmployeeNumber) as number_of_customer_per_employee 
FROM 
  customers c 
  JOIN employees e on c.salesRepEmployeeNumber = e.employeeNumber 
GROUP BY 
  e.lastName, 
  e.firstName 
ORDER BY 
  number_of_customer_per_employee DESC;
  
-- SALES KPIs
-- QUERY 1: Le revenu généré par chaque client
SELECT 
  c.customerNumber, 
  c.customerName, 
  o.orderNumber, 
  SUM(od.quantityOrdered * priceEach) as revenue 
FROM 
  customers c 
  JOIN orders o ON c.customerNumber = o.customerNumber 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
GROUP BY 
  c.customerNumber, 
  c.customerName, 
  o.orderNumber 
ORDER BY 
  revenue DESC;
  
-- QUERY 2: 
-- Le nombre de vente par année 
SELECT 
  YEAR (shippedDate) as annee, 
  COUNT(*) as nb_commandes 
FROM 
  orders 
WHERE 
  status = 'Shipped' 
  OR 'shipped' 
GROUP BY 
  annee;
  
-- le volume de ventes par année avec quantity ordered 
CREATE VIEW sales_per_year_quantity AS 
SELECT 
  YEAR (o.shippedDate) as annee, 
  SUM(od.quantityOrdered) as quantite 
FROM 
  orders o 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
WHERE 
  status = 'Shipped' 
  OR 'shipped' 
GROUP BY 
  annee 
ORDER BY 
  annee ASC;
  
-- Le revenu total par année 
CREATE VIEW sales_per_year AS 
SELECT 
  YEAR (o.shippedDate) as annee, 
  SUM(
    od.quantityOrdered * od.priceEach
  ) as revenue_par_an 
FROM 
  orders o 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
WHERE 
  status = 'Shipped' 
  OR 'shipped' 
GROUP BY 
  annee 
ORDER BY 
  annee ASC;
  
-- le nombre de vente par client par annéee en terme de volumes 
SELECT 
  YEAR (o.shippedDate) as annee, 
  SUM(od.quantityOrdered) as volume, 
  customerName 
FROM 
  orders o 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
  JOIN customers c ON c.customerNumber = o.customerNumber 
WHERE 
  status = 'Shipped' 
  OR 'shipped' 
GROUP BY 
  customerName, 
  annee 
ORDER BY 
  annee ASC;
  
-- le nombre de vente par client par annéee en terme de revenue 
SELECT 
  YEAR (o.shippedDate) as annee, 
  SUM(od.quantityOrdered * priceEach) as revenue, 
  customerName 
FROM 
  orders o 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
  JOIN customers c ON c.customerNumber = o.customerNumber 
WHERE 
  status = 'Shipped' 
  OR 'shipped' 
GROUP BY 
  customerName, 
  annee 
ORDER BY 
  annee ASC;
  
-- Obtenir les lignes de produits qui sont les plus vendues: les plus vendus sont le classic cars, le vintage cars et les motorcycles 
CREATE VIEW sales_by_productline AS 
SELECT 
  p.productLine, 
  SUM(od.quantityOrdered) as volume 
FROM 
  products p 
  JOIN orderdetails od ON p.productcode = od.productcode 
GROUP BY 
  p.productLine 
ORDER BY 
  volume DESC;
  
-- En utilisant la requête précédente, on va trouver le pourcentage que représente chacune par rapport au total 
SELECT 
  productLine, 
  volume, 
  volume / SUM(volume) OVER () AS percentage_of_total 
FROM 
  sales_by_productline 
ORDER BY 
  percentage_of_total DESC;
  
-- Les commandes par pays
SELECT 
  c.country, 
  SUM(od.quantityOrdered) as volume 
FROM 
  customers c 
  JOIN orders o ON c.customerNumber = o.customerNumber 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
GROUP BY 
  c.country 
ORDER BY 
  volume DESC;
SELECT 
  c.country, 
  SUM(od.quantityOrdered) as volume 
FROM 
  customers c 
  JOIN orders o ON c.customerNumber = o.customerNumber 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
WHERE 
  o.status = 'shipped' 
GROUP BY 
  c.country 
ORDER BY 
  volume DESC;
  
-- Maintenant on fait la même chose avec le revenu au lieu du volume de ventes
SELECT 
  c.country, 
  SUM(
    od.quantityOrdered * od.priceEach
  ) as revenue 
FROM 
  customers c 
  JOIN orders o ON c.customerNumber = o.customerNumber 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
WHERE 
  o.status = 'shipped' 
GROUP BY 
  c.country 
ORDER BY 
  revenue DESC;
  
-- Les lignes de produit que chaque pays commande le plus
CREATE VIEW ranked_products AS 
SELECT 
  c.country, 
  p.productline, 
  SUM(od.quantityOrdered), 
  RANK() OVER (
    PARTITION BY c.country 
    ORDER BY 
      SUM(od.quantityOrdered) DESC
  ) AS rnk 
FROM 
  customers c 
  JOIN orders o ON o.customerNumber = c.customerNumber 
  JOIN orderdetails od ON od.orderNumber = o.orderNumber 
  JOIN products p ON p.productCode = od.productCode 
GROUP BY 
  c.country, 
  p.productLine;
  
SELECT 
  country, 
  max(
    CASE WHEN rnk = 1 THEN productline END
  ) AS most_ordered_product1, 
  max(
    CASE WHEN rnk = 2 THEN productline END
  ) AS most_ordered_product2, 
  max(
    CASE WHEN rnk = 3 THEN productline END
  ) AS most_ordered_product3 
FROM 
  ranked_products 
WHERE 
  rnk <= 3 
GROUP BY 
  country;
  
-- Compter le nombre d'ordres qui n'ont pas lieu et on voit qu'ils sont au nombre de 6 
SELECT 
  COUNT(status) 
FROM 
  orders 
WHERE 
  status = 'cancelled';
-- Identify consumers that cancel the most orders -> On ne trouve rien d'alarmant 
SELECT 
  c.customerName, 
  COUNT(o.status) as number_canceled_orders 
FROM 
  customers c 
  JOIN orders o ON c.customerNumber = o.customerNumber 
WHERE 
  status = 'cancelled' 
GROUP BY 
  c.customerName 
ORDER BY 
  number_canceled_orders ASC;
  
-- Faire requête qui prend la différence entre MSPR et le buy price 
SELECT 
  productline, 
  SUM(MSRP - buyprice) as marge 
FROM 
  products 
GROUP BY 
  productLine 
ORDER BY 
  marge DESC;
  
-- On veut voir le lien entre les quantités qui existent dans l'inventaire et les quantités vendues 
SELECT 
  p.productline, 
  SUM(od.quantityOrdered), 
  SUM(DISTINCT p.quantityInStock) 
FROM 
  products p 
  JOIN orderdetails od ON p.productCode = od.productCode 
  JOIN orders o ON od.orderNumber = o.orderNumber 
WHERE 
  o.status = 'Shipped' 
GROUP BY 
  p.productLine 
ORDER BY 
  SUM(od.quantityOrdered) DESC;



-- Creation de views pour structurer les données avant de les importer sur PowerBI
CREATE VIEW Fact_Sales AS 
SELECT 
  o.orderNumber, 
  o.customerNumber, 
  YEAR(o.shippedDate) AS Year, 
  MONTH(o.shippedDate) AS Month, 
  SUM(
    od.quantityOrdered * od.priceEach
  ) AS Revenue, 
  SUM(od.quantityOrdered) AS Quantity_Sold 
FROM 
  orders o 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
WHERE 
  o.status = 'Shipped' 
GROUP BY 
  o.orderNumber, 
  o.customerNumber, 
  YEAR(o.shippedDate), 
  MONTH(o.shippedDate);
CREATE VIEW Dim_Customers AS 
SELECT 
  customerNumber AS CustomerID, 
  customerName, 
  country, 
  city, 
  state, 
  creditLimit 
FROM 
  customers;
CREATE VIEW Dim_Products AS 
SELECT 
  productCode AS ProductID, 
  productName, 
  productLine, 
  buyPrice, 
  MSRP 
FROM 
  products;
CREATE VIEW Dim_Time AS 
SELECT 
  DISTINCT YEAR(shippedDate) AS Year, 
  MONTH(shippedDate) AS Month, 
  shippedDate AS Date 
FROM 
  orders 
WHERE 
  shippedDate IS NOT NULL;
CREATE 
OR REPLACE VIEW Fact_Sales AS 
SELECT 
  o.orderNumber, 
  o.customerNumber, 
  YEAR(o.shippedDate) AS Year, 
  MONTH(o.shippedDate) AS Month, 
  SUM(
    od.quantityOrdered * od.priceEach
  ) AS Revenue, 
  SUM(od.quantityOrdered) AS Quantity_Sold 
FROM 
  orders o 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
WHERE 
  o.status = 'Shipped' 
GROUP BY 
  o.orderNumber, 
  o.customerNumber, 
  YEAR(o.shippedDate), 
  MONTH(o.shippedDate);
CREATE 
OR REPLACE VIEW FACT_TABLE_ANALYSIS AS 
SELECT 
  addressLine1, 
  addressLine2, 
  city, 
  state, 
  postalCode, 
  country, 
  o.orderNumber, 
  c.customerNumber, 
  p.productCode, 
  orderDate, 
  shippedDate, 
  requiredDate, 
  orderLineNumber, 
  quantityOrdered, 
  priceEach, 
  MSRP, 
  buyPrice, 
  quantityInStock, 
  creditLimit, 
  e.employeeNumber 
FROM 
  orders o 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
  JOIN products p ON p.productCode = od.productCode 
  JOIN customers c ON c.customerNumber = o.customerNumber 
  JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber;
CREATE 
OR REPLACE VIEW product_dimension AS 
SELECT 
  productCode, 
  productName, 
  productLine, 
  productVendor, 
  quantityInStock 
FROM 
  products;
-- CREATE VIEW ORDER_DIMENSION as 
SELECT 
  o.orderNumber, 
  status, 
  orderLineNumber 
FROM 
  orders o 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber 
GROUP BY 
  o.orderNumber, 
  status, 
  orderLineNumber;
SELECT 
  DISTINCT o.orderNumber, 
  o.status 
FROM 
  orders o 
  JOIN orderdetails od ON o.orderNumber = od.orderNumber;
CREATE VIEW LOCATION_DIMENSION AS 
SELECT 
  addressline1, 
  addressline2, 
  city, 
  state, 
  postalCode, 
  country 
FROM 
  customers;
CREATE VIEW TIME_DIMENSION AS 
SELECT 
  orderDate, 
  requiredDate, 
  shippedDate 
FROM 
  orders;
CREATE VIEW CUSTOMER_DIMENSION AS 
SELECT 
  customerNumber, 
  customerName 
FROM 
  customers;
CREATE VIEW EMPLOYEE_DIMENSION AS 
SELECT 
  employeeNumber, 
  lastName, 
  firstName, 
  jobTitle, 
  city, 
  state, 
  country 
FROM 
  employees e 
  JOIN offices o ON o.officeCode = e.officecode;
