WITH agg_cs AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        SUM(cs.cs_quantity) AS total_qty,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        ARRAY[SUM(cs.cs_quantity), SUM(cs.cs_ext_sales_price)] AS metrics_arr
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450541 AND 2451217
      AND cs.cs_ext_sales_price > 100
    GROUP BY cs.cs_item_sk, cs.cs_promo_sk
),
unnested_cs AS (
    SELECT
        a.cs_item_sk,
        a.cs_promo_sk,
        t.metric,
        CASE WHEN t.seq = 1 THEN 'qty' ELSE 'sales' END AS metric_type,
        a.total_qty,
        a.total_sales
    FROM (
        SELECT cs_item_sk, cs_promo_sk, metrics_arr, total_qty, total_sales
        FROM agg_cs
    ) a
    CROSS JOIN UNNEST(a.metrics_arr) WITH ORDINALITY AS t(metric, seq)
)
SELECT
    p.p_promo_name,
    w.w_state,
    c.c_birth_country,
    uc.metric_type,
    SUM(uc.metric) AS metric_sum,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
    SUM(ss.ss_net_profit) AS store_profit,
    AVG(ws.ws_net_paid) AS avg_web_paid,
    SUM(cr.cr_return_amount) AS total_return_amount
FROM unnested_cs uc
JOIN tpcds.catalog_sales cs
  ON cs.cs_item_sk = uc.cs_item_sk AND cs.cs_promo_sk = uc.cs_promo_sk
JOIN tpcds.promotion p
  ON p.p_promo_sk = cs.cs_promo_sk
JOIN tpcds.warehouse w
  ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN tpcds.customer c
  ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN tpcds.store_sales ss
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN tpcds.web_sales ws
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN tpcds.web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN tpcds.catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = cs.cs_item_sk
WHERE p.p_channel_demo = 'N'
  AND w.w_country = 'United States'
  AND c.c_birth_year BETWEEN 1970 AND 1990
  AND ws.ws_quantity > 1
  AND NOT EXISTS (
        SELECT 1 FROM tpcds.web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_amt > 500
    )
GROUP BY CUBE (p.p_promo_name, w.w_state, c.c_birth_country, uc.metric_type)
HAVING SUM(uc.metric) > 0
ORDER BY metric_sum DESC
LIMIT 100
