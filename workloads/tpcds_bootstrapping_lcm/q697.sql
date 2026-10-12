WITH aggregated AS (
    SELECT
        cc.cc_company_name,
        cc.cc_city,
        cc.cc_state,
        s.s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        d_sold.d_year AS catalog_sold_year,
        d_ship.d_year AS catalog_ship_year,
        d_ws_ship.d_year AS web_ship_year,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customer_cnt,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_cnt,
        AVG(cs.cs_quantity) AS avg_catalog_quantity,
        AVG(ws.ws_quantity) AS avg_web_quantity,
        (SUM(cs.cs_ext_discount_amt) + SUM(ws.ws_ext_discount_amt)) AS total_discount_amount
    FROM call_center cc
    JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_cc_closed.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    WHERE d_sold.d_year = 2001
      AND cc.cc_state = 'CA'
    GROUP BY
        cc.cc_company_name,
        cc.cc_city,
        cc.cc_state,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_sold.d_year,
        d_ship.d_year,
        d_ws_ship.d_year
    HAVING SUM(cs.cs_net_paid) > 5000
)
SELECT
    cc_company_name,
    cc_city,
    cc_state,
    s_store_name,
    store_city,
    store_state,
    catalog_sold_year,
    catalog_ship_year,
    web_ship_year,
    total_catalog_net_paid,
    total_web_net_paid,
    catalog_customer_cnt,
    web_customer_cnt,
    avg_catalog_quantity,
    avg_web_quantity,
    total_discount_amount,
    ROW_NUMBER() OVER (ORDER BY total_catalog_net_paid + total_web_net_paid DESC) AS revenue_rank_by_year
FROM aggregated
ORDER BY total_catalog_net_paid DESC
LIMIT 100
