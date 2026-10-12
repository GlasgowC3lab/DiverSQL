WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_tax,
        cr.cr_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 20
      AND cr.cr_fee >= 22.97
      AND cr.cr_return_tax <= 84.79
      AND cr.cr_return_quantity >= 1
)
SELECT DISTINCT
    c.c_customer_id,
    i.i_item_id,
    i.i_category,
    wp.wp_url,
    filtered_returns.cr_return_amount,
    filtered_returns.cr_fee,
    filtered_returns.cr_return_tax,
    (SELECT avg(cr2.cr_return_amount)
       FROM catalog_returns cr2
       WHERE cr2.cr_item_sk = i.i_item_sk) AS avg_item_return_amount,
    RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY filtered_returns.cr_net_loss DESC) AS net_loss_rank
FROM filtered_returns
JOIN item i
      ON filtered_returns.cr_item_sk = i.i_item_sk
     AND i.i_wholesale_cost < 1
JOIN customer c
      ON filtered_returns.cr_refunded_customer_sk = c.c_customer_sk
     AND c.c_preferred_cust_flag = 'Y'
JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
     AND wp.wp_max_ad_count >= 1
     AND wp.wp_link_count > 2
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr3
    WHERE cr3.cr_refunded_customer_sk = c.c_customer_sk
      AND cr3.cr_return_amount > filtered_returns.cr_return_amount
)
ORDER BY net_loss_rank, avg_item_return_amount DESC
LIMIT 100
