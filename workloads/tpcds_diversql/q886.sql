WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        d.d_year,
        s.s_market_manager,
        p.p_discount_active,
        cp.cp_department,
        wp.wp_image_count,
        we.web_name,
        r.total_return_amt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN LATERAL (
        SELECT SUM(wr.wr_return_amt) AS total_return_amt
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_item_sk = ws.ws_item_sk
    ) r ON TRUE
    WHERE d.d_year = 2001
      AND s.s_market_manager = 'James Irvin'
      AND p.p_discount_active = 'Y'
      AND wp.wp_image_count >= 3
      AND cp.cp_department = 'Electronics'
),
union_data AS (
    SELECT
        CASE WHEN cs_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS price_category,
        cs_net_paid AS net_paid,
        total_return_amt,
        cs_quantity AS quantity,
        (SELECT MAX(d2.d_year) FROM date_dim d2 WHERE d2.d_year <= 2001) AS max_year
    FROM base
    WHERE total_return_amt > 0
    UNION
    SELECT
        CASE WHEN cs_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END,
        cs_net_paid,
        total_return_amt,
        cs_quantity,
        (SELECT MAX(d2.d_year) FROM date_dim d2 WHERE d2.d_year <= 2001)
    FROM base
    WHERE total_return_amt IS NULL
)
SELECT
    price_category,
    SUM(net_paid) AS total_net_paid,
    SUM(total_return_amt) AS total_returns,
    COUNT(*) AS rows_cnt,
    AVG(quantity) AS avg_quantity,
    MAX(max_year) AS max_year
FROM union_data
GROUP BY price_category
ORDER BY total_net_paid DESC
LIMIT 100
