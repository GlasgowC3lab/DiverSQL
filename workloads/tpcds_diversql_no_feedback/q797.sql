WITH filtered_sales AS (
    SELECT
        cc.cc_call_center_id      AS cc_id,
        cc.cc_manager             AS manager,
        cc.cc_city                AS city,
        i.i_category              AS category,
        i.i_product_name          AS product_name,
        cs.cs_order_number        AS order_number,
        cs.cs_item_sk             AS item_sk,
        cs.cs_net_profit          AS net_profit
    FROM tpcds.call_center cc
    JOIN tpcds.catalog_sales cs
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_product_name, '^A.*Luxury')
      AND cc.cc_manager LIKE '%Bob%'
      AND cc.cc_city LIKE 'San%'
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
      )
)
SELECT
    cc_id,
    manager,
    city,
    category,
    product_name,
    SUM(net_profit) AS total_profit,
    substr(manager, 1, 1) || substr(manager, strpos(manager, ' ') + 1, 1) AS manager_initials
FROM filtered_sales
GROUP BY cc_id, manager, city, category, product_name, manager
ORDER BY total_profit DESC
LIMIT 100
