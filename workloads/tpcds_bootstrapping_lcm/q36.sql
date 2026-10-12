WITH sales_agg AS (
    SELECT
        i.i_category AS item_category,
        i.i_brand AS item_brand,
        sd.d_year AS sold_year,
        shd.d_month_seq AS ship_month_seq,
        s.s_state AS store_state,
        s.s_market_desc AS market_desc,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(i.i_wholesale_cost * cs.cs_quantity) AS total_wholesale_cost,
        SUM(i.i_current_price * cs.cs_quantity) AS total_current_price,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_cnt,
        SUM(wp.wp_image_count) AS total_image_count,
        AVG(wp.wp_char_count) AS avg_char_count,
        AVG(date_diff('day', shd.d_date, wpad.d_date)) AS avg_days_ship_to_access
    FROM catalog_sales cs
    JOIN date_dim sd
        ON cs.cs_sold_date_sk = sd.d_date_sk
    JOIN date_dim shd
        ON cs.cs_ship_date_sk = shd.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = shd.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = sd.d_date_sk
    JOIN date_dim wpad
        ON wp.wp_access_date_sk = wpad.d_date_sk
    WHERE sd.d_year BETWEEN 2015 AND 2020
      AND i.i_category = 'Electronics'
      AND s.s_state = 'CA'
      AND wp.wp_type = 'Landing'
    GROUP BY
        i.i_category,
        i.i_brand,
        sd.d_year,
        shd.d_month_seq,
        s.s_state,
        s.s_market_desc
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
    item_category,
    item_brand,
    sold_year,
    ship_month_seq,
    store_state,
    market_desc,
    total_net_paid,
    total_profit,
    order_cnt,
    avg_discount,
    total_wholesale_cost,
    total_current_price,
    web_page_cnt,
    total_image_count,
    avg_char_count,
    avg_days_ship_to_access,
    RANK() OVER (PARTITION BY item_category ORDER BY total_net_paid DESC) AS category_year_rank
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
