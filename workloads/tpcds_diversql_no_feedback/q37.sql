/*
Goal: Identify stores in California that recorded sales in the years 2000 and 2001, show the net paid amount and a running total per store, but exclude any store that had a negative net profit transaction in any year.
The query demonstrates:
- A RIGHT OUTER JOIN between the fact table store_sales and the dimension table store.
- UNION ALL to stack the two year‑specific result sets.
- EXCEPT to subtract stores with negative profit.
- A window function (SUM ... OVER) to compute a running total of net paid per store ordered by the sale date.
- LIMIT 100 to cap the output.
*/
SELECT
  union_sales.store_id,
  union_sales.sales_year,
  union_sales.net_paid,
  union_sales.running_net_paid
FROM (
  -- Sales for year 2000
  SELECT
    s.s_store_id               AS store_id,
    d.d_year                    AS sales_year,
    COALESCE(ss.ss_net_paid, 0) AS net_paid,
    SUM(COALESCE(ss.ss_net_paid, 0)) OVER (
      PARTITION BY s.s_store_id
      ORDER BY d.d_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                           AS running_net_paid
  FROM store_sales ss
  RIGHT JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE s.s_state = 'CA'
    AND d.d_year = 2000

  UNION ALL

  -- Sales for year 2001
  SELECT
    s.s_store_id               AS store_id,
    d.d_year                    AS sales_year,
    COALESCE(ss.ss_net_paid, 0) AS net_paid,
    SUM(COALESCE(ss.ss_net_paid, 0)) OVER (
      PARTITION BY s.s_store_id
      ORDER BY d.d_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                           AS running_net_paid
  FROM store_sales ss
  RIGHT JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE s.s_state = 'CA'
    AND d.d_year = 2001
) AS union_sales
EXCEPT
SELECT
  s_neg.s_store_id               AS store_id,
  d_neg.d_year                    AS sales_year,
  COALESCE(ss_neg.ss_net_paid, 0) AS net_paid,
  SUM(COALESCE(ss_neg.ss_net_paid, 0)) OVER (
    PARTITION BY s_neg.s_store_id
    ORDER BY d_neg.d_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )                               AS running_net_paid
FROM store_sales ss_neg
JOIN store s_neg ON ss_neg.ss_store_sk = s_neg.s_store_sk
JOIN date_dim d_neg ON ss_neg.ss_sold_date_sk = d_neg.d_date_sk
WHERE ss_neg.ss_net_profit < 0
  AND s_neg.s_state = 'CA'
LIMIT 100
