WITH avg_return AS (
       SELECT AVG(cr_return_amount) AS avg_amt
       FROM catalog_returns
   ),
   small_set AS (
       SELECT 1 AS grp UNION ALL SELECT 2 UNION ALL SELECT 3
   )
SELECT
    s.s_store_id,
    ws.web_site_id,
    d_ret.d_year,
    d_ret.d_month_seq,
    ss.grp,
    SUM(cr.cr_net_loss)                         AS total_net_loss,
    COUNT(*)                                     AS cnt_returns,
    AVG(cr.cr_return_amount)                    AS avg_return_amount
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN web_site ws_close
    ON ws_close.web_close_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN web_page wp_access
    ON wp_access.wp_access_date_sk = d_ret.d_date_sk
CROSS JOIN small_set ss
WHERE cr.cr_return_amount > (SELECT avg_amt FROM avg_return)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cr.cr_order_number
          AND cr2.cr_returned_date_sk > cr.cr_returned_date_sk
      )
GROUP BY
    s.s_store_id,
    ws.web_site_id,
    d_ret.d_year,
    d_ret.d_month_seq,
    ss.grp
ORDER BY total_net_loss DESC
LIMIT 100
