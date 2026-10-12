WITH agg_center_category AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_call_center_sk,
        i.i_category,
        SUM(cs.cs_ext_sales_price) AS cat_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM call_center cc
    JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
    JOIN item i ON i.i_item_sk = cs.cs_item_sk
    JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND i.i_current_price > 50
      AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND cs.cs_quantity > 1
    GROUP BY cc.cc_call_center_id, cc.cc_call_center_sk, i.i_category
    HAVING SUM(cs.cs_ext_sales_price) > 1000
)
SELECT
    cc_call_center_id,
    SUM(cat_sales) AS total_catalog_sales,
    SUM(store_profit) AS total_store_profit,
    SUM(web_profit) AS total_web_profit,
    COUNT(DISTINCT i_category) AS num_categories,
    (SELECT SUM(cr2.cr_net_loss)
     FROM catalog_returns cr2
     WHERE cr2.cr_call_center_sk = agg_center_category.cc_call_center_sk) AS total_return_loss
FROM agg_center_category
GROUP BY cc_call_center_id, agg_center_category.cc_call_center_sk
HAVING SUM(cat_sales) > 5000
ORDER BY total_catalog_sales DESC
LIMIT 100
