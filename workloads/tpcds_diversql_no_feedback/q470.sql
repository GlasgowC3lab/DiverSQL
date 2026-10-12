WITH inv_agg AS (
       SELECT inv_date_sk,
              SUM(inv_quantity_on_hand) AS total_qty,
              COUNT(*)               AS inv_rows
       FROM inventory
       GROUP BY inv_date_sk
   ),
   promo_site AS (
       SELECT p.p_promo_sk,
              p.p_promo_id,
              p.p_start_date_sk,
              p.p_end_date_sk,
              p.p_cost,
              s.web_site_sk,
              s.web_name,
              s.web_country
       FROM promotion p
       FULL OUTER JOIN web_site s
         ON p.p_start_date_sk = s.web_open_date_sk
       WHERE p.p_channel_dmail = 'Y'
         AND (p.p_discount_active = 'Y' OR s.web_country = 'United States')
   )
SELECT d.d_year,
       d.d_month_seq,
       ca.ca_state,
       c.c_preferred_cust_flag,
       COUNT(DISTINCT wr.wr_order_number)                     AS total_returns,
       SUM(wr.wr_return_amt)                                 AS sum_return_amount,
       AVG(wr.wr_return_amt)                                 AS avg_return_amount,
       SUM(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_quantity ELSE 0 END) AS total_return_qty,
       SUM(ia.total_qty)                                     AS total_inventory_qty,
       COUNT(DISTINCT ps.p_promo_sk)                         AS promo_count,
       AVG(ps.p_cost)                                        AS avg_promo_cost,
       MIN(wr.wr_return_amt)                                 AS min_return_amt,
       MAX(wr.wr_return_amt)                                 AS max_return_amt
FROM web_returns wr
JOIN date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
  ON wr.wr_returned_time_sk = t.t_time_sk
JOIN customer c
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN promo_site ps
  ON ps.p_start_date_sk = d.d_date_sk
JOIN inv_agg ia
  ON ia.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1210
  AND t.t_hour = 14
  AND ca.ca_state = 'CA'
  AND c.c_preferred_cust_flag = 'Y'
  AND wr.wr_return_amt > (SELECT AVG(inner_wr.wr_return_amt)
                           FROM web_returns inner_wr
                           WHERE inner_wr.wr_returned_date_sk = 2451081)
GROUP BY d.d_year,
         d.d_month_seq,
         ca.ca_state,
         c.c_preferred_cust_flag
ORDER BY sum_return_amount DESC
LIMIT 100
