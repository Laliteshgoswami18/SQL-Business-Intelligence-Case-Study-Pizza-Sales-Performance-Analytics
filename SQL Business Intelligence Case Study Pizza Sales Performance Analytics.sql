-- 1. Calculate the total revenue generated and the total number of unique orders processed from the dataset.

	 SELECT COUNT(DISTINCT OD.ORDER_ID) TOTAL_UNIQUE_ORDER, SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE 
	 FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID ;

-- 2. Retrieve the total quantity sold and total revenue generated for each pizza category. 
--    Sort the output by revenue in descending order.

	 SELECT PT.CATEGORY,  SUM(OD.QUANTITY) AS TOTAL_QUANTITY,  SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE
	 FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID 
	 JOIN PIZZA_TYPES PT ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
     GROUP BY PT.CATEGORY
     ORDER BY TOTAL_REVENUE DESC ;

-- 3. Identify the pizza categories that have generated a total revenue of more than $50,000.

      SELECT PT.CATEGORY, SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE 
	  FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON  P.PIZZA_ID = OD.PIZZA_ID 
      JOIN PIZZA_TYPES PT ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID
	  GROUP BY PT.CATEGORY
      HAVING SUM(P.PRICE * OD.QUANTITY) > 50000 ;

-- 4. Extract the hour from the time column and find the total number of orders placed during each hour of the day. 
--    Identify the top 3 peak hours for the business.

      SELECT HOUR(TIME) AS HOUR_PER_ORDER,
      COUNT(ORDER_ID) AS TOTAL_ORDER FROM PIZZA_ORDER
	  GROUP BY HOUR(TIME)
      ORDER BY TOTAL_ORDER DESC 
      LIMIT 3 ; 

-- 5. Determine which pizza size (S, M, L, etc.) is the most popular based on the total quantity ordered.

      SELECT P.SIZE, SUM(OD.QUANTITY) AS TOTAL_QUANTITY
      FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID 
      GROUP BY P.SIZE 
	  ORDER BY TOTAL_QUANTITY DESC
      LIMIT 1 ;

-- 6. Extract the day of the week from the date column and analyze the distribution of total orders 
--   across different days. 

     SELECT DAYNAME(DATE) AS DAY_OF_WEEK,
     COUNT(ORDER_ID) TOTAL_ORDER 
     FROM PIZZA_ORDER 
     GROUP BY DAYNAME(DATE)
     ORDER BY TOTAL_ORDER DESC ;

-- 7. Write a query to find all pizzas whose individual price is strictly greater than the average price 
--    of all pizzas within their respective category.

     SELECT P.PIZZA_ID, PT.NAME, PT.CATEGORY, P.PRICE
     FROM PIZZAS P JOIN PIZZA_TYPES PT ON P.PIZZA_TYPE_ID = PT.PIZZA_TYPE_ID 
WHERE P.PRICE > ( 
                 SELECT AVG(P2.PRICE) AS AVG_PRICE
     FROM PIZZAS P2 JOIN PIZZA_TYPES PT2 ON P2.PIZZA_TYPE_ID = PT2.PIZZA_TYPE_ID 
     WHERE PT2.CATEGORY 	= PT.CATEGORY ) ;

-- 8. Find all order_ids where the total quantity of pizzas ordered is greater than the average total quantity 
--    calculated across all orders in the entire system.

       SELECT ORDER_ID  
FROM (
       SELECT ORDER_ID, SUM(QUANTITY) AS TOTAL_QUANTITY 
       FROM PIZZA_ORDER_DETAIL
       GROUP BY ORDER_ID ) AS A
WHERE A.TOTAL_QUANTITY > ( 
                          SELECT AVG(TOTAL_QUANTITY) AS AVG_QUANTITY
FROM (
      SELECT ORDER_ID, SUM(QUANTITY) AS TOTAL_QUANTITY 
      FROM PIZZA_ORDER_DETAIL
      GROUP BY ORDER_ID ) AS S 
) ;

-- 9. Find the names of the pizzas that contain the maximum number of ingredients.

SELECT P1.NAME FROM PIZZA_TYPES P1 
WHERE ( LENGTH(P1.INGREDIENTS) - LENGTH (REPLACE(P1.INGREDIENTS, ',' , '')) + 1 ) 
       = (
	      SELECT MAX(LENGTH(P2.INGREDIENTS) - LENGTH(REPLACE(P2.INGREDIENTS, ',' , '')) + 1 ) FROM PIZZA_TYPES P2 ) ;

-- 10. List the pizza types that have never been ordered or have the lowest sales contribution, 
--     along with their category names.

WITH CTE AS (
			 SELECT PT.PIZZA_TYPE_ID, PT.CATEGORY, COALESCE(SUM(P.PRICE * OD.QUANTITY),0)  AS TOTAL_SALES
	         FROM PIZZA_TYPES PT LEFT JOIN PIZZAS P ON PT.PIZZA_TYPE_ID  = P.PIZZA_TYPE_ID  
	         LEFT JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID 
	         GROUP BY PT.PIZZA_TYPE_ID , PT.CATEGORY ),
RANKED AS ( 
		   SELECT *,
		   DENSE_RANK() OVER (ORDER BY TOTAL_SALES ASC) AS RANK_
		   FROM CTE )
    
           SELECT * FROM RANKED
           WHERE RANK_ = 1 ; 

-- 11. Identify the single order that generated the highest total bill amount. 
--     Display its order_id, total revenue, and the date of the order.

      SELECT PO.DATE, OD.ORDER_ID ,SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE 
      FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID 
      JOIN PIZZA_ORDER PO ON PO.ORDER_ID = OD.ORDER_ID 
      GROUP BY PO.DATE, OD.ORDER_ID 
      HAVING SUM(P.PRICE * OD.QUANTIY ) = 
(
     SELECT MAX(ORDER_TOTAL) 
FROM (
     SELECT OD2.ORDER_ID, SUM(P2.PRICE * OD2.QUANTITY) AS ORDER_TOTAL 
     FROM PIZZAS P2 JOIN PIZZA_ORDER_DETAIL OD2 ON P2.PIZZA_ID = OD2.PIZZA_ID 
     JOIN  PIZZA_ORDER PO2 ON PO2.ORDER_ID = OD2.ORDER_ID 
     GROUP BY OD2.ORDER_ID ) 
AS S ) ;

WITH CTE AS (
             SELECT PO.DATE, OD.ORDER_ID , SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE 
             FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID JOIN PIZZA_ORDER PO 
             ON PO.ORDER_ID = OD.ORDER_ID
             GROUP BY OD.ORDER_ID, PO.DATE 
)
SELECT ORDER_ID, DATE, TOTAL_REVENUE 
FROM CTE
ORDER BY TOTAL_REVENUE DESC
LIMIT 1 ;

-- 12. Calculate the total revenue generated for each date, and compute a running/cumulative total revenue 
--     over time, ordered chronologically by date.

       SELECT DATE, TOTAL_REVENUE, SUM(TOTAL_REVENUE) OVER (ORDER BY DATE) AS CUMULATIVE_REVENUE
FROM (
      SELECT PO.DATE, SUM(P.PRICE * QUANTITY) AS TOTAL_REVENUE 
      FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID 
	  JOIN PIZZA_ORDER PO ON PO.ORDER_ID = OD.ORDER_ID 
	  GROUP BY PO.DATE ) AS DAILY_REVENUE 
      ORDER BY DATE DESC ;
      
-- 13. Find total revenue per date and rank dates based on revenue (highest first).

       SELECT DATE, TOTAL_REVENUE, SUM(TOTAL_REVENUE) OVER (ORDER BY DATE) AS CUMULATIVE_REVENUE,
       DENSE_RANK() OVER (ORDER BY TOTAL_REVENUE DESC) AS DAILY_RANK 
FROM (
      SELECT PO.DATE, SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE 
      FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID 
      JOIN PIZZA_ORDER PO ON PO.ORDER_ID = OD.ORDER_ID 
      GROUP BY PO.DATE ) AS DAILY_REVENUE ;
      
-- 14. For each date, calculate total revenue, compare it with previous day revenue and next day revenue, 
--     and also compute running total
       
	WITH CTE AS (
       SELECT PO.DATE, SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE 
       FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID 
	   JOIN PIZZA_ORDER PO ON PO.ORDER_ID = OD.ORDER_ID 
       GROUP BY PO.DATE ),
REVENUE AS (
       SELECT DATE, TOTAL_REVENUE, 
       SUM(TOTAL_REVENUE) OVER (ORDER BY DATE) AS CUMULATIVE_REVENUE,
       LAG(TOTAL_REVENUE) OVER (ORDER BY DATE) AS PREVIOUS_DAY_REVENUE,
       LEAD(TOTAL_REVENUE) OVER (ORDER BY DATE) AS NEXT_DAY_REVENUE
FROM CTE )
       SELECT DATE, TOTAL_REVENUE,  CUMULATIVE_REVENUE, 
       COALESCE(PREVIOUS_DAY_REVENUE , 0) AS PREVIOUS_DAY_REVENUE,
       COALESCE(NEXT_DAY_REVENUE , 0) AS NEXT_DAY_REVENUE,
	   COALESCE(TOTAL_REVENUE,0) - COALESCE(PREVIOUS_DAY_REVENUE , 0) AS REVENUE_UPDATE
       FROM REVENUE
       ORDER BY DATE ; 
	
    
    
-- 15. For each pizza category, find the top 3 best-selling pizzas based on total revenue. 

WITH CTE AS (
			SELECT PT.CATEGORY, PT.NAME, SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE 
            FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID 
            JOIN PIZZA_TYPES PT ON PT.PIZZA_TYPE_ID = P.PIZZA_TYPE_ID
            GROUP BY PT.CATEGORY, PT.NAME ),
RANK_PIZZA AS (
		   SELECT CATEGORY, NAME, TOTAL_REVENUE,   
		   RANK() OVER (PARTITION BY CATEGORY ORDER BY TOTAL_REVENUE DESC)  AS RANK_
FROM CTE )
          SELECT CATEGORY, NAME , TOTAL_REVENUE, RANK_
          FROM RANK_PIZZA 
          WHERE RANK_ <= 3
          ORDER BY CATEGORY, RANK_;

 

-- 16. Group the orders by month and calculate the percentage growth or decline in total revenue from the 
--     previous month to the current month. 

WITH CTE AS (
             SELECT MONTH(PO.DATE) AS MONTH_NAME , SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE
             FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID 
             JOIN PIZZA_ORDER PO ON PO.ORDER_ID = OD.ORDER_ID 
			 GROUP BY MONTH(PO.DATE) ),
REVENUE AS ( 
            SELECT MONTH_NAME , TOTAL_REVENUE, 
            LAG(TOTAL_REVENUE) OVER (ORDER BY MONTH_NAME) AS PREVIOUS_REVENUE
FROM CTE ) 
            SELECT MONTH_NAME, TOTAL_REVENUE, PREVIOUS_REVENUE,
            ROUND(( (TOTAL_REVENUE - PREVIOUS_REVENUE) * 100.0) / PREVIOUS_REVENUE, 2) AS MONTHLY_GROWTH
            FROM REVENUE ;

-- 17. For every order placed on any day, calculate the time difference (in minutes) between that order 
--     and the immediately following order on the same day.

	WITH CTE AS (
				 SELECT ORDER_ID , DATE , TIME, 
				 LEAD(TIME) OVER (PARTITION BY DATE ORDER BY TIME) AS NEXT_TIME 
	FROM PIZZA_ORDER )
					 SELECT ORDER_ID, DATE, TIME, NEXT_TIME, 
					 TIMESTAMPDIFF(MINUTE,TIME,NEXT_TIME) AS DIFFERNECE_IN_MINUTE 
	FROM CTE ;
    
    
-- 18. Calculate the percentage contribution of each individual pizza type's revenue to the total 
--     overall revenue of the business. 

WITH CTE AS (
			 SELECT P.PIZZA_TYPE_ID, SUM(P.PRICE * OD.QUANTITY) AS TOTAL_REVENUE 
             FROM PIZZAS P JOIN PIZZA_ORDER_DETAIL OD ON P.PIZZA_ID = OD.PIZZA_ID
			 GROUP BY P.PIZZA_TYPE_ID  ),
RANK_WISE AS (
          SELECT PIZZA_TYPE_ID, TOTAL_REVENUE,
          SUM(TOTAL_REVENUE) OVER() AS OVERALL_REVENUE,
          RANK() OVER(ORDER BY TOTAL_REVENUE DESC) AS RANK_
          FROM CTE 
)        
          SELECT PIZZA_TYPE_ID, TOTAL_REVENUE, OVERALL_REVENUE, RANK_,
          ROUND((TOTAL_REVENUE / OVERALL_REVENUE) * 100.0 , 2) CONTRIBUTION
          FROM RANK_WISE ;
                          







