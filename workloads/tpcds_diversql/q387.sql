WITH
    inventory_sampled AS (
        SELECT inv_item_sk, inv_quantity_on_hand
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
        WHERE inv_quantity_on_hand > 0
    ),
    store_ret AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_return_amt,
            sr.sr_net_loss,
            d.d_year,
            d.d_day_name,
            i.i_category,
            cd.cd_gender,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            ib.ib_lower_bound
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2002
          AND t.t_minute = 11
          AND i.i_brand = 'Brand#12'
    ),
    web_ret AS (
        SELECT
            wr.wr_item_sk,
            wr.wr_return_amt,
            wr.wr_net_loss,
            d.d_year,
            d.d_day_name,
            i.i_category,
            cd.cd_gender,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            ib.ib_lower_bound,
            wp.wp_type
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE d.d_year = 2002
          AND t.t_second = 9
          AND wp.wp_type = 'content'
    ),
    catalog_page_join AS (
        SELECT
            cp.cp_catalog_page_id,
            cp.cp_department,
            d.d_year,
            d.d_day_name
        FROM catalog_page cp
        JOIN date_dim d ON cp.cp_end_date_sk = d.d_date_sk
        WHERE cp.cp_type = 'catalog'
          AND d.d_year = 2002
    ),
    web_page_join AS (
        SELECT
            wp.wp_web_page_id,
            wp.wp_type,
            d.d_year,
            d.d_day_name
        FROM web_page wp
        JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
        WHERE wp.wp_type = 'content'
          AND d.d_year = 2002
    ),
    diff_items AS (
        SELECT inv_item_sk
        FROM inventory_sampled
        EXCEPT
        SELECT sr_item_sk
        FROM store_ret
    )
SELECT
    cpj.cp_department,
    wpj.wp_type,
    COUNT(DISTINCT diff_items.inv_item_sk) AS distinct_items_not_returned,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amt,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amt,
    AVG(COALESCE(inv.inv_quantity_on_hand, 0)) AS avg_inventory_qty,
    MIN(ib.ib_lower_bound) AS min_income_lower,
    MAX(ib.ib_upper_bound) AS max_income_upper
FROM catalog_page_join cpj
FULL OUTER JOIN web_page_join wpj
    ON cpj.d_year = wpj.d_year
   AND cpj.d_day_name = wpj.d_day_name
LEFT JOIN store_ret sr
    ON sr.d_year = cpj.d_year
   AND sr.d_day_name = cpj.d_day_name
LEFT JOIN web_ret wr
    ON wr.d_year = wpj.d_year
   AND wr.d_day_name = wpj.d_day_name
LEFT JOIN diff_items
    ON diff_items.inv_item_sk = sr.sr_item_sk
LEFT JOIN inventory_sampled inv
    ON inv.inv_item_sk = diff_items.inv_item_sk
LEFT JOIN income_band ib
    ON ib.ib_income_band_sk = sr.hd_income_band_sk
WHERE (cpj.cp_department IS NOT NULL OR wpj.wp_type IS NOT NULL)
GROUP BY
    cpj.cp_department,
    wpj.wp_type
ORDER BY total_store_return_amt DESC
LIMIT 100
