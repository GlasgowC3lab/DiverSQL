WITH unified_sales AS (
    SELECT
        d.d_year,
        d.d_moy AS month_of_year,
        s.s_state AS state,
        s.s_city AS city,
        i.i_category AS category,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit,
        'store' AS channel,
        ss.ss_customer_sk AS customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        cc.cc_state,
        cc.cc_city,
        i.i_category,
        cs.cs_quantity,
        cs.cs_net_profit,
        'catalog',
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        we.web_state,
        we.web_city,
        i.i_category,
        ws.ws_quantity,
        ws.ws_net_profit,
        'web',
        ws.ws_bill_customer_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
),
aggregated AS (
    SELECT
        d_year,
        month_of_year,
        state,
        channel,
        category,
        SUM(quantity) AS total_quantity,
        SUM(net_profit) AS total_net_profit,
        COUNT(DISTINCT customer_sk) AS distinct_customers
    FROM unified_sales
    WHERE d_year BETWEEN 1998 AND 2002
    GROUP BY
        d_year,
        month_of_year,
        state,
        channel,
        category
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, month_of_year, channel ORDER BY total_net_profit DESC) AS profit_rank
    FROM aggregated
)
SELECT
    d_year,
    month_of_year,
    state,
    channel,
    category,
    total_quantity,
    total_net_profit,
    distinct_customers,
    profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, month_of_year, channel, profit_rank
