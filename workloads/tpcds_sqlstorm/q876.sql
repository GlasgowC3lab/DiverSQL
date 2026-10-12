WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           i.i_category AS category,
           'catalog' AS channel,
           cs.cs_net_profit AS profit,
           cs.cs_quantity AS quantity,
           cs.cs_ext_sales_price AS sales_amt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE p.p_discount_active = 'Y' AND cc.cc_state = 'CA'
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           i.i_category,
           'store',
           ss.ss_net_profit,
           ss.ss_quantity,
           ss.ss_ext_sales_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE p.p_discount_active = 'Y' AND s.s_state = 'CA'
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           i.i_category,
           'web',
           ws.ws_net_profit,
           ws.ws_quantity,
           ws.ws_ext_sales_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE p.p_discount_active = 'Y' AND wp.wp_type = 'Home'
),
agg AS (
    SELECT d.d_year AS d_year,
           s.category,
           s.channel,
           SUM(s.profit) AS total_profit,
           SUM(s.sales_amt) AS total_sales,
           SUM(s.quantity) AS total_quantity,
           COUNT(*) AS transaction_count
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, s.category, s.channel
),
ranked AS (
    SELECT a.*,
           ROW_NUMBER() OVER (PARTITION BY a.d_year, a.channel ORDER BY a.total_profit DESC) AS profit_rank
    FROM agg a
)
SELECT d_year,
       category,
       channel,
       total_profit,
       total_sales,
       total_quantity,
       transaction_count,
       profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, total_profit DESC
LIMIT 100
