WITH
    ss_agg AS (
        SELECT
            ss_item_sk,
            ss_sold_time_sk,
            ss_promo_sk,
            SUM(ss_ext_sales_price) AS total_store_sales,
            SUM(ss_net_profit) AS total_store_profit,
            COUNT(*) AS store_txn_cnt
        FROM store_sales
        WHERE ss_quantity > 5
          AND ss_ext_sales_price > 500
          AND ss_net_profit <> 0
        GROUP BY ss_item_sk, ss_sold_time_sk, ss_promo_sk
    ),
    ws_agg AS (
        SELECT
            ws_item_sk,
            ws_sold_time_sk,
            ws_promo_sk,
            SUM(ws_ext_sales_price) AS total_web_sales,
            SUM(ws_net_profit) AS total_web_profit,
            COUNT(*) AS web_txn_cnt
        FROM web_sales
        WHERE ws_quantity > 2
          AND ws_net_paid > 1000
        GROUP BY ws_item_sk, ws_sold_time_sk, ws_promo_sk
    ),
    cr_agg AS (
        SELECT
            cr_item_sk,
            cr_returned_time_sk,
            SUM(cr_return_amount) AS total_catalog_return_amount,
            COUNT(*) AS catalog_return_cnt
        FROM catalog_returns
        WHERE cr_return_quantity = 1
          AND cr_return_amount > 20
        GROUP BY cr_item_sk, cr_returned_time_sk
    ),
    wr_agg AS (
        SELECT
            wr_item_sk,
            wr_returned_time_sk,
            SUM(wr_return_amt) AS total_web_return_amount,
            COUNT(*) AS web_return_cnt
        FROM web_returns
        WHERE wr_return_quantity > 0
          AND wr_return_amt > 10
        GROUP BY wr_item_sk, wr_returned_time_sk
    )
SELECT
    i.i_item_id,
    i.i_brand,
    p.p_promo_name,
    td.t_hour,
    ss_agg.total_store_sales,
    ws_agg.total_web_sales,
    cr_agg.total_catalog_return_amount,
    wr_agg.total_web_return_amount,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items_sold
FROM ss_agg
JOIN ws_agg
    ON ss_agg.ss_item_sk = ws_agg.ws_item_sk
   AND ss_agg.ss_sold_time_sk = ws_agg.ws_sold_time_sk
   AND ss_agg.ss_promo_sk = ws_agg.ws_promo_sk
JOIN item i
    ON ss_agg.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN time_dim td
    ON ss_agg.ss_sold_time_sk = td.t_time_sk
LEFT JOIN cr_agg
    ON cr_agg.cr_item_sk = i.i_item_sk
   AND cr_agg.cr_returned_time_sk = td.t_time_sk
LEFT JOIN wr_agg
    ON wr_agg.wr_item_sk = i.i_item_sk
   AND wr_agg.wr_returned_time_sk = td.t_time_sk
WHERE p.p_discount_active = 'Y'
  AND i.i_brand = 'Brand#12'
GROUP BY i.i_item_id,
         i.i_brand,
         p.p_promo_name,
         td.t_hour,
         ss_agg.total_store_sales,
         ws_agg.total_web_sales,
         cr_agg.total_catalog_return_amount,
         wr_agg.total_web_return_amount
HAVING SUM(ss_agg.total_store_sales) > 10000

UNION DISTINCT

SELECT
    i2.i_item_id,
    i2.i_brand,
    p2.p_promo_name,
    td2.t_hour,
    NULL AS total_store_sales,
    NULL AS total_web_sales,
    cr_agg.total_catalog_return_amount,
    wr_agg.total_web_return_amount,
    COUNT(DISTINCT i2.i_item_sk) AS distinct_items_sold
FROM cr_agg
JOIN item i2
    ON cr_agg.cr_item_sk = i2.i_item_sk
JOIN promotion p2
    ON p2.p_item_sk = i2.i_item_sk
JOIN time_dim td2
    ON cr_agg.cr_returned_time_sk = td2.t_time_sk
LEFT JOIN wr_agg
    ON wr_agg.wr_item_sk = i2.i_item_sk
   AND wr_agg.wr_returned_time_sk = td2.t_time_sk
WHERE p2.p_discount_active = 'N'
  AND i2.i_size = 'large'
GROUP BY i2.i_item_id,
         i2.i_brand,
         p2.p_promo_name,
         td2.t_hour,
         cr_agg.total_catalog_return_amount,
         wr_agg.total_web_return_amount
HAVING SUM(cr_agg.total_catalog_return_amount) > 5000

LIMIT 100
