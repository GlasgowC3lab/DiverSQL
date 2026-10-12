WITH
    sales_agg AS (
        SELECT
            cs.cs_bill_customer_sk,
            cs.cs_promo_sk,
            SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
            SUM(cs.cs_ext_discount_amt) AS total_discount,
            COUNT(*) AS order_cnt
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE c.c_salutation IN ('Mr.', 'Mrs.', 'Ms.', 'Miss')
          AND cs.cs_sold_date_sk BETWEEN 2450500 AND 2452000
          AND cs.cs_quantity > 1
          AND cs.cs_list_price > 100
        GROUP BY GROUPING SETS (
            (cs.cs_bill_customer_sk, cs.cs_promo_sk),
            (cs.cs_bill_customer_sk)
        )
    ),
    web_agg AS (
        SELECT
            ws.ws_bill_customer_sk,
            ws.ws_promo_sk,
            SUM(ws.ws_net_paid_inc_ship) AS ws_total_net_paid,
            SUM(ws.ws_ext_discount_amt) AS ws_total_discount,
            COUNT(*) AS ws_order_cnt
        FROM web_sales ws
        JOIN customer c2 ON ws.ws_bill_customer_sk = c2.c_customer_sk
        JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
        WHERE c2.c_birth_year = 1975
          AND ws.ws_sold_date_sk BETWEEN 2450500 AND 2452000
          AND ws.ws_quantity > 2
          AND ws.ws_list_price > 200
        GROUP BY ws.ws_bill_customer_sk, ws.ws_promo_sk
    )
SELECT
    sa.cs_bill_customer_sk AS customer_sk,
    sa.cs_promo_sk AS promo_sk,
    SUM(sa.total_net_paid) AS catalog_total_net,
    SUM(sa.total_discount) AS catalog_total_discount,
    SUM(sa.order_cnt) AS catalog_order_cnt,
    COALESCE(SUM(wa.ws_total_net_paid), 0) AS web_total_net,
    COALESCE(SUM(wa.ws_total_discount), 0) AS web_total_discount,
    COALESCE(SUM(wa.ws_order_cnt), 0) AS web_order_cnt,
    CASE WHEN SUM(sa.total_discount) > 5000 THEN 'HIGH' ELSE 'LOW' END AS catalog_discount_level,
    CASE WHEN COALESCE(SUM(wa.ws_total_discount), 0) > 3000 THEN 'HIGH' ELSE 'LOW' END AS web_discount_level,
    ROW_NUMBER() OVER (PARTITION BY sa.cs_bill_customer_sk ORDER BY SUM(sa.total_net_paid) DESC) AS rn
FROM sales_agg sa
LEFT JOIN web_agg wa
    ON sa.cs_bill_customer_sk = wa.ws_bill_customer_sk
   AND (sa.cs_promo_sk = wa.ws_promo_sk OR sa.cs_promo_sk IS NULL)
GROUP BY
    sa.cs_bill_customer_sk,
    sa.cs_promo_sk,
    wa.ws_bill_customer_sk,
    wa.ws_promo_sk
ORDER BY catalog_total_net DESC, rn
OFFSET 0 FETCH NEXT 100 ROWS ONLY
