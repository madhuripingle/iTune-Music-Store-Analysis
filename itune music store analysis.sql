select * from album
select * from customer
select * from artist
select * from customer
select * from employee
select * from genre
select * from invoice
select * from invoice_line
select * from media_type
select * from playlist
select * from playlist_track
select * from track
 

--- Realistic Business Questions

---1.Customer Analytics

---Which customers have spent the most money on music?
 
SELECT customer.customer_id, customer.first_name, customer.last_name,
    SUM(invoice.total) AS TotalSpent
    FROM customer
    JOIN invoice ON customer.customer_id = invoice.customer_id
    GROUP BY customer.customer_id,customer.first_name,customer.last_name
    ORDER BY TotalSpent DESC;
	 

---	What is the average customer lifetime value?
    
SELECT SUM(invoice.total)/COUNT(DISTINCT customer.customer_id) AS AverageCustomerLifetimeValue
	FROM customer
	JOIN invoice ON customer.customer_id = invoice.customer_id;

--- How many customers have made repeat purchases versus one-time purchases?

--Group customer by Number of Invoices and add categories
SELECT PurchaseCategory, COUNT(*)AS NumberOfCustomers
   FROM(
	    SELECT customer_id, COUNT(invoice.invoice_id) AS NumberOfPurchases,
	    CASE
	    WHEN COUNT(invoice.invoice_id) = 1 THEN 'One-Time Purchases'
		WHEN COUNT(invoice.invoice_id) >=2 THEN 'Repeat Purchases'
        END AS PurchaseCategory
	    FROM invoice
	    GROUP BY customer_id
   ) AS CstomerPurchaseSummary
GROUP By PurchaseCategory;
 

--- Which country generates the most revenue per customer?
SELECT customer.country,
       COUNT(Distinct customer.customer_id) AS NumberOfCustomers,
	   SUM(invoice.total) AS TotalRevenue,
	   SUM(invoice.total) / COUNT(Distinct customer.customer_id) AS RevenuePerCustomer
FROM customer
JOIN invoice on customer.customer_id = invoice.customer_id
GROUP BY customer.country
ORDER BY RevenuePerCustomer DESC;

--- Which customers haven't made a purchase in the last 6 months?
SELECT customer.customer_id, customer.first_name, customer.last_name, customer.country
FROM customer
WHERE customer.customer_id NOT IN (
      SELECT DISTINCT customer_id
	  FROM invoice
	  WHERE invoice_date >= DATEADD(MONTH, -6, '2020-12-30')
	  );

----2.Sales and Revenue Analysis

--- What are the monthly revenue trends for the last two years?
SELECT YEAR(invoice_date) AS RevenueYear,
       MONTH(invoice_date) AS RevenueMonth,
	   SUM(total) AS MonthlyRevenue
FROM invoice
WHERE invoice_date >= DATEADD(YEAR, -2, '2020-12-30')
      AND invoice_date <= '2020-12-30'
GROUP BY YEAR(invoice_date),
         MONTH(invoice_date)
ORDER BY RevenueYear, RevenueMonth;
	 
--- What is the average value of an invoice (purchase)?
SELECT AVG(total) AS AverageInvoiceValue
FROM invoice;


--- Which months or quarters have peak music sales?
SELECT 
    DATENAME(YEAR, invoice_date) AS SalesYear,
    DATENAME(MONTH, invoice_date) AS SalesMonth,
    COUNT(invoice_id) AS NumberOfInvoices,
    SUM(total) AS TotalRevenue
FROM 
    invoice
GROUP BY 
    YEAR(invoice_date), MONTH(invoice_date), DATENAME(YEAR, invoice_date), DATENAME(MONTH, invoice_date)
ORDER BY 
    TotalRevenue DESC;

---3. Product & Content Analysis

--- Which tracks generated the most revenue?
SELECT TOP 10 track.track_id, track.name AS TrackName,
SUM(invoice_line.unit_price * invoice_line.quantity) AS TotalRevenue,
SUM(invoice_line.quantity) AS TotalUnitSold
FROM invoice_line
JOIN track on invoice_line.track_id = track.track_id
GROUP BY track.track_id,track.name
ORDER BY TotalRevenue DESC;
 
 --- Which albums or playlists are most frequently included in purchases?
 SELECT TOP 10 album.title AS AlbumTitle FROM album
 SELECT TOP 10 artist.name AS ArtistName FROM artist
 SELECT TOP 10 COUNT(invoice_line.invoice_line_id) AS TrackSold FROM invoice_line
 JOIN track on invoice_line.track_id = track.track_id
 JOIN album on track.album_id = album.album_id
 JOIN artist on album.artist_id = artist.artist_id
 GROUP BY album.title, artist.name
 ORDER BY TrackSold DESC;

 --- Are there any tracks or albums that have never been purchased?
 SELECT track.track_id, track.name AS TrackName FROM track
 LEFT JOIN invoice_line on track.track_id = invoice_line.track_id
 WHERE invoice_line.track_id IS NULL;


 --- What is the average price per track across different genres?
 SELECT genre.name AS Genre FROM genre
 SELECT AVG(track.unit_price) AS AveragePrice FROM track
 JOIN genre on track.genre_id = genre.genre_id
 GROUP BY genre.name
 ORDER BY AveragePrice DESC;

 --- How many tracks does the store have per genre and how does it correlate with sales?
 WITH TrackCounts AS (
    SELECT genre_id,
        COUNT(*) AS TotalTracks
    FROM track
    GROUP BY genre_id
),
SalesByGenre AS (
    SELECT 
        track.genre_id,
        COUNT(invoice_line.invoice_line_id) AS TracksSold,
        SUM(invoice_line.unit_price * invoice_line.quantity) AS Revenue
    FROM invoice_line
    JOIN track on invoice_line.track_id = track.track_id
	GROUP BY track.genre_id
)
SELECT genre.name AS Genre,
    TrackCounts.TotalTracks,
    ISNULL(SalesByGenre.TracksSold, 0) AS TracksSold,
    ISNULL(SalesByGenre.Revenue, 0) AS Revenue
FROM 
    genre
LEFT JOIN 
    TrackCounts ON genre.genre_id = TrackCounts.genre_id
LEFT JOIN 
    SalesByGenre ON genre.genre_id = SalesByGenre.genre_id
ORDER BY 
    Revenue DESC;


----4. Artist & Genre Performance

--- Who are the top 5 highest-grossing artists?
SELECT TOP 5 artist.name AS ArtistName FROM artist
SELECT Top 5 SUM(invoice_line.unit_price * invoice_line.quantity) AS TotalRevenue FROM invoice_line
JOIN track on invoice_line.track_id = track.track_id
JOIN album on track.album_id = album.album_id
JOIN artist on album.artist_id = artist.artist_id
GROUP BY artist.name
ORDER BY TotalRevenue DESC;

--- Which music genres are most popular in terms of:
  --Number of tracks sold
  --Total revenue
SELECT genre.name AS Genre FROM genre
SELECT COUNT(invoice_line.invoice_line_id) AS TracksSold,
       SUM(invoice_line.unit_price * invoice_line.quantity) AS TotalRevenue
FROM invoice_line
JOIN track ON invoice_line.track_id = track.track_id
JOIN genre ON track.genre_id = genre.genre_id
GROUP BY genre.name
ORDER BY TotalRevenue DESC;


SELECT genre.name AS Genre FROM genre
SELECT COUNT(invoice_line.invoice_line_id) AS TracksSold,
       SUM(invoice_line.unit_price * invoice_line.quantity) AS TotalRevenue
FROM invoice_line
JOIN track ON invoice_line.track_id = track.track_id
JOIN genre ON track.genre_id = genre.genre_id
GROUP BY genre.name
ORDER BY TracksSold DESC;


--- Are certain genres more popular in specific countries?
SELECT invoice.billing_country FROM invoice
SELECT genre.name AS genre FROM genre
SELECT COUNT(invoice_line.invoice_line_id) AS TracksSold,
       SUM(invoice_line.unit_price * invoice_line.quantity) AS TotalRevenue
FROM invoice
JOIN invoice_line on invoice.invoice_id = invoice_line.invoice_id
JOIN track ON invoice_line.track_id = track.track_id
JOIN genre on track.genre_id = genre.genre_id
GROUP BY invoice.billing_country, genre.name
ORDER BY invoice.billing_country, TracksSold DESC;


----5. Employee & Operational Efficiency

--- Which employees (support representatives) are managing the highest-spending customers?
SELECT Top 5 employee.employee_id, 
       employee.first_name + '  ' + employee.last_name AS SupportRep FROM employee
SELECT customer.customer_id,
        customer.first_name + '  ' + customer.last_name AS CustomerName From customer
SELECT SUM(invoice.total) AS CustomerTotalSpending FROM invoice
JOIN customer on customer.customer_id = invoice.customer_id
JOIN employee on customer.support_rep_id = employee.employee_id
GROUP BY employee.employee_id, employee.first_name, employee.last_name,
         customer.customer_id, customer.first_name, customer.last_name
ORDER BY CustomerTotalSpending DESC;

--- What is the average number of customers per employee?
SELECT CAST(COUNT(customer.customer_id) AS FLOAT) / NULLIF (COUNT(employee.employee_id), 0) AS AvgCustomersPerEmployee
FROM customer, employee;

 ----6. Geographic Trends

 --- Which countries or cities have the highest number of customers?
 SELECT TOP 10
 country, COUNT(*) AS CustomerCount
 FROM customer
 GROUP BY country
 ORDER BY CustomerCount DESC;



SELECT TOP 10
 city, COUNT(*) AS CustomerCount
 FROM customer
 GROUP BY city
 ORDER BY CustomerCount DESC;

----7. Operational Optimization

---	Are there pricing patterns that lead to higher or lower sales?
SELECT invoice_line.unit_price, COUNT(*) AS TotalSales
FROM invoice_line
GROUP BY invoice_line.unit_price
ORDER BY invoice_line.unit_price;

--- Which media types (e.g., MPEG, AAC) are declining or increasing in usage?
 
SELECT media_type.name AS MediaType FROM media_type
 SELECT COUNT(track.track_id) AS UsageCount FROM track
INNER JOIN media_type on track.media_type_id  = media_type.media_type_id
GROUP BY media_type.name
ORDER BY UsageCount DESC;

Drop table 

 