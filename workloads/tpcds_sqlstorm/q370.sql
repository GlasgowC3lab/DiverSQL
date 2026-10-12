WITH unified_sales AS (
    SELECT
        d.d_year AS sales_year,
        s.s_state AS state,
        i.i_category AS category,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        ca.ca_state,
        i.i_category,
        cs.cs_net_paid,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    UNION ALL
    SELECT
        d.d_year,
        ca.ca_state,
        i.i_category,
        ws.ws_net_paid,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), top_categories AS (
    SELECT category
    FROM unified_sales
    GROUP BY category
    ORDER BY SUM(net_paid) DESC
    LIMIT 10
), aggregated AS (
    SELECT
        sales_year,
        state,
        category,
        SUM(net_paid) AS total_net_paid,
        SUM(profit) AS total_profit
    FROM unified_sales
    WHERE sales_year BETWEEN 1999 AND 2002
      AND category IN (SELECT category FROM top_categories)
    GROUP BY sales_year, state, category
)
SELECT
    sales_year,
    state,
    category,
    total_net_paid,
    total_profit,
    ROUND(
        ((total_net_paid - LAG(total_net_paid) OVER (PARTITION BY state, category ORDER BY sales_year))
        / NULLIF(LAG(total_net_paid) OVER (PARTITION BY state, category ORDER BY sales_year), 0)) * 100,
        2
    ) AS yoy_pct_change
FROM aggregated
ORDER BY sales_year, state, total_net_paid DESC
