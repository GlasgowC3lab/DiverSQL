WITH agg_inventory AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'BrandX')
)
SELECT
    s.s_store_name,
    d_sold.d_year,
    i_sales.i_product_name,
    p.p_promo_name,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    SUM(fs.cs_net_profit) AS total_profit,
    inv_agg.total_qty_on_hand,
    COUNT(DISTINCT fs.cs_order_number) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(fs.cs_ext_sales_price) DESC) AS sales_rank
FROM filtered_sales fs
JOIN date_dim d_sold
     ON fs.cs_sold_date_sk = d_sold.d_date_sk
JOIN call_center cc
     ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
     ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i_sales
     ON fs.cs_item_sk = i_sales.i_item_sk
JOIN promotion p
     ON fs.cs_promo_sk = p.p_promo_sk
JOIN agg_inventory inv_agg
     ON i_sales.i_item_sk = inv_agg.inv_item_sk
JOIN store_returns sr
     ON sr.sr_item_sk = i_sales.i_item_sk
JOIN item i_return
     ON sr.sr_item_sk = i_return.i_item_sk
JOIN date_dim d_returned
     ON sr.sr_returned_date_sk = d_returned.d_date_sk
JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
     ON s.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY
    s.s_store_name,
    d_sold.d_year,
    i_sales.i_product_name,
    p.p_promo_name,
    inv_agg.total_qty_on_hand
ORDER BY total_sales DESC
LIMIT 100
