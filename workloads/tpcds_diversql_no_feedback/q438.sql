WITH sales_join AS (
    SELECT
        s.s_store_name            AS s_store_name,
        i.i_brand                 AS i_brand,
        d.d_year                  AS d_year,
        cp.cp_department          AS cp_department,
        wp.wp_type                AS wp_type,
        ss.ss_ext_sales_price     AS ss_ext_sales_price,
        ss.ss_net_profit          AS ss_net_profit,
        ss.ss_quantity            AS ss_quantity,
        ss.ss_ticket_number       AS ss_ticket_number,
        ss.ss_ext_discount_amt    AS ss_ext_discount_amt,
        ss.ss_net_paid            AS ss_net_paid
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE i.i_category_id = 5
      AND i.i_units = 'Box'
      AND d.d_year = 2001
      AND s.s_state = 'CA'
      AND cp.cp_type = 'Promotional'
      AND i.i_current_price > (
            SELECT AVG(i_current_price)
            FROM item
            WHERE i_category_id = 5
        )
)
SELECT
    s_store_name,
    i_brand,
    d_year,
    cp_department,
    wp_type,
    COUNT(*)                              AS sales_cnt,
    SUM(ss_ext_sales_price)               AS total_sales,
    AVG(ss_net_profit)                    AS avg_profit,
    MIN(ss_ext_sales_price)               AS min_sale,
    MAX(ss_ext_sales_price)               AS max_sale
FROM sales_join
GROUP BY s_store_name, i_brand, d_year, cp_department, wp_type
ORDER BY total_sales DESC
LIMIT 100
