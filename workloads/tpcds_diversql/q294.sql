WITH
    sales_by_cc_item AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_market_manager,
            cc.cc_state,
            i.i_category_id,
            i.i_category,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_quantity) AS total_quantity,
            COUNT(DISTINCT cs.cs_order_number) AS order_cnt
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cc.cc_market_manager = 'Gary Colburn'
          AND cc.cc_state = 'CA'
          AND cc.cc_rec_start_date >= DATE '2000-01-01'
          AND i.i_category_id IN (1, 3, 9)
        GROUP BY
            cc.cc_call_center_sk,
            cc.cc_market_manager,
            cc.cc_state,
            i.i_category_id,
            i.i_category
    ),
    avg_sales_per_manager AS (
        SELECT
            cc_market_manager,
            AVG(total_sales) AS avg_total_sales,
            SUM(total_quantity) AS sum_quantity
        FROM sales_by_cc_item
        GROUP BY cc_market_manager
        HAVING AVG(total_sales) > 5000
    ),
    high_low_orders AS (
        SELECT DISTINCT cs.cs_order_number AS order_num
        FROM catalog_sales cs
        WHERE cs.cs_net_profit > 1000
        EXCEPT
        SELECT DISTINCT cs.cs_order_number
        FROM catalog_sales cs
        WHERE cs.cs_net_profit < 200
    ),
    tier_labels AS (
        SELECT *
        FROM (VALUES
            (1, 'Low'),
            (2, 'Medium'),
            (3, 'High')
        ) AS t(tier, label)
    ),
    sales_with_tier AS (
        SELECT
            cc_market_manager,
            i_category,
            total_sales,
            CASE
                WHEN total_sales < 10000 THEN 1
                WHEN total_sales < 50000 THEN 2
                ELSE 3
            END AS tier
        FROM sales_by_cc_item
    )
SELECT
    a.cc_market_manager,
    s.i_category,
    s.total_sales,
    tl.label,
    a.avg_total_sales,
    a.sum_quantity,
    hl.order_num
FROM sales_with_tier s
JOIN avg_sales_per_manager a
    ON s.cc_market_manager = a.cc_market_manager
CROSS JOIN tier_labels tl
CROSS JOIN (SELECT order_num FROM high_low_orders LIMIT 5) hl
WHERE tl.tier = s.tier
LIMIT 100
