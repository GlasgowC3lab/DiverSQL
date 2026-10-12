WITH
    sampled_inventory AS (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
    ),

    sales_agg AS (
        SELECT
            s.s_state                         AS state,
            i1.i_category                     AS category,
            SUM(ss.ss_net_paid)               AS total_net_paid,
            SUM(ss.ss_net_profit)             AS total_profit,
            COUNT(DISTINCT ss.ss_ticket_number) AS distinct_cnt,
            CASE WHEN SUM(ss.ss_net_profit) > 1000000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
        FROM store_sales ss
        JOIN item i1               ON ss.ss_item_sk   = i1.i_item_sk
        JOIN store s               ON ss.ss_store_sk  = s.s_store_sk
        JOIN promotion p1         ON ss.ss_promo_sk  = p1.p_promo_sk
        JOIN customer c1          ON ss.ss_customer_sk = c1.c_customer_sk
        JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
        JOIN customer_address ca1 ON ss.ss_addr_sk   = ca1.ca_address_sk
        LEFT JOIN sampled_inventory inv
               ON inv.inv_item_sk = i1.i_item_sk
              AND inv.inv_warehouse_sk = s.s_store_sk
        GROUP BY s.s_state, i1.i_category
    ),

    web_agg AS (
        SELECT
            ca2.ca_state                       AS state,
            i2.i_category                      AS category,
            SUM(ws.ws_net_paid)                AS total_net_paid,
            SUM(ws.ws_net_profit)              AS total_profit,
            COUNT(DISTINCT ws.ws_order_number) AS distinct_cnt,
            CASE WHEN SUM(ws.ws_net_profit) > 500000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
        FROM web_sales ws
        JOIN item i2               ON ws.ws_item_sk   = i2.i_item_sk
        JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
        JOIN promotion p2          ON ws.ws_promo_sk  = p2.p_promo_sk
        JOIN customer c2          ON ws.ws_bill_customer_sk = c2.c_customer_sk
        JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
        GROUP BY ca2.ca_state, i2.i_category
    ),

    catalog_agg AS (
        SELECT
            cc.cc_state                       AS state,
            i3.i_category                     AS category,
            SUM(cs.cs_net_paid)               AS total_net_paid,
            SUM(cs.cs_net_profit)             AS total_profit,
            COUNT(DISTINCT cs.cs_order_number) AS distinct_cnt,
            CASE WHEN SUM(cs.cs_net_profit) > 800000 THEN 'HIGH' ELSE 'LOW' END AS profit_level
        FROM catalog_sales cs
        JOIN item i3                ON cs.cs_item_sk   = i3.i_item_sk
        JOIN call_center cc         ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN promotion p3           ON cs.cs_promo_sk   = p3.p_promo_sk
        JOIN warehouse w3           ON cs.cs_warehouse_sk = w3.w_warehouse_sk
        GROUP BY cc.cc_state, i3.i_category
    ),

    orders_without_returns AS (
        SELECT cs_order_number
        FROM catalog_sales
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
    ),

    union_sales AS (
        SELECT state, category, total_net_paid, total_profit, distinct_cnt, profit_level
        FROM sales_agg
        UNION DISTINCT
        SELECT state, category, total_net_paid, total_profit, distinct_cnt, profit_level
        FROM web_agg
    ),

    full_joined AS (
        SELECT
            COALESCE(sa.state, ca.state)        AS state,
            COALESCE(sa.category, ca.category)  AS category,
            SUM(COALESCE(sa.total_net_paid,0) + COALESCE(ca.total_net_paid,0))   AS combined_net_paid,
            SUM(COALESCE(sa.total_profit,0)   + COALESCE(ca.total_profit,0))     AS combined_profit,
            SUM(COALESCE(sa.distinct_cnt,0)   + COALESCE(ca.distinct_cnt,0))     AS combined_cnt,
            CASE
                WHEN SUM(COALESCE(sa.total_profit,0) + COALESCE(ca.total_profit,0)) > 1500000 THEN 'VERY HIGH'
                ELSE 'NORMAL'
            END AS overall_profit_level
        FROM sales_agg sa
        FULL OUTER JOIN catalog_agg ca
            ON sa.state = ca.state AND sa.category = ca.category
        GROUP BY COALESCE(sa.state, ca.state), COALESCE(sa.category, ca.category)
    )

SELECT DISTINCT
    fj.state,
    fj.category,
    fj.combined_net_paid,
    fj.combined_profit,
    fj.combined_cnt,
    fj.overall_profit_level
FROM full_joined fj
WHERE fj.state IS NOT NULL
ORDER BY fj.combined_profit DESC
OFFSET 0 LIMIT 100
