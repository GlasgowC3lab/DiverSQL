WITH combined_sales AS (
   SELECT 
       cs.cs_sold_date_sk AS date_sk,
       cs.cs_call_center_sk AS call_center_sk,
       cs.cs_bill_customer_sk AS customer_sk,
       cs.cs_item_sk AS item_sk,
       cs.cs_quantity AS quantity,
       cs.cs_net_paid AS net_paid,
       cs.cs_net_profit AS net_profit,
       'Catalog' AS channel,
       cs.cs_promo_sk AS promo_sk
   FROM catalog_sales cs
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE cs.cs_sold_date_sk IS NOT NULL

   UNION ALL

   SELECT 
       ss.ss_sold_date_sk AS date_sk,
       NULL AS call_center_sk,
       ss.ss_customer_sk AS customer_sk,
       ss.ss_item_sk AS item_sk,
       ss.ss_quantity AS quantity,
       ss.ss_net_paid AS net_paid,
       ss.ss_net_profit AS net_profit,
       'Store' AS channel,
       ss.ss_promo_sk AS promo_sk
   FROM store_sales ss
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE ss.ss_sold_date_sk IS NOT NULL

   UNION ALL

   SELECT 
       ws.ws_sold_date_sk AS date_sk,
       NULL AS call_center_sk,
       ws.ws_bill_customer_sk AS customer_sk,
       ws.ws_item_sk AS item_sk,
       ws.ws_quantity AS quantity,
       ws.ws_net_paid AS net_paid,
       ws.ws_net_profit AS net_profit,
       'Web' AS channel,
       ws.ws_promo_sk AS promo_sk
   FROM web_sales ws
   LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE ws.ws_sold_date_sk IS NOT NULL
),
sales_with_date AS (
   SELECT 
       cs.*,
       d.d_date,
       d.d_year,
       d.d_month_seq,
       d.d_week_seq,
       d.d_day_name,
       COALESCE(cc.cc_name, 'N/A') AS call_center_name
   FROM combined_sales cs
   LEFT JOIN date_dim d ON cs.date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cs.call_center_sk = cc.cc_call_center_sk
),
sales_with_rank AS (
   SELECT 
       swd.*,
       ROW_NUMBER() OVER (PARTITION BY swd.customer_sk ORDER BY swd.net_paid DESC) AS purchase_rank,
       SUM(swd.net_paid) OVER (PARTITION BY swd.customer_sk) AS total_customer_spent,
       MAX(swd.net_profit) OVER (PARTITION BY swd.item_sk) AS max_item_profit,
       CASE 
           WHEN swd.net_profit < 0 THEN CONCAT('Loss_', swd.channel)
           ELSE CONCAT('Profit_', swd.channel)
       END AS profit_status,
       COALESCE(
           (SELECT SUM(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = swd.item_sk
              AND cs2.cs_sold_date_sk = swd.date_sk), 0) 
       + COALESCE(
           (SELECT SUM(ss2.ss_net_profit)
            FROM store_sales ss2
            WHERE ss2.ss_item_sk = swd.item_sk
              AND ss2.ss_sold_date_sk = swd.date_sk), 0)
       + COALESCE(
           (SELECT SUM(ws2.ws_net_profit)
            FROM web_sales ws2
            WHERE ws2.ws_item_sk = swd.item_sk
              AND ws2.ws_sold_date_sk = swd.date_sk), 0) 
           AS total_profit_same_day
   FROM sales_with_date swd
),
filtered_sales AS (
   SELECT *
   FROM sales_with_rank
   WHERE d_year BETWEEN 1998 AND 1999
     AND ((channel = 'Catalog' AND call_center_name IS NOT NULL) OR channel <> 'Catalog')
     AND total_customer_spent > 1000
)

SELECT 
    f.customer_sk,
    c.c_customer_id,
    f.item_sk,
    i.i_product_name,
    f.channel,
    f.d_date,
    f.quantity,
    f.net_paid,
    f.net_profit,
    f.purchase_rank,
    f.total_customer_spent,
    f.max_item_profit,
    f.profit_status,
    f.total_profit_same_day,
    CASE 
        WHEN f.call_center_name IS NULL THEN 'No Call Center'
        ELSE f.call_center_name
    END AS call_center_info
FROM filtered_sales f
JOIN customer c ON f.customer_sk = c.c_customer_sk
JOIN item i ON f.item_sk = i.i_item_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_customer_sk = f.customer_sk
      AND sr.sr_returned_date_sk = f.date_sk
)
UNION ALL
SELECT 
    c.c_customer_sk,
    c.c_customer_id,
    CAST(NULL AS integer),
    CAST(NULL AS varchar),
    'NoSales',
    CAST(NULL AS date),
    0,
    CAST(0.0 AS decimal(7,2)),
    CAST(0.0 AS decimal(7,2)),
    CAST(NULL AS integer),
    CAST(0.0 AS decimal(7,2)),
    CAST(NULL AS decimal(7,2)),
    'NoSales',
    CAST(0.0 AS decimal(7,2)),
    'No Sales Data'
FROM customer c
WHERE NOT EXISTS (SELECT 1 FROM filtered_sales f WHERE f.customer_sk = c.c_customer_sk)
