-- Create a CTE named top_customers that lists the top 10 customers
-- based on the total number of distinct films they've rented.
WITH top_customers AS
(
	SELECT
		cu.customer_id
	FROM public.customer AS cu
	INNER JOIN public.rental as r
		ON cu.customer_id = r.customer_id
	INNER JOIN public.inventory as i
		ON i.inventory_id = r.inventory_id
	INNER JOIN public.film as f
		ON i.film_id = f.film_id
	GROUP BY cu.customer_id
	ORDER BY COUNT(DISTINCT f.film_id) DESC
	LIMIT 10
)
SELECT * FROM top_customers


-- For each customer from top_customers,
--retrieve their average payment amount and the count of rentals they've made.
WITH top_customers AS
(
	SELECT
		cu.customer_id,
		ROUND(AVG(p.amount),2) AS avg_payment,
		COUNT(r.rental_id) AS rental_counts
	FROM public.customer AS cu
	INNER JOIN public.rental as r
		ON cu.customer_id = r.customer_id
	INNER JOIN public.inventory as i
		ON i.inventory_id = r.inventory_id
	INNER JOIN public.film as f
		ON i.film_id = f.film_id
	LEFT OUTER JOIN public.payment as p
		ON p.rental_id = r.rental_id
	GROUP BY cu.customer_id
	ORDER BY COUNT(DISTINCT f.film_id) DESC
	LIMIT 10
)
SELECT * FROM top_customers



-- Create a Temporary Table named film_inventory that stores film titles and their corresponding available inventory count.
DROP TABLE IF EXISTS film_inventory;
CREATE TEMPORARY TABLE film_inventory AS
(
	SELECT
		f.film_id,
		f.title,
		COUNT(i.inventory_id) AS inventory_count
	FROM public.film AS f
	INNER JOIN public.inventory AS i
		ON i.film_id = f.film_id
	GROUP BY f.film_id, f.title
);
CREATE INDEX idx_film_inventory ON film_inventory(film_id);
SELECT * FROM film_inventory

-- Populate the film_inventory table with data from the DVD rental database,
-- considering both rentals and returns.
DROP TABLE IF EXISTS film_inventory_edited;
CREATE TEMPORARY TABLE film_inventory_edited AS
(
SELECT
	f.film_id,
	f.title AS title2,
	COUNT(r.rental_id) AS times_rented,
	COUNT(r.return_date) AS times_returned,
	COUNT(i.inventory_id) AS inventory_count2
FROM public.film AS f
INNER JOIN public.inventory AS i
	ON i.film_id = f.film_id
INNER JOIN public.rental AS r
	ON r.inventory_id = i.inventory_id
INNER JOIN film_inventory
	ON film_inventory.title = f.title
GROUP BY f.film_id,f.title
);
CREATE INDEX idx_film_inventory_edited ON film_inventory_edited(film_id);
SELECT * FROM film_inventory_edited

-- Retrieve the film title with the lowest available inventory count from the film_inventory table.
SELECT
	title,inventory_count
FROM film_inventory
WHERE inventory_count =
	(
		SELECT MIN(inventory_count)
		FROM film_inventory
	)
	
	
--Create a Temporary Table named store_performance that stores store IDs, revenue,
-- and the average payment amount per rental.
DROP TABLE IF EXISTS store_performance;
CREATE TEMPORARY TABLE store_performance AS
(
	SELECT
		s.store_id,
		SUM(p.amount) AS revenue,
		ROUND(AVG(p.amount),2) AS avg_payment_per_rental
	FROM
		public.store AS s
	INNER JOIN public.inventory AS i
		ON s.store_id = i.store_id
	INNER JOIN PUBLIC.rental AS r
		ON r.inventory_id = i.inventory_id
	INNER JOIN PUBLIC.payment AS p
		ON r.rental_id = p.rental_id
	GROUP BY
		s.store_id
);
CREATE INDEX idx_store_performance ON store_performance(store_id);
SELECT * FROM store_performance


