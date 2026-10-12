WITH raw_sales AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_call_center_sk AS channel_sk,
           cs_ext_sales_price AS sales_amount,
           cs_net_profit AS profit,
           cs_quantity AS quantity,
           cs_ext_discount_amt AS discount_amt,
           cs_bill_customer_sk AS cust_sk,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_store_sk,
           ss_ext_sales_price,
           ss_net_profit,
           ss_quantity,
           ss_ext_discount_amt,
           ss_customer_sk,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_web_page_sk,
           ws_ext_sales_price,
           ws_net_profit,
           ws_quantity,
           ws_ext_discount_amt,
           ws_bill_customer_sk,
           'web'
    FROM web_sales
),
sales_agg AS (
    SELECT 
        date_sk,
        item_sk,
        SUM(sales_amount) AS total_sales,
        SUM(profit) AS total_profit,
        SUM(quantity) AS total_quantity,
        SUM(discount_amt) AS total_discount,
        COUNT(DISTINCT cust_sk) AS distinct_customers,
        COUNT(*) AS transaction_count,
        MIN(channel) AS any_channel
    FROM raw_sales
    GROUP BY date_sk, item_sk
),
promo_agg AS (
    SELECT p_item_sk AS item_sk,
           SUM(p_cost) AS total_promo_cost
    FROM promotion
    GROUP BY p_item_sk
),
inventory_latest AS (
    SELECT inv_item_sk AS item_sk,
           inv_quantity_on_hand AS on_hand
    FROM (
        SELECT inv_item_sk,
               inv_quantity_on_hand,
               ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rn
        FROM inventory
    ) t
    WHERE rn = 1
),
promo_inv AS (
    SELECT COALESCE(p.item_sk, i.item_sk) AS item_sk,
           COALESCE(p.total_promo_cost, 0) AS total_promo_cost,
           COALESCE(i.on_hand, 0) AS inventory_on_hand
    FROM promo_agg p
    FULL OUTER JOIN inventory_latest i
        ON p.item_sk = i.item_sk
),
product_info AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           i.i_category,
           i.i_brand,
           i.i_color,
           i.i_size,
           i.i_manager_id,
           i.i_current_price,
           CONCAT(i.i_category, ' - ', CAST(i.i_brand_id AS VARCHAR)) AS cat_brand_key
    FROM item i
),
catalog_sales_agg AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           MIN(cs_call_center_sk) AS call_center_sk
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_item_sk
),
store_sales_agg AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           MIN(ss_store_sk) AS store_sk
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk
),
category_profit_stats AS (
    SELECT s.date_sk,
           i.i_category,
           AVG(s.total_profit) AS avg_category_profit,
           MAX(s.total_profit) AS max_category_profit
    FROM sales_agg s
    JOIN item i ON s.item_sk = i.i_item_sk
    GROUP BY s.date_sk, i.i_category
),
final AS (
    SELECT 
        p.i_item_sk AS product_sk,
        p.i_product_name,
        p.i_category,
        p.i_brand,
        p.i_color,
        p.i_size,
        p.i_manager_id,
        p.i_current_price,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_profit, 0) AS total_profit,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_discount, 0) AS total_discount,
        COALESCE(s.distinct_customers, 0) AS distinct_customers,
        pi.total_promo_cost,
        pi.inventory_on_hand,
        cps.avg_category_profit,
        cps.max_category_profit,
        CASE 
            WHEN COALESCE(s.total_profit, 0) > COALESCE(cps.max_category_profit, 0) * 0.9 THEN 'Top Performer'
            WHEN COALESCE(s.total_profit, 0) < COALESCE(cps.avg_category_profit, 0) * 0.5 THEN 'Underperformer'
            ELSE 'Average'
        END AS performance_tag,
        ROW_NUMBER() OVER (PARTITION BY p.i_category ORDER BY COALESCE(s.total_profit, 0) DESC) AS category_profit_rank,
        (SELECT MAX(s2.total_profit)
         FROM sales_agg s2
         JOIN item i2 ON s2.item_sk = i2.i_item_sk
         WHERE i2.i_category = p.i_category
           AND s2.date_sk = COALESCE(s.date_sk, ca.date_sk, sa.date_sk)
           AND s2.item_sk <> p.i_item_sk) AS max_other_item_profit,
        CONCAT(COALESCE(p.i_brand, 'UNKNOWN'), ' - ', COALESCE(p.i_category, 'UNKNOWN'), ' (', CAST(p.i_item_sk AS VARCHAR), ')') AS product_label,
        cc.cc_name AS call_center_name,
        s_dim.s_store_name AS store_name
    FROM product_info p
    LEFT JOIN sales_agg s ON p.i_item_sk = s.item_sk
    LEFT JOIN catalog_sales_agg ca ON p.i_item_sk = ca.item_sk
    LEFT JOIN store_sales_agg sa ON p.i_item_sk = sa.item_sk
    LEFT JOIN promo_inv pi ON p.i_item_sk = pi.item_sk
    LEFT JOIN category_profit_stats cps ON COALESCE(s.date_sk, ca.date_sk, sa.date_sk) = cps.date_sk AND p.i_category = cps.i_category
    LEFT JOIN call_center cc ON ca.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store s_dim ON sa.store_sk = s_dim.s_store_sk
    LEFT JOIN date_dim d ON COALESCE(s.date_sk, ca.date_sk, sa.date_sk) = d.d_date_sk
)
SELECT *
FROM final
WHERE (total_sales > 0 OR inventory_on_hand > 0)
ORDER BY total_profit DESC
LIMIT 100
