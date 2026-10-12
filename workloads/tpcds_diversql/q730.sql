WITH
store_fact AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_ticket_number,
    ss.ss_customer_sk,
    ss.ss_net_profit,
    ss.ss_quantity,
    ss.ss_item_sk,
    d.d_year   AS year,
    c.c_preferred_cust_flag,
    p.p_channel_demo,
    cd.cd_gender,
    hd.hd_income_band_sk
  FROM store_sales ss
  JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2000
    AND c.c_preferred_cust_flag = 'Y'
    AND p.p_channel_demo = 'N'
    AND cd.cd_gender = 'M'
    AND hd.hd_income_band_sk BETWEEN 3 AND 5
    AND ss.ss_quantity > 2
),
catalog_fact AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_order_number,
    cs.cs_bill_customer_sk,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_sales_price,
    d.d_year            AS cat_year,
    p.p_channel_demo    AS cat_channel_demo,
    cd.cd_marital_status,
    hd.hd_buy_potential,
    cp.cp_department
  FROM catalog_sales cs
  JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year = 2000
    AND p.p_channel_demo = 'N'
    AND cd.cd_marital_status = 'M'
    AND hd.hd_buy_potential = '2000-3000'
    AND cs.cs_quantity > 1
),
store_ret AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    r.r_reason_desc,
    d.d_year AS ret_year
  FROM store_returns sr
  JOIN reason r      ON sr.sr_reason_sk = r.r_reason_sk
  JOIN date_dim d    ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE r.r_reason_desc = 'Damaged'
    AND d.d_year = 2000
),
web_ret AS (
  SELECT
    wr.wr_order_number,
    wr.wr_return_quantity,
    wr.wr_net_loss,
    r.r_reason_desc AS web_reason,
    d.d_year        AS web_year
  FROM web_returns wr
  JOIN reason r    ON wr.wr_reason_sk = r.r_reason_sk
  JOIN date_dim d  ON wr.wr_returned_date_sk = d.d_date_sk
  WHERE r.r_reason_desc = 'Damaged'
    AND d.d_year = 2000
),
order_intersect AS (
  SELECT ss_ticket_number AS order_id FROM store_fact
  INTERSECT
  SELECT cs_order_number    AS order_id FROM catalog_fact
),
order_except AS (
  SELECT cs_order_number AS order_id FROM catalog_fact
  EXCEPT
  SELECT ss_ticket_number AS order_id FROM store_fact
),
full_returns AS (
  SELECT
    COALESCE(sr.sr_ticket_number, wr.wr_order_number) AS order_id,
    sr.sr_return_quantity,
    wr.wr_return_quantity          AS web_return_quantity,
    sr.sr_net_loss,
    wr.wr_net_loss                AS web_net_loss,
    sr.r_reason_desc               AS store_reason,
    wr.web_reason                  AS web_reason
  FROM store_ret sr
  FULL OUTER JOIN web_ret wr
    ON sr.sr_ticket_number = wr.wr_order_number
)
SELECT
  sf.ss_customer_sk,
  c.c_first_name,
  c.c_last_name,
  SUM(sf.ss_net_profit + COALESCE(cf.cs_net_profit, 0)) AS total_net_profit,
  CASE
    WHEN SUM(sf.ss_net_profit + COALESCE(cf.cs_net_profit, 0)) > 10000 THEN 'HIGH'
    WHEN SUM(sf.ss_net_profit + COALESCE(cf.cs_net_profit, 0)) > 1000  THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  ROW_NUMBER() OVER (PARTITION BY sf.ss_customer_sk ORDER BY SUM(sf.ss_net_profit + COALESCE(cf.cs_net_profit, 0)) DESC) AS profit_rank,
  oi.order_id AS intersect_order_id,
  oe.order_id AS except_order_id,
  fr.store_reason,
  fr.web_reason,
  fr.sr_return_quantity,
  fr.web_return_quantity
FROM store_fact sf
JOIN customer c        ON sf.ss_customer_sk = c.c_customer_sk
LEFT JOIN catalog_fact cf ON sf.ss_customer_sk = cf.cs_bill_customer_sk
LEFT JOIN order_intersect oi ON sf.ss_ticket_number = oi.order_id
LEFT JOIN order_except   oe ON sf.ss_ticket_number = oe.order_id
LEFT JOIN full_returns   fr ON sf.ss_ticket_number = fr.order_id
WHERE sf.year = 2000
GROUP BY
  sf.ss_customer_sk,
  c.c_first_name,
  c.c_last_name,
  oi.order_id,
  oe.order_id,
  fr.store_reason,
  fr.web_reason,
  fr.sr_return_quantity,
  fr.web_return_quantity
ORDER BY total_net_profit DESC
LIMIT 100
