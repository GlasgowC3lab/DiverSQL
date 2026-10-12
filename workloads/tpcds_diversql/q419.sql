WITH date_filtered AS (
        SELECT d_date_sk,
               d_date,
               d_year,
               d_day_name,
               d_holiday,
               d_month_seq
        FROM date_dim
        WHERE d_year = 2001
          AND d_day_name = 'Friday   '
          AND d_holiday = 'N'
          AND d_month_seq BETWEEN 300 AND 400
    ),
    full_outer_wp_cust AS (
        SELECT wp.wp_web_page_sk,
               wp.wp_url,
               wp.wp_type,
               wp.wp_creation_date_sk,
               wp.wp_access_date_sk,
               c.c_customer_sk,
               c.c_first_name,
               c.c_last_name
        FROM web_page wp
        FULL OUTER JOIN customer c
            ON wp.wp_customer_sk = c.c_customer_sk
    )
SELECT
    wr.wr_returned_date_sk,
    d_ret.d_date,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    CASE
        WHEN wr.wr_net_loss > 0 THEN 'Loss'
        ELSE 'Gain'
    END AS loss_indicator,
    (SELECT avg(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_item_sk = wr.wr_item_sk) AS avg_item_return_amt,
    cp.cp_department,
    cp.cp_catalog_page_number,
    inv.inv_quantity_on_hand,
    t_ret.t_hour,
    fw.wp_url,
    fw.c_customer_sk AS wp_customer_sk,
    ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY wr.wr_return_amt DESC) AS dept_return_rank,
    RANK() OVER (ORDER BY wr.wr_return_amt DESC) AS overall_return_rank
FROM web_returns wr
JOIN date_filtered d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret
    ON wr.wr_returned_time_sk = t_ret.t_time_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_ret.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_ret.d_date_sk
JOIN full_outer_wp_cust fw
    ON fw.wp_web_page_sk = wr.wr_web_page_sk
JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
WHERE i.i_current_price > 20
  AND i.i_color = 'Red'
  AND inv.inv_quantity_on_hand < 100
  AND wr.wr_return_amt > 100
  AND cp.cp_catalog_number BETWEEN 100 AND 200
  AND t_ret.t_hour BETWEEN 9 AND 17
ORDER BY dept_return_rank, loss_indicator
LIMIT 100
