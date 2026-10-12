WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_store_sk,
        ss_sold_time_sk,
        ss_promo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_quantity > 2
    GROUP BY ss_item_sk, ss_store_sk, ss_sold_time_sk, ss_promo_sk
)
SELECT
    s.s_store_name,
    i.i_category,
    td.t_hour,
    p.p_promo_name,
    SUM(sa.total_sales) AS sum_sales,
    SUM(sr.sr_return_amt) AS sum_store_returns,
    SUM(cr.cr_return_amount) AS sum_catalog_returns,
    SUM(wr.wr_return_amt) AS sum_web_returns,
    COUNT(DISTINCT sa.ss_promo_sk) AS distinct_promos,
    AVG(p.p_cost) AS avg_promo_cost
FROM ss_agg sa
JOIN item i
    ON sa.ss_item_sk = i.i_item_sk
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN time_dim td
    ON sa.ss_sold_time_sk = td.t_time_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_store_sk = s.s_store_sk
   AND sr.sr_return_time_sk = td.t_time_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_time_sk = td.t_time_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_time_sk = td.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    i.i_category_id = 5
    AND s.s_state = 'CA'
    AND td.t_hour BETWEEN 9 AND 17
    AND sa.total_sales > (SELECT MAX(p_cost) FROM promotion)
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 100
    )
GROUP BY
    s.s_store_name,
    i.i_category,
    td.t_hour,
    p.p_promo_name
ORDER BY sum_sales DESC
LIMIT 100
