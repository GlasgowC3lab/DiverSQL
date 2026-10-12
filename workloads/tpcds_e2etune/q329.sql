WITH catalog_agg AS (
  SELECT
    cs_call_center_sk,
    cs_item_sk,
    cs_sold_date_sk,
    SUM(cs_net_profit) AS catalog_net_profit,
    SUM(cs_net_paid) AS catalog_net_paid,
    SUM(cs_ext_discount_amt) AS catalog_discount,
    COUNT(*) AS catalog_orders
  FROM catalog_sales
  WHERE cs_sold_date_sk BETWEEN 2450806 AND 2451063
    AND cs_net_paid > 0
  GROUP BY cs_call_center_sk, cs_item_sk, cs_sold_date_sk
),
store_agg AS (
  SELECT
    ss_item_sk,
    ss_sold_date_sk,
    SUM(ss_net_profit) AS store_net_profit,
    SUM(ss_net_paid) AS store_net_paid,
    SUM(ss_ext_discount_amt) AS store_discount,
    COUNT(*) AS store_transactions
  FROM store_sales
  WHERE ss_sold_date_sk BETWEEN 2450806 AND 2451063
    AND ss_net_paid > 0
  GROUP BY ss_item_sk, ss_sold_date_sk
),
joined AS (
  SELECT
    c.cc_division AS division,
    c.cc_state AS state,
    c.cc_name AS name,
    ca.cs_call_center_sk,
    ca.cs_item_sk,
    ca.cs_sold_date_sk,
    ca.catalog_net_profit,
    ca.catalog_net_paid,
    ca.catalog_discount,
    ca.catalog_orders,
    sa.store_net_profit,
    sa.store_net_paid,
    sa.store_discount,
    sa.store_transactions
  FROM catalog_agg ca
  LEFT JOIN store_agg sa
    ON ca.cs_item_sk = sa.ss_item_sk
   AND ca.cs_sold_date_sk = sa.ss_sold_date_sk
  JOIN call_center c
    ON ca.cs_call_center_sk = c.cc_call_center_sk
  WHERE c.cc_tax_percentage BETWEEN 0.00 AND 0.12
    AND c.cc_division IN (1,2,3,4,5)
)
SELECT
  division,
  state,
  name,
  SUM(catalog_net_profit + COALESCE(store_net_profit,0)) AS total_net_profit,
  SUM(catalog_net_paid + COALESCE(store_net_paid,0)) AS total_net_paid,
  SUM(catalog_discount + COALESCE(store_discount,0)) AS total_discount,
  SUM(catalog_orders + COALESCE(store_transactions,0)) AS total_transactions,
  ROUND(SUM(catalog_net_paid) / NULLIF(SUM(catalog_orders),0),2) AS avg_catalog_spend_per_order,
  ROUND(SUM(COALESCE(store_net_paid,0)) / NULLIF(SUM(COALESCE(store_transactions,0)),0),2) AS avg_store_spend_per_transaction,
  RANK() OVER (ORDER BY SUM(catalog_net_profit + COALESCE(store_net_profit,0)) DESC) AS profit_rank
FROM joined
GROUP BY division, state, name
HAVING SUM(catalog_net_profit + COALESCE(store_net_profit,0)) > 100000
ORDER BY total_net_profit DESC
LIMIT 50
