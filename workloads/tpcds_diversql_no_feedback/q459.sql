/* goal: Identify fiscal years (2000‑2005) that have store return activity but no catalog sales activity. */
SELECT year
FROM (
    SELECT d.d_year AS year
    FROM date_dim d
    RIGHT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE sr.sr_return_quantity > 0
      AND d.d_year BETWEEN 2000 AND 2005
    EXCEPT
    SELECT d.d_year AS year
    FROM date_dim d
    RIGHT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_quantity > 0
      AND d.d_year BETWEEN 2000 AND 2005
) t
ORDER BY year
LIMIT 100
