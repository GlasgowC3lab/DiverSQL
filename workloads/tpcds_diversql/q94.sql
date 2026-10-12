WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        CASE WHEN i.i_current_price > 100 THEN 'Premium' ELSE 'Standard' END AS price_category,
        cs.cs_net_profit AS cs_net_profit,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_quantity AS cs_quantity,
        ss.ss_quantity AS ss_quantity,
        cc.cc_name,
        cp.cp_type,
        hd.hd_vehicle_count,
        c.c_customer_id
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        LEFT JOIN (
            SELECT * FROM store_sales TABLESAMPLE BERNOULLI (5)
        ) ss ON ss.ss_sold_date_sk = d.d_date_sk
               AND ss.ss_item_sk = i.i_item_sk
        LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk
        LEFT JOIN catalog_page cp2 ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
        LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
        LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    WHERE
        d.d_year BETWEEN 1999 AND 2001
        AND i.i_current_price BETWEEN 50 AND 150
        AND hd.hd_vehicle_count >= 1
        AND cc.cc_state = 'CA'
        AND cp.cp_type = 'C'
        AND c.c_preferred_cust_flag = 'Y'
        AND cs.cs_quantity > (SELECT MAX(hd2.hd_vehicle_count) FROM household_demographics hd2)
),
agg_by_category AS (
    SELECT
        d_year,
        i_category,
        price_category,
        SUM(cs_net_profit + COALESCE(ss_net_profit, 0)) AS total_profit,
        SUM(cs_quantity + COALESCE(ss_quantity, 0)) AS total_quantity
    FROM base
    GROUP BY d_year, i_category, price_category
)
SELECT
    d_year,
    AVG(total_profit) AS avg_profit_per_category,
    COUNT(*) AS category_cnt
FROM agg_by_category
GROUP BY d_year
HAVING AVG(total_profit) > (
    SELECT MAX(i2.i_current_price)
    FROM item i2
    WHERE i2.i_brand = 'BrandX'
)
ORDER BY d_year DESC
LIMIT 100
