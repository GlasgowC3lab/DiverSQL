WITH
  sales_agg AS (
    SELECT
      ss_store_sk,
      ss_promo_sk,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_store_sk, ss_promo_sk
  ),
  returns_agg AS (
    SELECT
      sr_store_sk,
      sr_reason_sk,
      SUM(sr_return_amt) AS total_return,
      SUM(sr_net_loss) AS total_loss
    FROM store_returns
    GROUP BY sr_store_sk, sr_reason_sk
  ),
  sales_detail AS (
    SELECT
      ss_ticket_number,
      ss_addr_sk,
      ss_store_sk,
      ss_promo_sk,
      ss_quantity
    FROM store_sales
  ),
  unmatched_sales AS (
    SELECT ss_ticket_number FROM store_sales
    EXCEPT
    SELECT sr_ticket_number FROM store_returns
  )
SELECT
  s.s_store_name,
  p.p_promo_name,
  ca.ca_state,
  r.r_reason_desc,
  sales_agg.total_sales,
  returns_agg.total_return,
  CASE WHEN sales_agg.total_sales > 0 THEN returns_agg.total_return / sales_agg.total_sales ELSE 0 END AS return_rate,
  COUNT(DISTINCT sd.ss_ticket_number) AS tickets_sold,
  (SELECT COUNT(*) FROM unmatched_sales) AS unmatched_ticket_cnt
FROM
  sales_agg
  JOIN store s
    ON sales_agg.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON sales_agg.ss_promo_sk = p.p_promo_sk
  FULL OUTER JOIN returns_agg
    ON sales_agg.ss_store_sk = returns_agg.sr_store_sk
  LEFT JOIN store_returns sr
    ON returns_agg.sr_store_sk = sr.sr_store_sk
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN store_sales ss
    ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN sales_detail sd
    ON ss.ss_ticket_number = sd.ss_ticket_number
  LEFT JOIN promotion p2
    ON sd.ss_promo_sk = p2.p_promo_sk
WHERE
  s.s_state = 'TX'
  AND ca.ca_location_type = 'single family'
GROUP BY
  s.s_store_name,
  p.p_promo_name,
  ca.ca_state,
  r.r_reason_desc,
  sales_agg.total_sales,
  returns_agg.total_return
HAVING
  SUM(sd.ss_quantity) > 100
ORDER BY
  return_rate DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
