WITH
store_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        d.d_year,
        d.d_moy AS month_no,
        s.s_state AS state,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_net_paid) AS net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_item_sk, i.i_product_name, d.d_year, d.d_moy, s.s_state
),
catalog_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        d.d_year,
        d.d_moy AS month_no,
        cc.cc_state AS state,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_net_paid) AS net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_item_sk, i.i_product_name, d.d_year, d.d_moy, cc.cc_state
),
web_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        d.d_year,
        d.d_moy AS month_no,
        we.web_state AS state,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_net_paid) AS net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_item_sk, i.i_product_name, d.d_year, d.d_moy, we.web_state
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
monthly_agg AS (
    SELECT
        i_item_sk,
        i_product_name,
        d_year,
        month_no,
        state,
        SUM(net_profit) AS total_profit,
        SUM(net_paid) AS total_paid,
        SUM(orders) AS total_orders
    FROM combined_sales
    GROUP BY i_item_sk, i_product_name, d_year, month_no, state
),
ranked_monthly AS (
    SELECT
        i_item_sk,
        i_product_name,
        d_year,
        month_no,
        state,
        total_profit,
        total_paid,
        total_orders,
        ROW_NUMBER() OVER (PARTITION BY state, d_year, month_no ORDER BY total_profit DESC) AS profit_rank
    FROM monthly_agg
)
SELECT
    i_item_sk,
    i_product_name,
    d_year,
    month_no,
    state,
    total_profit,
    total_paid,
    total_orders,
    profit_rank
FROM ranked_monthly
WHERE profit_rank <= 10
ORDER BY state, d_year, month_no, profit_rank
