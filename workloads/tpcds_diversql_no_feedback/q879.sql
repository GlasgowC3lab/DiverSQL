WITH intersect_items AS (
        SELECT cs.cs_item_sk AS item_sk
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        INTERSECT
        SELECT sr.sr_item_sk
        FROM store_returns sr
        JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ),
    cross_set AS (
        SELECT hd.hd_demo_sk, yr.year
        FROM household_demographics hd
        CROSS JOIN (VALUES 2020, 2021) AS yr(year)
        WHERE hd.hd_buy_potential = '5001-10000'
    )
SELECT
    d.d_year,
    i.i_category,
    p.p_promo_name,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    COUNT(DISTINCT i.i_brand) AS distinct_brands
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN intersect_items ii ON i.i_item_sk = ii.item_sk
CROSS JOIN cross_set cs_cross
WHERE
    i.i_class_id = 10
    AND p.p_discount_active = 'Y'
    AND hd.hd_dep_count >= 5
    AND d.d_quarter_seq = 7
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY
    d.d_year,
    i.i_category,
    p.p_promo_name
ORDER BY
    total_sales DESC
LIMIT 100
