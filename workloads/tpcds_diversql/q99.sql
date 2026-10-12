WITH
    /* Aggregate store sales per item, date, household and promotion */
    sales_summary AS (
        SELECT
            ss_item_sk,
            ss_sold_date_sk,
            ss_hdemo_sk,
            ss_promo_sk,
            SUM(ss_ext_sales_price) AS total_sales,
            SUM(ss_ext_discount_amt) AS total_discount,
            COUNT(*) AS sales_cnt
        FROM store_sales
        GROUP BY ss_item_sk, ss_sold_date_sk, ss_hdemo_sk, ss_promo_sk
    ),
    /* Aggregate store returns per item, date and household */
    returns_summary AS (
        SELECT
            sr_item_sk,
            sr_returned_date_sk,
            sr_hdemo_sk,
            SUM(sr_return_amt) AS total_return_amt,
            COUNT(*) AS return_cnt
        FROM store_returns
        GROUP BY sr_item_sk, sr_returned_date_sk, sr_hdemo_sk
    ),
    /* Items that were sold but never returned */
    items_not_returned AS (
        SELECT ss_item_sk
        FROM store_sales
        EXCEPT
        SELECT sr_item_sk
        FROM store_returns
    ),
    /* Distinct web pages with a specific type */
    distinct_wp AS (
        SELECT DISTINCT wp_web_page_sk, wp_type
        FROM web_page
        WHERE wp_type = 'content'
    ),
    /* Aggregate web returns per item, date and page */
    web_returns_agg AS (
        SELECT
            wr_item_sk,
            wr_returned_date_sk,
            wr_web_page_sk,
            SUM(wr_return_quantity) AS wr_return_quantity,
            SUM(wr_return_amt) AS wr_return_amt
        FROM web_returns
        GROUP BY wr_item_sk, wr_returned_date_sk, wr_web_page_sk
    )
SELECT
    d.d_year,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_promo_name,
    SUM(COALESCE(s.total_sales, 0)) AS sum_sales,
    SUM(COALESCE(r.total_return_amt, 0)) AS sum_returns,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS sum_quantity_on_hand,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS sum_web_return_qty,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS sum_web_return_amt,
    COUNT(DISTINCT COALESCE(s.ss_item_sk, r.sr_item_sk)) AS distinct_items,
    CASE WHEN inc.ss_item_sk IS NOT NULL THEN 1 ELSE 0 END AS sold_without_return_flag
FROM sales_summary s
FULL OUTER JOIN returns_summary r
    ON s.ss_item_sk = r.sr_item_sk
    AND s.ss_sold_date_sk = r.sr_returned_date_sk
    AND s.ss_hdemo_sk = r.sr_hdemo_sk
JOIN date_dim d
    ON COALESCE(s.ss_sold_date_sk, r.sr_returned_date_sk) = d.d_date_sk
JOIN household_demographics hd
    ON COALESCE(s.ss_hdemo_sk, r.sr_hdemo_sk) = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN promotion p
    ON s.ss_promo_sk = p.p_promo_sk
LEFT JOIN inventory inv
    ON d.d_date_sk = inv.inv_date_sk
LEFT JOIN web_returns_agg wr
    ON wr.wr_item_sk = COALESCE(s.ss_item_sk, r.sr_item_sk)
   AND wr.wr_returned_date_sk = COALESCE(s.ss_sold_date_sk, r.sr_returned_date_sk)
LEFT JOIN distinct_wp dp
    ON wr.wr_web_page_sk = dp.wp_web_page_sk
LEFT JOIN web_page wp
    ON dp.wp_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site wsite
    ON wsite.web_open_date_sk = d.d_date_sk
LEFT JOIN items_not_returned inc
    ON inc.ss_item_sk = COALESCE(s.ss_item_sk, r.sr_item_sk)
WHERE d.d_year = 2002
  AND ib.ib_lower_bound >= 40000
  AND p.p_channel_event = 'N'
GROUP BY d.d_year, hd.hd_buy_potential, ib.ib_lower_bound, ib.ib_upper_bound, p.p_promo_name, inc.ss_item_sk
ORDER BY sum_sales DESC
LIMIT 100
