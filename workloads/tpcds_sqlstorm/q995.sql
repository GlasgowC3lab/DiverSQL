WITH sales_by_state AS (
    SELECT d.d_year AS year,
           ca.ca_state AS state,
           SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND i.i_category = 'Electronics'
    GROUP BY d.d_year, ca.ca_state

    UNION ALL

    SELECT d.d_year AS year,
           ca.ca_state AS state,
           SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND i.i_category = 'Electronics'
    GROUP BY d.d_year, ca.ca_state

    UNION ALL

    SELECT d.d_year AS year,
           ca.ca_state AS state,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND i.i_category = 'Electronics'
    GROUP BY d.d_year, ca.ca_state
),
state_agg AS (
    SELECT year,
           state,
           SUM(total_profit) AS total_profit
    FROM sales_by_state
    GROUP BY year, state
)
SELECT
    year,
    state,
    total_profit,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank
FROM state_agg
ORDER BY total_profit DESC
LIMIT 10
