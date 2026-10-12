/*
Goal: Calculate sales and return metrics per store and product category, with subtotals and grand total using ROLLUP, and return the top‑5 categories per store based on catalog net paid. The query joins all 13 selected TPC‑DS tables, re‑uses the CUSTOMER and ITEM tables under different aliases, computes distinct aggregates, includes a scalar sub‑query, and limits the result to 100 rows.
*/
WITH base AS (
    SELECT
        s.s_store_name,
        i.i_category,
        cs.cs_net_paid               AS cs_net_paid,
        ws.ws_net_paid               AS ws_net_paid,
        sr.sr_return_amt            AS sr_return_amt,
        wr.wr_return_amt            AS wr_return_amt,
        cust_bill.c_customer_sk      AS c_customer_sk,
        i.i_brand                    AS i_brand
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p1
        ON ss.ss_promo_sk = p1.p_promo_sk
    JOIN customer cust_bill
        ON ss.ss_customer_sk = cust_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON ss.ss_addr_sk = ca_bill.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN item i_sr
        ON sr.sr_item_sk = i_sr.i_item_sk
    JOIN store s_sr
        ON sr.sr_store_sk = s_sr.s_store_sk
    JOIN customer cust_ret
        ON sr.sr_customer_sk = cust_ret.c_customer_sk
    JOIN customer_address ca_ret
        ON sr.sr_addr_sk = ca_ret.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
        AND cs.cs_item_sk = i.i_item_sk
    JOIN promotion p2
        ON cs.cs_promo_sk = p2.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN customer cust_ship
        ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
    JOIN promotion p3
        ON ws.ws_promo_sk = p3.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE ca_bill.ca_state = 'CA'
),
agg AS (
    SELECT
        s_store_name,
        i_category,
        SUM(cs_net_paid)                AS sum_cs_net_paid,
        SUM(ws_net_paid)                AS sum_ws_net_paid,
        SUM(sr_return_amt)              AS sum_store_returns,
        SUM(wr_return_amt)              AS sum_web_returns,
        COUNT(DISTINCT c_customer_sk)   AS distinct_customers,
        COUNT(DISTINCT i_brand)         AS distinct_brands,
        (SELECT AVG(cs_ext_discount_amt) FROM catalog_sales) AS avg_catalog_discount
    FROM base
    GROUP BY ROLLUP (s_store_name, i_category)
)
SELECT
    s_store_name,
    i_category,
    sum_cs_net_paid,
    sum_ws_net_paid,
    sum_store_returns,
    sum_web_returns,
    distinct_customers,
    distinct_brands,
    avg_catalog_discount
FROM (
    SELECT
        s_store_name,
        i_category,
        sum_cs_net_paid,
        sum_ws_net_paid,
        sum_store_returns,
        sum_web_returns,
        distinct_customers,
        distinct_brands,
        avg_catalog_discount,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(s_store_name, 'ALL')
            ORDER BY sum_cs_net_paid DESC
        ) AS rn
    FROM agg
) t
WHERE rn <= 5
ORDER BY s_store_name, i_category
LIMIT 100
